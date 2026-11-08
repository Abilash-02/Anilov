// AniKoto source provider conforming to AnimeSourceProvider architecture.
// Integrates metadata, season discovery, and episode listing from anikoto.cz.
// Complies with embedding policy (X-Frame-Options: SAMEORIGIN) without scraping hidden streams.

import '../../domain/models/anime_media.dart';
import '../../domain/models/anime_source.dart';
import '../anikoto_client.dart';

class AnikotoSourceProvider implements AnimeSourceProvider {
  final AnikotoClient _client;

  AnikotoSourceProvider({AnikotoClient? client})
      : _client = client ?? AnikotoClient();

  @override
  String get id => 'anikoto';

  @override
  String get name => 'AniKoto';

  @override
  String get description =>
      'AniKoto catalogue (anikoto.cz). In-app embedding restricted by SAMEORIGIN; launches externally.';

  @override
  SourceAvailabilityStatus get availability =>
      SourceAvailabilityStatus.restrictedEmbedding;

  @override
  bool get canStreamInApp => false;

  @override
  Future<List<AnimeMedia>> searchAnime(String query) async {
    final results = await _client.search(query);
    return results.map((details) {
      return AnimeMedia(
        id: details.tipId ?? details.slug.hashCode,
        title: AnimeTitle(
          romaji: details.title,
          english: details.title,
        ),
        coverImage: AnimeCover(
          extraLarge: details.posterUrl,
          large: details.posterUrl,
          medium: details.posterUrl,
        ),
        episodes: details.totalEpisodes > 0 ? details.totalEpisodes : null,
      );
    }).toList();
  }

  @override
  Future<List<AnimeSourceSeason>> getSeasons(AnimeMedia anime) async {
    final showDetails = await _client.resolveShow(anime);
    if (showDetails.seasons.isNotEmpty) {
      return showDetails.seasons
          .map(
            (s) => AnimeSourceSeason(
              seasonNumber: s.seasonNumber,
              name: s.name,
              slug: s.slug,
              episodesCount: s.episodesCount ?? showDetails.totalEpisodes,
              bannerUrl: s.bannerUrl,
            ),
          )
          .toList();
    }

    return [
      AnimeSourceSeason(
        seasonNumber: 1,
        name: 'Season 1',
        slug: showDetails.slug,
        episodesCount: showDetails.totalEpisodes,
      ),
    ];
  }

  @override
  Future<List<AnimeSourceEpisode>> getEpisodes(
    AnimeMedia anime, {
    String? seasonSlug,
  }) async {
    final showDetails = await _client.resolveShow(anime);
    final count = showDetails.totalEpisodes > 0 ? showDetails.totalEpisodes : 12;

    return List.generate(
      count,
      (i) => AnimeSourceEpisode(
        episodeNumber: i + 1,
        title: 'Episode ${i + 1}',
        sourceIdentifier: showDetails.buildEpisodeUrl(
          i + 1,
          seasonSlug: seasonSlug,
        ),
      ),
    );
  }

  @override
  Future<EpisodePlaybackInfo> getEpisodePlayback(
    AnimeMedia anime,
    int episodeNumber, {
    String? seasonSlug,
  }) async {
    final showDetails = await _client.resolveShow(anime);
    final watchUrl = showDetails.buildEpisodeUrl(
      episodeNumber,
      seasonSlug: seasonSlug,
    );

    return EpisodePlaybackInfo(
      episodeNumber: episodeNumber,
      episodeTitle: '${anime.title.displayTitle} — Episode $episodeNumber',
      availability: SourceAvailabilityStatus.restrictedEmbedding,
      externalWatchUrl: watchUrl,
      notice:
          'AniKoto enforces "X-Frame-Options: SAMEORIGIN" and requires internal vrf verification. '
          'In compliance with security guidelines, hidden stream URLs are not scraped. '
          'Please watch via the official browser endpoint or select Authorized Stream.',
    );
  }
}
