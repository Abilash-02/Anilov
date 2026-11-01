// Riverpod providers for Watchlist and History persistence

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../anime/domain/models/anime_media.dart';
import '../../domain/models/history_item.dart';
import '../../domain/models/watch_status.dart';
import '../../domain/models/watchlist_item.dart';
import '../data/app_database.dart';
import '../data/history_repository.dart';
import '../data/watchlist_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final watchlistRepositoryProvider = Provider<WatchlistRepository>((ref) {
  final dbHelper = ref.watch(appDatabaseProvider);
  return SqfliteWatchlistRepository(dbHelper: dbHelper);
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final dbHelper = ref.watch(appDatabaseProvider);
  return SqfliteHistoryRepository(dbHelper: dbHelper);
});

// Watchlist Filter & Sort State
class WatchlistFilterState {
  final WatchStatus? status; // null means 'All'
  final String searchQuery;
  final String sortBy;
  final bool ascending;

  const WatchlistFilterState({
    this.status,
    this.searchQuery = '',
    this.sortBy = 'updated_at',
    this.ascending = false,
  });

  WatchlistFilterState copyWith({
    WatchStatus? Function()? status,
    String? searchQuery,
    String? sortBy,
    bool? ascending,
  }) {
    return WatchlistFilterState(
      status: status != null ? status() : this.status,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
    );
  }
}

class WatchlistFilterNotifier extends Notifier<WatchlistFilterState> {
  @override
  WatchlistFilterState build() => const WatchlistFilterState();

  void setStatus(WatchStatus? status) {
    state = state.copyWith(status: () => status);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSortBy(String sortBy, {bool ascending = false}) {
    state = state.copyWith(sortBy: sortBy, ascending: ascending);
  }
}

final watchlistFilterProvider =
    NotifierProvider<WatchlistFilterNotifier, WatchlistFilterState>(
  WatchlistFilterNotifier.new,
);

// Main Watchlist Notifier
class WatchlistNotifier extends AsyncNotifier<List<WatchlistItem>> {
  @override
  Future<List<WatchlistItem>> build() async {
    final filter = ref.watch(watchlistFilterProvider);
    final repository = ref.watch(watchlistRepositoryProvider);

    return repository.getWatchlist(
      status: filter.status,
      searchQuery: filter.searchQuery,
      sortBy: filter.sortBy,
      ascending: filter.ascending,
    );
  }

  Future<void> addItem({
    required AnimeMedia anime,
    WatchStatus status = WatchStatus.planning,
    int progress = 0,
    double? score,
  }) async {
    final repository = ref.read(watchlistRepositoryProvider);
    final now = DateTime.now();

    final item = WatchlistItem(
      animeId: anime.id,
      title: anime.title.displayTitle,
      coverUrl: anime.coverImage.displayUrl,
      format: anime.displayFormat,
      totalEpisodes: anime.episodes,
      status: status,
      progress: progress,
      score: score,
      updatedAt: now,
      createdAt: now,
    );

    await repository.saveWatchlistItem(item);

    if (progress > 0) {
      final historyRepo = ref.read(historyRepositoryProvider);
      await historyRepo.recordHistory(
        animeId: anime.id,
        title: anime.title.displayTitle,
        coverUrl: anime.coverImage.displayUrl,
        episode: progress,
      );
      ref.invalidate(historyNotifierProvider);
    }

    ref.invalidate(watchlistCountsProvider);
    ref.invalidate(continueWatchingProvider);
    ref.invalidate(watchlistItemProvider(anime.id));
    ref.invalidateSelf();
  }

  Future<void> updateProgress(
    int animeId,
    int progress, {
    required String title,
    String? coverUrl,
  }) async {
    final repository = ref.read(watchlistRepositoryProvider);
    await repository.updateProgress(animeId, progress);

    if (progress > 0) {
      final historyRepo = ref.read(historyRepositoryProvider);
      await historyRepo.recordHistory(
        animeId: animeId,
        title: title,
        coverUrl: coverUrl,
        episode: progress,
      );
      ref.invalidate(historyNotifierProvider);
    }

    ref.invalidate(watchlistCountsProvider);
    ref.invalidate(continueWatchingProvider);
    ref.invalidate(watchlistItemProvider(animeId));
    ref.invalidateSelf();
  }

