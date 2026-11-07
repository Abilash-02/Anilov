// Unit and integration tests for SQLite database persistence

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:anilov/features/watchlist/data/app_database.dart';
import 'package:anilov/features/watchlist/data/history_repository.dart';
import 'package:anilov/features/watchlist/data/watchlist_repository.dart';
import 'package:anilov/features/watchlist/domain/models/watch_status.dart';
import 'package:anilov/features/watchlist/domain/models/watchlist_item.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late AppDatabase dbHelper;
  late SqfliteWatchlistRepository watchlistRepo;
  late SqfliteHistoryRepository historyRepo;

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await AppDatabase.initializeSchema(db);
    dbHelper = AppDatabase(db);
    watchlistRepo = SqfliteWatchlistRepository(dbHelper: dbHelper);
    historyRepo = SqfliteHistoryRepository(dbHelper: dbHelper);
  });

  tearDown(() async {
    await db.close();
  });

  group('SQLite Watchlist Persistence Tests', () {
    test('add and retrieve watchlist item', () async {
      final now = DateTime.now();
      final item = WatchlistItem(
        animeId: 16498,
        title: 'Attack on Titan',
        coverUrl: 'https://example.com/aot.jpg',
        format: 'TV',
        totalEpisodes: 25,
        status: WatchStatus.watching,
        progress: 10,
        score: 9.0,
        updatedAt: now,
        createdAt: now,
      );

      await watchlistRepo.saveWatchlistItem(item);

      final retrieved = await watchlistRepo.getWatchlistItem(16498);
      expect(retrieved, isNotNull);
      expect(retrieved!.animeId, 16498);
      expect(retrieved.title, 'Attack on Titan');
      expect(retrieved.status, WatchStatus.watching);
      expect(retrieved.progress, 10);
      expect(retrieved.score, 9.0);
      expect(await watchlistRepo.isInWatchlist(16498), isTrue);
      expect(await watchlistRepo.isInWatchlist(99999), isFalse);
    });

    test('duplicate prevention: re-inserting existing animeId replaces without duplicate key error', () async {
      final now = DateTime.now();
      final item1 = WatchlistItem(
        animeId: 100,
        title: 'Demon Slayer',
        status: WatchStatus.planning,
        progress: 0,
        updatedAt: now,
        createdAt: now,
      );

      final item2 = WatchlistItem(
        animeId: 100,
        title: 'Demon Slayer: Kimetsu no Yaiba',
        status: WatchStatus.watching,
        progress: 4,
        updatedAt: now.add(const Duration(hours: 1)),
        createdAt: now,
      );

      await watchlistRepo.saveWatchlistItem(item1);
      await watchlistRepo.saveWatchlistItem(item2);

      final list = await watchlistRepo.getWatchlist();
      expect(list.length, 1);
      expect(list.first.title, 'Demon Slayer: Kimetsu no Yaiba');
      expect(list.first.status, WatchStatus.watching);
      expect(list.first.progress, 4);
    });

    test('updateProgress increments and automatically completes anime when total reached', () async {
      final now = DateTime.now();
      final item = WatchlistItem(
        animeId: 200,
        title: 'Mob Psycho 100',
        totalEpisodes: 12,
        status: WatchStatus.watching,
        progress: 11,
        updatedAt: now,
        createdAt: now,
      );

      await watchlistRepo.saveWatchlistItem(item);

      // Increment to 12 (completes show)
      await watchlistRepo.updateProgress(200, 12);
      final updated = await watchlistRepo.getWatchlistItem(200);

      expect(updated!.progress, 12);
      expect(updated.status, WatchStatus.completed);
    });

    test('updateProgress transitions from planning to watching when progress > 0', () async {
      final now = DateTime.now();
      final item = WatchlistItem(
        animeId: 201,
        title: 'Frieren: Beyond Journey\'s End',
        totalEpisodes: 28,
        status: WatchStatus.planning,
        progress: 0,
        updatedAt: now,
        createdAt: now,
      );

      await watchlistRepo.saveWatchlistItem(item);

      await watchlistRepo.updateProgress(201, 1);
      final updated = await watchlistRepo.getWatchlistItem(201);

      expect(updated!.progress, 1);
      expect(updated.status, WatchStatus.watching);
    });

    test('filter by status and search query', () async {
      final now = DateTime.now();
      await watchlistRepo.saveWatchlistItem(WatchlistItem(
        animeId: 1,
        title: 'Jujutsu Kaisen',
        status: WatchStatus.watching,
        updatedAt: now,
        createdAt: now,
      ));
      await watchlistRepo.saveWatchlistItem(WatchlistItem(
        animeId: 2,
        title: 'Chainsaw Man',
        status: WatchStatus.planning,
        updatedAt: now,
        createdAt: now,
      ));
      await watchlistRepo.saveWatchlistItem(WatchlistItem(
        animeId: 3,
        title: 'Jujutsu Kaisen 0',
        status: WatchStatus.completed,
        updatedAt: now,
        createdAt: now,
      ));

      final watchingOnly = await watchlistRepo.getWatchlist(status: WatchStatus.watching);
      expect(watchingOnly.length, 1);
      expect(watchingOnly.first.title, 'Jujutsu Kaisen');

      final searchJujutsu = await watchlistRepo.getWatchlist(searchQuery: 'jujutsu');
      expect(searchJujutsu.length, 2);

      final searchPlanning = await watchlistRepo.getWatchlist(
        status: WatchStatus.planning,
        searchQuery: 'chainsaw',
      );
      expect(searchPlanning.length, 1);
    });

    test('sorting by title, progress, and score', () async {
      final now = DateTime.now();
      await watchlistRepo.saveWatchlistItem(WatchlistItem(
        animeId: 1,
        title: 'Bleach',
        progress: 100,
        score: 8.0,
        updatedAt: now.subtract(const Duration(hours: 3)),
        createdAt: now,
      ));
      await watchlistRepo.saveWatchlistItem(WatchlistItem(
        animeId: 2,
        title: 'Naruto',
        progress: 220,
        score: 7.5,
        updatedAt: now.subtract(const Duration(hours: 1)),
        createdAt: now,
      ));
      await watchlistRepo.saveWatchlistItem(WatchlistItem(
        animeId: 3,
        title: 'One Piece',
        progress: 1050,
        score: 9.8,
        updatedAt: now,
        createdAt: now,
      ));

      // Title A-Z
      final sortedTitle = await watchlistRepo.getWatchlist(sortBy: 'title', ascending: true);
      expect(sortedTitle.map((e) => e.title).toList(), ['Bleach', 'Naruto', 'One Piece']);

      // Progress descending
      final sortedProgress = await watchlistRepo.getWatchlist(sortBy: 'progress', ascending: false);
      expect(sortedProgress.map((e) => e.title).toList(), ['One Piece', 'Naruto', 'Bleach']);

      // Score descending
      final sortedScore = await watchlistRepo.getWatchlist(sortBy: 'score', ascending: false);
      expect(sortedScore.map((e) => e.title).toList(), ['One Piece', 'Bleach', 'Naruto']);
    });

    test('continue watching retrieves active watching or in-progress shows', () async {
      final now = DateTime.now();
      await watchlistRepo.saveWatchlistItem(WatchlistItem(
        animeId: 1,
        title: 'Show 1',
        status: WatchStatus.watching,
        progress: 3,
        updatedAt: now,
        createdAt: now,
      ));
      await watchlistRepo.saveWatchlistItem(WatchlistItem(
        animeId: 2,
        title: 'Show 2',
        status: WatchStatus.completed,
        progress: 12,
        updatedAt: now,
        createdAt: now,
      ));
      await watchlistRepo.saveWatchlistItem(WatchlistItem(
        animeId: 3,
        title: 'Show 3',
        status: WatchStatus.planning,
        progress: 0,
        updatedAt: now,
        createdAt: now,
      ));

      final continueList = await watchlistRepo.getContinueWatching();
      expect(continueList.length, 1);
      expect(continueList.first.title, 'Show 1');
    });

    test('getWatchlistCounts returns accurate counts per status', () async {
      final now = DateTime.now();
      await watchlistRepo.saveWatchlistItem(WatchlistItem(
        animeId: 1,
        title: 'Show 1',
        status: WatchStatus.watching,
        updatedAt: now,
        createdAt: now,
      ));
      await watchlistRepo.saveWatchlistItem(WatchlistItem(
        animeId: 2,
        title: 'Show 2',
        status: WatchStatus.watching,
        updatedAt: now,
        createdAt: now,
      ));
      await watchlistRepo.saveWatchlistItem(WatchlistItem(
        animeId: 3,
        title: 'Show 3',
        status: WatchStatus.planning,
        updatedAt: now,
        createdAt: now,
      ));

      final counts = await watchlistRepo.getWatchlistCounts();
      expect(counts[WatchStatus.watching], 2);
      expect(counts[WatchStatus.planning], 1);
      expect(counts[WatchStatus.completed], 0);
      expect(counts[WatchStatus.onHold], 0);
      expect(counts[WatchStatus.dropped], 0);
    });

    test('deleteWatchlistItem removes item completely', () async {
      final now = DateTime.now();
      await watchlistRepo.saveWatchlistItem(WatchlistItem(
        animeId: 500,
        title: 'To Delete',
        updatedAt: now,
        createdAt: now,
      ));

      expect(await watchlistRepo.isInWatchlist(500), isTrue);
      await watchlistRepo.deleteWatchlistItem(500);
      expect(await watchlistRepo.isInWatchlist(500), isFalse);
    });
  });

  group('SQLite Watch History Persistence Tests', () {
    test('recordHistory and retrieve list ordered by watchedAt DESC', () async {
      await historyRepo.recordHistory(
        animeId: 10,
        title: 'Steins;Gate',
        episode: 1,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await historyRepo.recordHistory(
        animeId: 10,
        title: 'Steins;Gate',
        episode: 2,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await historyRepo.recordHistory(
        animeId: 20,
        title: 'Death Note',
        episode: 1,
      );

      final history = await historyRepo.getHistory();
      expect(history.length, 3);
      expect(history.first.title, 'Death Note');
      expect(history.first.episode, 1);

      final latestEp = await historyRepo.getLatestWatchedEpisode(10);
      expect(latestEp, 2);
    });

    test('re-watching episode replaces duplicate entry with newer timestamp', () async {
      await historyRepo.recordHistory(
        animeId: 10,
        title: 'Steins;Gate',
        episode: 1,
      );
      await historyRepo.recordHistory(
        animeId: 10,
        title: 'Steins;Gate',
        episode: 1,
      );

      final history = await historyRepo.getHistory();
      expect(history.length, 1);
    });

    test('deleteHistoryItem and clearHistory', () async {
      await historyRepo.recordHistory(
        animeId: 1,
        title: 'Show 1',
        episode: 1,
      );
      await historyRepo.recordHistory(
        animeId: 2,
        title: 'Show 2',
        episode: 1,
      );

      var list = await historyRepo.getHistory();
      expect(list.length, 2);

      await historyRepo.deleteHistoryItem(list.first.id!);
      list = await historyRepo.getHistory();
      expect(list.length, 1);

      await historyRepo.clearHistory();
      list = await historyRepo.getHistory();
      expect(list.isEmpty, isTrue);
    });
  });
}
