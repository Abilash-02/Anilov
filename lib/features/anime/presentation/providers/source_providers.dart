// State management and Riverpod providers for modular AnimeSourceProvider.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/anikoto_source_provider.dart';
import '../../data/providers/authorized_anime_source_provider.dart';
import '../../data/providers/fetch_kickass_source_provider.dart';
import '../../data/providers/local_media_source_provider.dart';
import '../../data/providers/megavid_source_provider.dart';
import '../../domain/models/anime_media.dart';
import '../../domain/models/anime_source.dart';

/// Registry of all registered AnimeSourceProviders in Anilov.
final allSourceProviders = Provider<List<AnimeSourceProvider>>((ref) {
  return [
    AuthorizedAnimeSourceProvider(),
    AnikotoSourceProvider(),
    FetchKickassSourceProvider(),
    LocalMediaSourceProvider(),
    MegavidSourceProvider(),
  ];
});

/// Notifier managing the currently active AnimeSourceProvider.
class ActiveSourceNotifier extends Notifier<AnimeSourceProvider> {
  @override
  AnimeSourceProvider build() {
    // Default to AuthorizedAnimeSourceProvider for seamless out-of-the-box HLS playback
    return AuthorizedAnimeSourceProvider();
  }

  void selectProvider(AnimeSourceProvider provider) {
    state = provider;
  }

  void selectProviderById(String id) {
    final list = ref.read(allSourceProviders);
    final found = list.firstWhere((p) => p.id == id, orElse: () => state);
    state = found;
  }
}

final activeSourceProviderState =
    NotifierProvider<ActiveSourceNotifier, AnimeSourceProvider>(
  ActiveSourceNotifier.new,
);

/// Provider fetching seasons for an anime using the currently active source.
final sourceSeasonsProvider = FutureProvider.family
    .autoDispose<List<AnimeSourceSeason>, AnimeMedia>((ref, anime) async {
  final provider = ref.watch(activeSourceProviderState);
  return provider.getSeasons(anime);
});

/// Provider fetching episodes for an anime using the currently active source.
final sourceEpisodesProvider = FutureProvider.family.autoDispose<
    List<AnimeSourceEpisode>,
    ({AnimeMedia anime, String? seasonSlug})>((ref, arg) async {
  final provider = ref.watch(activeSourceProviderState);
  return provider.getEpisodes(arg.anime, seasonSlug: arg.seasonSlug);
});

/// Provider resolving playback information for a specific episode.
final episodePlaybackInfoProvider = FutureProvider.family.autoDispose<
    EpisodePlaybackInfo,
    ({AnimeMedia anime, int episodeNumber, String? seasonSlug})>((ref, arg) async {
  final provider = ref.watch(activeSourceProviderState);
  return provider.getEpisodePlayback(
    arg.anime,
    arg.episodeNumber,
    seasonSlug: arg.seasonSlug,
  );
});
