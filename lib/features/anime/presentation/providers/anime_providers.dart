import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/anilist_client.dart';
import '../../data/anilist_repository_impl.dart';
import '../../data/anime_repository.dart';
import '../../domain/models/anime_media.dart';

final animeClientProvider = Provider<AniListClient>((ref) {
  return AniListClient();
});

final animeRepositoryProvider = Provider<AnimeRepository>((ref) {
  final client = ref.watch(animeClientProvider);
  return AniListRepositoryImpl(client: client);
});

class HomeData {
  final List<AnimeMedia> featured;
  final List<AnimeMedia> trending;
  final List<AnimeMedia> popular;
  final List<AnimeMedia> topRated;
  final List<AnimeMedia> airingToday;
  final List<AnimeMedia> currentlyAiring;

  const HomeData({
    required this.featured,
    required this.trending,
    required this.popular,
    required this.topRated,
    required this.airingToday,
    required this.currentlyAiring,
  });
}

final homeDataProvider = FutureProvider.autoDispose<HomeData>((ref) async {
  final repo = ref.watch(animeRepositoryProvider);

  final results = await Future.wait([
    repo.getTrendingAnime(page: 1, perPage: 10),
    repo.getPopularAnime(page: 1, perPage: 10),
    repo.getTopRatedAnime(page: 1, perPage: 10),
    repo.getAiringTodayAnime(page: 1, perPage: 10),
    repo.getCurrentlyAiringAnime(page: 1, perPage: 10),
  ]);

  final trending = results[0];
  final popular = results[1];
  final topRated = results[2];
  final airingToday = results[3];
  final currentlyAiring = results[4];

  // Featured carousel takes top 5 from trending with banner or cover
  final featured = trending.take(5).toList();

  return HomeData(
    featured: featured,
    trending: trending,
    popular: popular,
    topRated: topRated,
    airingToday: airingToday,
    currentlyAiring: currentlyAiring,
  );
});

final animeDetailsProvider =
    FutureProvider.family.autoDispose<AnimeMedia, int>((ref, id) async {
  final repo = ref.watch(animeRepositoryProvider);
  return repo.getAnimeDetails(id);
});

class ExploreState {
  final String query;
  final String? genre;
  final String? format;
  final String? status;
  final int? year;
  final String sort;
  final List<AnimeMedia> items;
  final PageInfo pageInfo;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final List<String> searchHistory;

  const ExploreState({
    this.query = '',
    this.genre,
    this.format,
    this.status,
    this.year,
    this.sort = 'TRENDING_DESC',
    this.items = const [],
    this.pageInfo = const PageInfo(),
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.searchHistory = const [],
  });

  ExploreState copyWith({
    String? query,
    String? genre,
    bool clearGenre = false,
    String? format,
    bool clearFormat = false,
    String? status,
    bool clearStatus = false,
    int? year,
    bool clearYear = false,
    String? sort,
    List<AnimeMedia>? items,
    PageInfo? pageInfo,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    List<String>? searchHistory,
  }) {
    return ExploreState(
      query: query ?? this.query,
      genre: clearGenre ? null : (genre ?? this.genre),
      format: clearFormat ? null : (format ?? this.format),
      status: clearStatus ? null : (status ?? this.status),
      year: clearYear ? null : (year ?? this.year),
      sort: sort ?? this.sort,
      items: items ?? this.items,
      pageInfo: pageInfo ?? this.pageInfo,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      searchHistory: searchHistory ?? this.searchHistory,
    );
  }
}

class ExploreNotifier extends Notifier<ExploreState> {
  Timer? _debounceTimer;

  AnimeRepository get _repository => ref.read(animeRepositoryProvider);

  @override
  ExploreState build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    _loadSearchHistory();
    return const ExploreState();
  }

  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('explore_search_history') ?? [];
      state = state.copyWith(searchHistory: history);
    } catch (_) {}
  }

  Future<void> _saveSearchHistory(String query) async {
    if (query.trim().isEmpty) return;
    final trimmed = query.trim();
    final updated = [
      trimmed,
      ...state.searchHistory.where((q) => q.toLowerCase() != trimmed.toLowerCase()),
    ].take(10).toList();

    state = state.copyWith(searchHistory: updated);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('explore_search_history', updated);
    } catch (_) {}
  }

  Future<void> clearSearchHistory() async {
    state = state.copyWith(searchHistory: []);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('explore_search_history');
    } catch (_) {}
  }

  void onQueryChanged(String query) {
    if (state.query == query) return;
    state = state.copyWith(query: query);

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (query.trim().isNotEmpty) {
        _saveSearchHistory(query);
      }
      search();
    });
  }

  void onGenreSelected(String? genre) {
    if (genre == 'All Genres') genre = null;
    if (state.genre == genre) return;
    state = state.copyWith(genre: genre, clearGenre: genre == null);
    search();
  }

  void onFormatSelected(String? format) {
    if (format == 'ALL') format = null;
    if (state.format == format) return;
    state = state.copyWith(format: format, clearFormat: format == null);
    search();
  }

  void onStatusSelected(String? status) {
    if (status == 'ALL') status = null;
    if (state.status == status) return;
    state = state.copyWith(status: status, clearStatus: status == null);
    search();
  }

  void onYearSelected(int? year) {
    if (state.year == year) return;
    state = state.copyWith(year: year, clearYear: year == null);
    search();
  }

  void onSortSelected(String sort) {
    if (state.sort == sort) return;
    state = state.copyWith(sort: sort);
    search();
  }

  Future<void> search() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _repository.searchAnime(
        query: state.query,
        genre: state.genre,
        format: state.format,
        status: state.status,
        year: state.year,
        sort: state.sort,
        page: 1,
        perPage: 20,
      );

      state = state.copyWith(
        items: result.items,
        pageInfo: result.pageInfo,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.pageInfo.hasNextPage) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.pageInfo.currentPage + 1;
      final result = await _repository.searchAnime(
        query: state.query,
        genre: state.genre,
        format: state.format,
        status: state.status,
        year: state.year,
        sort: state.sort,
        page: nextPage,
        perPage: 20,
      );

      state = state.copyWith(
        items: [...state.items, ...result.items],
        pageInfo: result.pageInfo,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

final exploreStateProvider =
    NotifierProvider<ExploreNotifier, ExploreState>(ExploreNotifier.new);
