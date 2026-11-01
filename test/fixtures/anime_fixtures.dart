// Test JSON fixtures simulating AniList GraphQL responses.

import 'package:anilov/features/anime/data/anime_repository.dart';
import 'package:anilov/features/anime/domain/models/anime_media.dart';
import 'package:anilov/features/watchlist/data/history_repository.dart';
import 'package:anilov/features/watchlist/data/watchlist_repository.dart';
import 'package:anilov/features/watchlist/domain/models/history_item.dart';
import 'package:anilov/features/watchlist/domain/models/watch_status.dart';
import 'package:anilov/features/watchlist/domain/models/watchlist_item.dart';

const Map<String, dynamic> sampleAnimeJson = {
  'id': 16498,
  'idMal': 16498,
  'title': {
    'romaji': 'Shingeki no Kyojin',
    'english': 'Attack on Titan',
    'native': '進撃の巨人',
    'userPreferred': 'Attack on Titan',
  },
  'coverImage': {
    'extraLarge': 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx16498.jpg',
    'large': 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/medium/bx16498.jpg',
    'medium': 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/small/bx16498.jpg',
    'color': '#e4a05a',
  },
  'bannerImage': 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/16498.jpg',
  'description': 'Centuries ago, mankind was almost slaughtered...<br><br><b>Enter Eren!</b>',
  'format': 'TV',
  'status': 'FINISHED',
  'seasonYear': 2013,
  'season': 'SPRING',
  'episodes': 25,
  'duration': 24,
  'averageScore': 85,
  'popularity': 540000,
  'genres': ['Action', 'Drama', 'Fantasy', 'Mystery'],
  'studios': {
    'nodes': [
      {'name': 'WIT Studio'}
    ]
  },
  'trailer': {
    'id': 'MGRm4IzK1SQ',
    'site': 'youtube',
  },
  'externalLinks': [
    {
      'id': 101,
      'site': 'Crunchyroll',
      'url': 'https://www.crunchyroll.com/attack-on-titan',
      'type': 'STREAMING',
    },
    {
      'id': 102,
      'site': 'Netflix',
      'url': 'https://www.netflix.com/title/70299043',
      'type': 'STREAMING',
    }
  ],
  'nextAiringEpisode': null,
  'relations': {
    'edges': [
      {
        'relationType': 'SEQUEL',
        'node': {
          'id': 20958,
          'title': {
            'userPreferred': 'Attack on Titan Season 2',
            'english': 'Attack on Titan Season 2',
            'romaji': 'Shingeki no Kyojin Season 2',
          },
          'coverImage': {
            'medium': 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/medium/20958.jpg',
            'large': 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/20958.jpg',
          },
          'format': 'TV',
          'status': 'FINISHED',
        }
      }
    ]
  }
};

const Map<String, dynamic> sampleAnimeWithNullsJson = {
  'id': 99999,
  'idMal': null,
  'title': null,
  'coverImage': null,
  'bannerImage': null,
  'description': null,
  'format': null,
  'status': null,
  'seasonYear': null,
  'season': null,
  'episodes': null,
  'duration': null,
  'averageScore': null,
  'popularity': null,
  'genres': null,
  'studios': null,
  'trailer': null,
  'externalLinks': null,
  'nextAiringEpisode': null,
  'relations': null,
};

const Map<String, dynamic> samplePageJson = {
  'Page': {
    'pageInfo': {
      'total': 120,
      'currentPage': 1,
      'lastPage': 6,
      'hasNextPage': true,
      'perPage': 20,
    },
    'media': [
      sampleAnimeJson,
    ]
  }
};

class FakeAnimeRepository implements AnimeRepository {
  final List<AnimeMedia> items;
  final bool shouldFail;

  FakeAnimeRepository(this.items, {this.shouldFail = false});

  @override
  Future<List<AnimeMedia>> getTrendingAnime({int page = 1, int perPage = 10}) async {
    if (shouldFail) throw Exception('Network timeout error');
    return items;
  }

  @override
  Future<List<AnimeMedia>> getPopularAnime({int page = 1, int perPage = 10}) async {
    if (shouldFail) throw Exception('Network timeout error');
    return items;
  }

  @override
  Future<List<AnimeMedia>> getTopRatedAnime({int page = 1, int perPage = 10}) async {
    if (shouldFail) throw Exception('Network timeout error');
    return items;
  }

  @override
  Future<List<AnimeMedia>> getAiringTodayAnime({int page = 1, int perPage = 10}) async {
    if (shouldFail) throw Exception('Network timeout error');
    return items;
  }

  @override
  Future<List<AnimeMedia>> getCurrentlyAiringAnime({int page = 1, int perPage = 10}) async {
    if (shouldFail) throw Exception('Network timeout error');
    return items;
  }

  @override
  Future<AnimeMedia> getAnimeDetails(int id) async {
    if (shouldFail) throw Exception('Failed to load anime details');
    return items.first;
  }

