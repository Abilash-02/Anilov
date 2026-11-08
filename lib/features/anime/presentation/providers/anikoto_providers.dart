import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/anikoto_client.dart';
import '../../domain/models/anime_media.dart';
import '../../domain/models/playback_provider.dart';

/// Provider for AnikotoClient instance.
final anikotoClientProvider = Provider<AnikotoClient>((ref) {
  return AnikotoClient();
});

/// Currently selected playback provider (AniKoto or Local Player).
final selectedPlaybackProvider =
    StateProvider<PlaybackProviderType>((ref) {
  return PlaybackProviderType.anikoto;
});

/// Resolves an AniList anime to an AniKoto show with all seasons and metadata.
final anikotoShowProvider =
    FutureProvider.family.autoDispose<AnikotoShowDetails, AnimeMedia>(
  (ref, anime) async {
    final client = ref.watch(anikotoClientProvider);
    return client.resolveShow(anime);
  },
);

/// Currently selected season index for season browsing.
final selectedSeasonIndexProvider = StateProvider.autoDispose<int>((ref) {
  return 0;
});