  Future<void> incrementProgress(
    int animeId, {
    required String title,
    String? coverUrl,
  }) async {
    final repository = ref.read(watchlistRepositoryProvider);
    final current = await repository.getWatchlistItem(animeId);
    if (current == null) return;

    if (current.canIncrement) {
      await updateProgress(
        animeId,
        current.progress + 1,
        title: title,
        coverUrl: coverUrl,
      );
    }
  }

  Future<void> decrementProgress(int animeId) async {
    final repository = ref.read(watchlistRepositoryProvider);
    final current = await repository.getWatchlistItem(animeId);
    if (current == null || current.progress <= 0) return;

    await repository.updateProgress(animeId, current.progress - 1);
    ref.invalidate(watchlistCountsProvider);
    ref.invalidate(continueWatchingProvider);
    ref.invalidate(watchlistItemProvider(animeId));
    ref.invalidateSelf();
  }

  Future<void> updateStatus(int animeId, WatchStatus status) async {
    final repository = ref.read(watchlistRepositoryProvider);
    await repository.updateStatus(animeId, status);
    ref.invalidate(watchlistCountsProvider);
    ref.invalidate(continueWatchingProvider);
    ref.invalidate(watchlistItemProvider(animeId));
    ref.invalidateSelf();
  }

  Future<void> updateScore(int animeId, double? score) async {
    final repository = ref.read(watchlistRepositoryProvider);
    await repository.updateScore(animeId, score);
    ref.invalidate(watchlistItemProvider(animeId));
    ref.invalidateSelf();
  }

  Future<void> removeItem(int animeId) async {
    final repository = ref.read(watchlistRepositoryProvider);
    await repository.deleteWatchlistItem(animeId);
    ref.invalidate(watchlistCountsProvider);
    ref.invalidate(continueWatchingProvider);
    ref.invalidate(watchlistItemProvider(animeId));
    ref.invalidateSelf();
  }
}

final watchlistNotifierProvider =
    AsyncNotifierProvider<WatchlistNotifier, List<WatchlistItem>>(
  WatchlistNotifier.new,
);

// Single Item Provider for Details Screen
final watchlistItemProvider =
    FutureProvider.family.autoDispose<WatchlistItem?, int>((ref, animeId) async {
  final repository = ref.watch(watchlistRepositoryProvider);
  return repository.getWatchlistItem(animeId);
});

// Watchlist Counts Provider
final watchlistCountsProvider =
    FutureProvider.autoDispose<Map<WatchStatus, int>>((ref) async {
  final repository = ref.watch(watchlistRepositoryProvider);
  return repository.getWatchlistCounts();
});

// Continue Watching Provider for Home Screen
final continueWatchingProvider =
    FutureProvider.autoDispose<List<WatchlistItem>>((ref) async {
  final repository = ref.watch(watchlistRepositoryProvider);
  return repository.getContinueWatching(limit: 10);
});

// History Notifier
class HistoryNotifier extends AsyncNotifier<List<HistoryItem>> {
  @override
  Future<List<HistoryItem>> build() async {
    final repository = ref.watch(historyRepositoryProvider);
    return repository.getHistory(limit: 100);
  }

  Future<void> recordEpisode({
    required int animeId,
    required String title,
    String? coverUrl,
    required int episode,
  }) async {
    final repository = ref.read(historyRepositoryProvider);
    await repository.recordHistory(
      animeId: animeId,
      title: title,
      coverUrl: coverUrl,
      episode: episode,
    );
    ref.invalidateSelf();
  }

  Future<void> removeItem(int id) async {
    final repository = ref.read(historyRepositoryProvider);
    await repository.deleteHistoryItem(id);
    ref.invalidateSelf();
  }

  Future<void> clearHistory() async {
    final repository = ref.read(historyRepositoryProvider);
    await repository.clearHistory();
    ref.invalidateSelf();
  }
}

final historyNotifierProvider =
    AsyncNotifierProvider<HistoryNotifier, List<HistoryItem>>(
  HistoryNotifier.new,
);