  @override
  Future<PaginatedAnime> searchAnime({
    String? query,
    String? genre,
    String? format,
    String? status,
    int? year,
    String sort = 'TRENDING_DESC',
    int page = 1,
    int perPage = 20,
  }) async {
    if (shouldFail) throw Exception('Search error');
    if (query == 'empty') {
      return const PaginatedAnime(pageInfo: PageInfo(), items: []);
    }
    return PaginatedAnime(pageInfo: const PageInfo(total: 1), items: items);
  }

  @override
  Future<List<String>> getGenres() async => ['Action', 'Adventure', 'Comedy', 'Drama'];
}

class FakeWatchlistRepository implements WatchlistRepository {
  final Map<int, WatchlistItem> _items = {};

  FakeWatchlistRepository([List<WatchlistItem> initialItems = const []]) {
    for (final item in initialItems) {
      _items[item.animeId] = item;
    }
  }

  @override
  Future<List<WatchlistItem>> getWatchlist({
    WatchStatus? status,
    String? searchQuery,
    String sortBy = 'updated_at',
    bool ascending = false,
  }) async {
    var result = _items.values.toList();
    if (status != null) {
      result = result.where((it) => it.status == status).toList();
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      result = result.where((it) => it.title.toLowerCase().contains(q)).toList();
    }
    result.sort((a, b) {
      int cmp;
      if (sortBy == 'title') {
        cmp = a.title.compareTo(b.title);
      } else if (sortBy == 'progress') {
        cmp = a.progress.compareTo(b.progress);
      } else if (sortBy == 'score') {
        cmp = (a.score ?? 0.0).compareTo(b.score ?? 0.0);
      } else {
        cmp = a.updatedAt.compareTo(b.updatedAt);
      }
      return ascending ? cmp : -cmp;
    });
    return result;
  }

  @override
  Future<WatchlistItem?> getWatchlistItem(int animeId) async => _items[animeId];

  @override
  Future<void> saveWatchlistItem(WatchlistItem item) async {
    _items[item.animeId] = item;
  }

  @override
  Future<void> updateProgress(int animeId, int progress) async {
    final cur = _items[animeId];
    if (cur == null) return;
    var st = cur.status;
    if (cur.totalEpisodes != null && cur.totalEpisodes! > 0 && progress >= cur.totalEpisodes!) {
      st = WatchStatus.completed;
    } else if (st == WatchStatus.planning && progress > 0) {
      st = WatchStatus.watching;
    }
    _items[animeId] = cur.copyWith(
      progress: progress,
      status: st,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> updateStatus(int animeId, WatchStatus status) async {
    final cur = _items[animeId];
    if (cur == null) return;
    _items[animeId] = cur.copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> updateScore(int animeId, double? score) async {
    final cur = _items[animeId];
    if (cur == null) return;
    _items[animeId] = cur.copyWith(
      score: score,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteWatchlistItem(int animeId) async {
    _items.remove(animeId);
  }

  @override
  Future<bool> isInWatchlist(int animeId) async => _items.containsKey(animeId);

  @override
  Future<List<WatchlistItem>> getContinueWatching({int limit = 10}) async {
    final list = _items.values
        .where((it) =>
            it.status == WatchStatus.watching ||
            (it.progress > 0 &&
                it.status != WatchStatus.completed &&
                it.status != WatchStatus.dropped))
        .toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list.take(limit).toList();
  }

  @override
  Future<Map<WatchStatus, int>> getWatchlistCounts() async {
    final counts = <WatchStatus, int>{
      WatchStatus.watching: 0,
      WatchStatus.planning: 0,
      WatchStatus.completed: 0,
      WatchStatus.onHold: 0,
      WatchStatus.dropped: 0,
    };
    for (final it in _items.values) {
      counts[it.status] = (counts[it.status] ?? 0) + 1;
    }
    return counts;
  }
}

class FakeHistoryRepository implements HistoryRepository {
  final List<HistoryItem> _items = [];
  int _nextId = 1;

  FakeHistoryRepository([List<HistoryItem> initialItems = const []]) {
    for (final it in initialItems) {
      _items.add(it.copyWith(id: it.id ?? _nextId++));
    }
  }

  @override
  Future<void> recordHistory({
    required int animeId,
    required String title,
    String? coverUrl,
    required int episode,
  }) async {
    _items.removeWhere((it) => it.animeId == animeId && it.episode == episode);
    _items.insert(
      0,
      HistoryItem(
        id: _nextId++,
        animeId: animeId,
        title: title,
        coverUrl: coverUrl,
        episode: episode,
        watchedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<List<HistoryItem>> getHistory({int limit = 50, int offset = 0}) async {
    return _items.skip(offset).take(limit).toList();
  }

  @override
  Future<void> deleteHistoryItem(int id) async {
    _items.removeWhere((it) => it.id == id);
  }

  @override
  Future<void> deleteHistoryForAnime(int animeId) async {
    _items.removeWhere((it) => it.animeId == animeId);
  }

  @override
  Future<void> clearHistory() async {
    _items.clear();
  }

  @override
  Future<int?> getLatestWatchedEpisode(int animeId) async {
    final match = _items.where((it) => it.animeId == animeId);
    if (match.isEmpty) return null;
    return match.first.episode;
  }
}

