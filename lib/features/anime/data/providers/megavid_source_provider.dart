// MegaVid external source provider implementation.
// Maps officially supplied source link for Blue Box Season 1 Episode 1 (https://megavid.buzz/ani/170942/1/sub).
// Enforces security policies: no hidden stream extraction, no Cloudflare/DRM bypass,
// no false Media3 claims, and supports secure in-app browser playback.

import '../../domain/models/anime_media.dart';
import '../../domain/models/anime_source.dart';
import '../../domain/models/playback_provider.dart';

class MegavidSourceProvider implements AnimeSourceProvider {
  /// AniList Media ID for Blue Box (Ao no Hako).
  static const int blueBoxAniListId = 170942;

  /// Specific Season and Episode mapped for MegaVid source.
  static const int blueBoxSeasonNumber = 1;
  static const int blueBoxEpisodeNumber = 1;

  /// Exact original source URL supplied for Blue Box S01E01.
  static const String blueBoxS01E01Url = 'https://megavid.buzz/ani/170942/1/sub';

  @override
  String get id => 'megavid';

  @override
  String get name => 'MegaVid';

  @override
  String get description =>
      'MegaVid external source link provider. In-app browser supported; native stream scraping disabled.';

  @override
  SourceAvailabilityStatus get availability =>
      SourceAvailabilityStatus.restrictedEmbedding;

  @override
  bool get canStreamInApp => false;

  /// Determines if an anime corresponds to Blue Box.
  static bool isBlueBox(AnimeMedia anime) {
    if (anime.id == blueBoxAniListId) return true;
    final displayTitle = anime.title.displayTitle.toLowerCase();
    if (displayTitle.contains('blue box')) return true;
    final romaji = anime.title.romaji?.toLowerCase() ?? '';
    if (romaji.contains('ao no hako') || romaji.contains('blue box')) return true;
    final english = anime.title.english?.toLowerCase() ?? '';
    if (english.contains('blue box')) return true;
    return false;
  }

  /// Determines if a specific episode maps to Blue Box S01E01.
  /// Strictly associates only with Blue Box Season 1 Episode 1.
  static bool isBlueBoxS01E01({
    required int animeId,
    String? title,
    int season = 1,
    int episode = 1,
  }) {
    final matchesAnime = animeId == blueBoxAniListId ||
        (title != null &&
            (title.toLowerCase().contains('blue box') ||
                title.toLowerCase().contains('ao no hako')));
    return matchesAnime &&
        season == blueBoxSeasonNumber &&
        episode == blueBoxEpisodeNumber;
  }

  /// Returns the registered source URL for the episode if mapped.
  static String? getSourceUrl({
    required int animeId,
    String? title,
    int season = 1,
    int episode = 1,
  }) {
    if (isBlueBoxS01E01(
      animeId: animeId,
      title: title,
      season: season,
      episode: episode,
    )) {
      return blueBoxS01E01Url;
    }
    return null;
  }

  /// Evaluates the source URL per project policy guidelines.
  static MegavidPlaybackEvaluation evaluateSource(String url) {
    return MegavidPlaybackEvaluation.evaluate(url);
  }

  static final AnimeMedia _blueBoxMedia = AnimeMedia(
    id: blueBoxAniListId,
    title: const AnimeTitle(
      romaji: 'Ao no Hako',
      english: 'Blue Box',
      native: 'アオのハコ',
    ),
    format: 'TV',
    status: 'RELEASING',
    episodes: 25,
    coverImage: const AnimeCover(
      extraLarge:
          'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx170942-eZ0j2Wk1R5Q8.jpg',
      large:
          'https://s4.anilist.co/file/anilistcdn/media/anime/cover/medium/bx170942-eZ0j2Wk1R5Q8.jpg',
    ),
    description:
        'Taiki Inomata is on the boys\' badminton team at sports powerhouse Eimei Junior and Senior High. He\'s in love with Chinatsu Kano, the older girl on the girls\' basketball team.',
  );

  @override
  Future<List<AnimeMedia>> searchAnime(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return [];
    if (clean.contains('blue box') ||
        clean.contains('ao no hako') ||
        clean == '$blueBoxAniListId') {
      return [_blueBoxMedia];
    }
    return [];
  }

  @override
  Future<AnimeMedia?> getAnimeDetails(String identifier) async {
    final clean = identifier.trim().toLowerCase();
    if (clean == '$blueBoxAniListId' ||
        clean.contains('blue box') ||
        clean.contains('ao no hako')) {
      return _blueBoxMedia;
    }
    return null;
  }

  @override
  Future<List<AnimeSourceSeason>> getSeasons(AnimeMedia anime) async {
    if (isBlueBox(anime)) {
      return [
        AnimeSourceSeason(
          seasonNumber: blueBoxSeasonNumber,
          name: 'Season 1',
          slug: 'blue-box-season-1',
          episodesCount: anime.episodes ?? 25,
        ),
      ];
    }
    return [];
  }

  @override
  Future<List<AnimeSourceEpisode>> getEpisodes(
    AnimeMedia anime, {
    String? seasonSlug,
  }) async {
    if (!isBlueBox(anime)) return [];
    final total = anime.episodes ?? 25;
    return List.generate(
      total,
      (i) {
        final epNum = i + 1;
        return AnimeSourceEpisode(
          episodeNumber: epNum,
          title: 'Episode $epNum',
          sourceIdentifier:
              epNum == blueBoxEpisodeNumber ? blueBoxS01E01Url : null,
        );
      },
    );
  }

  @override
  Future<EpisodePlaybackInfo> getEpisodePlayback(
    AnimeMedia anime,
    int episodeNumber, {
    String? seasonSlug,
  }) async {
    if (isBlueBox(anime) && episodeNumber == blueBoxEpisodeNumber) {
      return const EpisodePlaybackInfo(
        episodeNumber: blueBoxEpisodeNumber,
        episodeTitle: 'Blue Box — Episode 1',
        availability: SourceAvailabilityStatus.restrictedEmbedding,
        externalWatchUrl: blueBoxS01E01Url,
        notice:
            'MegaVid source link mapped for Blue Box Season 1 Episode 1. Direct Media3 video stream is not available; opened securely via in-app browser without scraping hidden streams or bypassing Cloudflare/DRM.',
      );
    }

    return EpisodePlaybackInfo(
      episodeNumber: episodeNumber,
      episodeTitle: '${anime.title.displayTitle} — Episode $episodeNumber',
      availability: SourceAvailabilityStatus.unsupported,
      notice:
          'MegaVid source is only mapped for Blue Box Season 1 Episode 1. No stream is available for this episode on MegaVid.',
    );
  }
}
