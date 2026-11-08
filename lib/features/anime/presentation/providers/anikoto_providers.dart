import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/anikoto_client.dart';
import '../../domain/models/anime_media.dart';
import '../../domain/models/playback_provider.dart';

/// Provider for AnikotoClient instance.
final anikotoClientProvider = Provider<AnikotoClient>((ref) {
  return AnikotoClient();
});

/// Notifier managing active playback provider selection.
class SelectedPlaybackProviderNotifier extends Notifier<PlaybackProviderType> {
  @override
  PlaybackProviderType build() => PlaybackProviderType.anikoto;

  void setProvider(PlaybackProviderType provider) => state = provider;
}

/// Currently selected playback provider (AniKoto or Local Player).
final selectedPlaybackProvider =
    NotifierProvider<SelectedPlaybackProviderNotifier, PlaybackProviderType>(
  SelectedPlaybackProviderNotifier.new,
);

/// Resolves an AniList anime to an AniKoto show with all seasons and metadata.
final anikotoShowProvider =
    FutureProvider.family.autoDispose<AnikotoShowDetails, AnimeMedia>(
  (ref, anime) async {
    final client = ref.watch(anikotoClientProvider);
    return client.resolveShow(anime);
  },
);

/// Notifier managing selected season index.
class SelectedSeasonIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;
}

/// Currently selected season index for season browsing.
final selectedSeasonIndexProvider =
    NotifierProvider<SelectedSeasonIndexNotifier, int>(
  SelectedSeasonIndexNotifier.new,
);
