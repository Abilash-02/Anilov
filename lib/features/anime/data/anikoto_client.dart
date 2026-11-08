import 'dart:async';
import 'package:dio/dio.dart';

import '../domain/models/anime_media.dart';
import '../domain/models/playback_provider.dart';

/// Client for interacting with AniKoto (https://anikoto.cz) public endpoints.
/// Strictly inspects public pages, evaluates embedding restrictions, and constructs
/// website-supported playback URLs without scraping hidden streams or bypassing controls.
class AnikotoClient {
  final Dio _dio;
  static const String baseUrl = 'https://anikoto.cz';

  // In-memory cache to reduce network queries
  final Map<String, ({DateTime timestamp, dynamic data})> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  AnikotoClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: {
                  'User-Agent': 'Anilov/1.0.0 (Linux; Android)',
                  'Accept': 'text/html,application/xhtml+xml,application/json',
                },
              ),
            );

  /// Clears the in-memory cache.
  void clearCache() {
    _cache.clear();
  }

  /// Searches AniKoto for anime matching the query string.
  Future<List<AnikotoShowDetails>> search(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final cacheKey = 'search_$cleanQuery';
    final cached = _cache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) < _cacheDuration) {
      return (cached.data as List<AnikotoShowDetails>);
    }

    try {
      final response = await _dio.get(
        '/filter',
        queryParameters: {'keyword': cleanQuery},
      );

      final html = response.data?.toString() ?? '';
      final results = parseSearchResultsHtml(html);

      _cache[cacheKey] = (timestamp: DateTime.now(), data: results);
      return results;
    } catch (_) {
      return [];
    }
  }

  /// Parses the HTML search results page from AniKoto.
  List<AnikotoShowDetails> parseSearchResultsHtml(String html) {
    final results = <AnikotoShowDetails>[];
    if (html.isEmpty) return results;

    // Pattern to capture each item container in the search list
    final itemRegex = RegExp(
      r'<div class="item\s*">([\s\S]*?)</div>\s*</div>\s*</div>',
      caseSensitive: false,
    );

    final tipIdRegex = RegExp(r'data-tip="(\d+)"');
    final hrefRegex = RegExp(r'href="https?://anikoto\.cz/watch/([^"/]+)');
    final titleRegex = RegExp(r'<a class="name d-title"[^>]*>([\s\S]*?)</a>');
    final posterRegex = RegExp(r'<img\s+src="([^"]+)"');
    final subRegex =
        RegExp(r'<span class="ep-status sub"><span>\s*(\d+)</span></span>');
    final dubRegex =
        RegExp(r'<span class="ep-status dub"><span>\s*(\d+)</span></span>');
    final totalRegex =
        RegExp(r'<span class="ep-status total"><span>\s*(\d+)</span></span>');

    for (final match in itemRegex.allMatches(html)) {
      final block = match.group(1) ?? '';

      final tipMatch = tipIdRegex.firstMatch(block);
      final hrefMatch = hrefRegex.firstMatch(block);
      final titleMatch = titleRegex.firstMatch(block);
      final posterMatch = posterRegex.firstMatch(block);
      final subMatch = subRegex.firstMatch(block);
      final dubMatch = dubRegex.firstMatch(block);
      final totalMatch = totalRegex.firstMatch(block);

      if (hrefMatch != null && titleMatch != null) {
        final slug = hrefMatch.group(1)!.trim();
        final rawTitle = titleMatch.group(1)!.trim();
        final cleanTitle = _unescapeHtml(rawTitle);
        final tipId =
            tipMatch != null ? int.tryParse(tipMatch.group(1)!) : null;
        final posterUrl = posterMatch?.group(1);

        final totalEps =
            totalMatch != null ? int.tryParse(totalMatch.group(1)!) ?? 0 : 0;
        final subEps =
            subMatch != null ? int.tryParse(subMatch.group(1)!) ?? 0 : 0;
        final dubEps =
            dubMatch != null ? int.tryParse(dubMatch.group(1)!) ?? 0 : 0;

        results.add(
          AnikotoShowDetails(
            tipId: tipId,
            title: cleanTitle,
            slug: slug,
            posterUrl: posterUrl,
            totalEpisodes: totalEps > 0 ? totalEps : (subEps > 0 ? subEps : 12),
            subEpisodes: subEps,
            dubEpisodes: dubEps,
          ),
        );
      }
    }

    return results;
  }

  /// Retrieves available seasons for an anime show given its tipId.
  Future<List<AnikotoSeason>> getSeasons(
    int tipId,
    String fallbackSlug, {
    String fallbackTitle = 'Season 1',
    int? fallbackEpisodes,
  }) async {
    final cacheKey = 'seasons_$tipId';
    final cached = _cache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) < _cacheDuration) {
      return (cached.data as List<AnikotoSeason>);
    }

    try {
      final response = await _dio.get(
        '/api/seasons/$tipId',
        options: Options(headers: {'X-Requested-With': 'XMLHttpRequest'}),
      );

      final data = response.data;
      if (data is Map && data['result'] != null && data['result'] is String) {
        final html = data['result'] as String;
        final seasons = parseSeasonsHtml(html);
        if (seasons.isNotEmpty) {
          _cache[cacheKey] = (timestamp: DateTime.now(), data: seasons);
          return seasons;
        }
      }
    } catch (_) {
      // Fallback below
    }

    final fallback = [
      AnikotoSeason(
        seasonNumber: 1,
        name: fallbackTitle,
        slug: fallbackSlug,
        episodesCount: fallbackEpisodes,
      ),
    ];
    _cache[cacheKey] = (timestamp: DateTime.now(), data: fallback);
    return fallback;
  }

  /// Parses the HTML returned by AniKoto's /api/seasons endpoint.
  List<AnikotoSeason> parseSeasonsHtml(String html) {
    final seasons = <AnikotoSeason>[];
    if (html.isEmpty) return seasons;

    // Pattern to capture season links, banners, and names
    final seasonRegex = RegExp(
      r'<a\s+href="https?://anikoto\.cz/watch/([^"/]+)"(?:\s+style="[^"]*background-image:\s*url\(([^)]+)\)[^"]*")?>\s*<div\s+class="name"[^>]*>([\s\S]*?)</div>',
      caseSensitive: false,
    );

    int count = 1;
    for (final match in seasonRegex.allMatches(html)) {
      final slug = match.group(1)!.trim();
      var bannerUrl = match.group(2)?.trim();
      if (bannerUrl != null) {
        bannerUrl = bannerUrl.replaceAll(r'\/', '/').replaceAll('"', '').trim();
      }
      final name = _unescapeHtml((match.group(3) ?? 'Season $count').trim());

      seasons.add(
        AnikotoSeason(
          seasonNumber: count,
          name: name.isNotEmpty ? name : 'Season $count',
          slug: slug,
          bannerUrl: bannerUrl,
        ),
      );
      count++;
    }

    return seasons;
  }

  /// Resolves an AniList anime to an AniKoto show and its seasons.
  Future<AnikotoShowDetails> resolveShow(AnimeMedia anime) async {
    // 1. Try search with Romaji title, then English title, then display title
    final queries = <String>{
      if (anime.title.romaji != null && anime.title.romaji!.isNotEmpty)
        anime.title.romaji!,
      if (anime.title.english != null && anime.title.english!.isNotEmpty)
        anime.title.english!,
      anime.title.displayTitle,
    };

    List<AnikotoShowDetails> searchResults = [];
    for (final query in queries) {
      searchResults = await search(query);
      if (searchResults.isNotEmpty) break;
    }

    if (searchResults.isNotEmpty) {
      final bestMatch = _findBestMatch(searchResults, anime);
      if (bestMatch.tipId != null) {
        final seasons = await getSeasons(
          bestMatch.tipId!,
          bestMatch.slug,
          fallbackTitle: 'Season 1',
          fallbackEpisodes: anime.episodes,
        );
        return AnikotoShowDetails(
          tipId: bestMatch.tipId,
          title: bestMatch.title,
          slug: bestMatch.slug,
          posterUrl: bestMatch.posterUrl ?? anime.coverImage.displayUrl,
          totalEpisodes: bestMatch.totalEpisodes > 0
              ? bestMatch.totalEpisodes
              : (anime.episodes ?? 12),
          subEpisodes: bestMatch.subEpisodes,
          dubEpisodes: bestMatch.dubEpisodes,
          seasons: seasons,
        );
      }

      return AnikotoShowDetails(
        tipId: bestMatch.tipId,
        title: bestMatch.title,
        slug: bestMatch.slug,
        posterUrl: bestMatch.posterUrl ?? anime.coverImage.displayUrl,
        totalEpisodes: bestMatch.totalEpisodes > 0
            ? bestMatch.totalEpisodes
            : (anime.episodes ?? 12),
        subEpisodes: bestMatch.subEpisodes,
        dubEpisodes: bestMatch.dubEpisodes,
        seasons: [
          AnikotoSeason(
            seasonNumber: 1,
            name: 'Season 1',
            slug: bestMatch.slug,
            bannerUrl: anime.bannerImage,
            episodesCount: anime.episodes,
          ),
        ],
      );
    }

    // Fallback: Generate derived slug from title if search yields no results
    final derivedSlug = slugify(anime.title.displayTitle);
    return AnikotoShowDetails(
      title: anime.title.displayTitle,
      slug: derivedSlug,
      posterUrl: anime.coverImage.displayUrl,
      totalEpisodes: anime.episodes ?? 12,
      subEpisodes: anime.episodes ?? 12,
      seasons: [
        AnikotoSeason(
          seasonNumber: 1,
          name: 'Season 1',
          slug: derivedSlug,
          bannerUrl: anime.bannerImage,
          episodesCount: anime.episodes,
        ),
      ],
    );
  }

  /// Evaluates in-app playback capability for an AniKoto episode URL.
  AnikotoPlaybackEvaluation evaluateEpisodePlayback(
    String slug,
    int episodeNumber,
  ) {
    final watchUrl = buildEpisodeUrl(slug, episodeNumber);
    return AnikotoPlaybackEvaluation.evaluate(watchUrl);
  }

  /// Builds the official AniKoto watch URL for an episode.
  static String buildEpisodeUrl(String slug, int episodeNumber) {
    return '$baseUrl/watch/$slug/ep-$episodeNumber';
  }

  /// Converts a title into a URL slug.
  static String slugify(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  /// Finds the best match from search results for the given anime.
  AnikotoShowDetails _findBestMatch(
    List<AnikotoShowDetails> candidates,
    AnimeMedia anime,
  ) {
    final targetDisplay = anime.title.displayTitle.toLowerCase();
    final targetRomaji = anime.title.romaji?.toLowerCase() ?? '';
    final targetEnglish = anime.title.english?.toLowerCase() ?? '';

    for (final candidate in candidates) {
      final candTitle = candidate.title.toLowerCase();
      if (candTitle == targetDisplay ||
          (targetRomaji.isNotEmpty && candTitle == targetRomaji) ||
          (targetEnglish.isNotEmpty && candTitle == targetEnglish)) {
        return candidate;
      }
    }
    return candidates.first;
  }

  static String _unescapeHtml(String input) {
    return input
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }
}
