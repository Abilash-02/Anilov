// Local Media and direct stream source provider.

import '../../domain/models/anime_media.dart';
import '../../domain/models/anime_source.dart';

class LocalMediaSourceProvider implements AnimeSourceProvider {
  @override
  String get id => 'local_player';

  @override
  String get name => 'Local Media & Direct Stream';

  @override
  String get description =>
      'Play offline downloaded video files or authorized direct video streams.';

  @override
  SourceAvailabilityStatus get availability =>
      SourceAvailabilityStatus.authorized;

  @override
  bool get canStreamInApp => true;

  @override
  Future<List<AnimeMedia>> searchAnime(String query) async => [];

  @override
  Future<List<AnimeSourceSeason>> getSeasons(AnimeMedia anime) async {
    return [
      AnimeSourceSeason(
        seasonNumber: 1,
        name: 'Local Collection',
        slug: 'local',
        episodesCount: anime.episodes ?? 1,
      ),
    ];
  }

  @override
  Future<List<AnimeSourceEpisode>> getEpisodes(
    AnimeMedia anime, {
    String? seasonSlug,
  }) async {
    final count = anime.episodes ?? 12;
    return List.generate(
      count,
      (i) => AnimeSourceEpisode(
        episodeNumber: i + 1,
        title: 'Local Episode ${i + 1}',
        sourceIdentifier: 'local://${anime.id}/${i + 1}',
      ),
    );
  }

  @override
  Future<EpisodePlaybackInfo> getEpisodePlayback(
    AnimeMedia anime,
    int episodeNumber, {
    String? seasonSlug,
  }) async {
    return EpisodePlaybackInfo(
      episodeNumber: episodeNumber,
      episodeTitle: '${anime.title.displayTitle} — Episode $episodeNumber',
      availability: SourceAvailabilityStatus.authorized,
      streams: const [],
      notice:
          'Local Media mode: Select a local video file or provide a direct video URL from the Local Player.',
    );
  }
}
