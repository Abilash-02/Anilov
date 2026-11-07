import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anilov/features/anime/data/anilist_client.dart';
import 'package:anilov/features/auth/presentation/providers/auth_provider.dart';
import 'package:anilov/features/sync/data/anilist_sync_repository.dart';
import 'package:anilov/features/sync/domain/models/sync_state.dart';
import 'package:anilov/features/watchlist/presentation/providers/watchlist_providers.dart';

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  final client = AniListClient();
  final watchlistRepo = ref.watch(watchlistRepositoryProvider);
  return AniListSyncRepository(
    client: client,
    watchlistRepository: watchlistRepo,
  );
});

class SyncNotifier extends Notifier<SyncState> {
  static const String _keyLastSync = 'anilov_last_sync_timestamp';

  late final SyncRepository _syncRepository;

  @override
  SyncState build() {
    _syncRepository = ref.watch(syncRepositoryProvider);
    _loadLastSyncTime();
    return const SyncState(status: SyncStatus.idle);
  }

  Future<void> _loadLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final millis = prefs.getInt(_keyLastSync);
      if (millis != null && millis > 0) {
        state = state.copyWith(
          lastSyncTime: () => DateTime.fromMillisecondsSinceEpoch(millis),
        );
      }
    } catch (_) {}
  }

  Future<void> syncNow() async {
    final authState = ref.read(authNotifierProvider);
    if (!authState.isAuthenticated || authState.accessToken == null || authState.user == null) {
      state = state.copyWith(
        status: SyncStatus.error,
        message: () => 'Not connected to AniList. Please log in first.',
      );
      return;
    }

    state = state.copyWith(
      status: SyncStatus.syncing,
      message: () => 'Synchronizing with AniList...',
    );

    try {
      final result = await _syncRepository.synchronize(
        accessToken: authState.accessToken!,
        userId: authState.user!.id,
      );

      final now = DateTime.now();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_keyLastSync, now.millisecondsSinceEpoch);
      } catch (_) {}

      // Invalidate local watchlist provider to refresh UI
      ref.invalidate(watchlistNotifierProvider);
      ref.invalidate(watchlistCountsProvider);
      ref.invalidate(continueWatchingProvider);

      state = SyncState(
        status: SyncStatus.success,
        lastSyncTime: now,
        syncedCount: result.totalSynced,
        message: 'Sync completed! Updated ${result.totalSynced} anime entries (${result.pulledCount} pulled, ${result.pushedCount} pushed).',
      );
    } on UnauthorizedException {
      // Access token revoked or expired
      await ref.read(authNotifierProvider.notifier).logout();
      state = state.copyWith(
        status: SyncStatus.error,
        message: () => 'AniList session expired. Please connect your account again.',
      );
    } on NetworkException catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        message: () => e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        message: () => 'Synchronization failed: $e',
      );
    }
  }
}

final syncNotifierProvider = NotifierProvider<SyncNotifier, SyncState>(() {
  return SyncNotifier();
});
