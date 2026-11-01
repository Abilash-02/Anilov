// Watchlist repository interface and SQLite implementation

import 'package:sqflite/sqflite.dart';

import '../domain/models/watch_status.dart';
import '../domain/models/watchlist_item.dart';
import 'app_database.dart';

abstract class WatchlistRepository {
  Future<List<WatchlistItem>> getWatchlist({
    WatchStatus? status,
    String? searchQuery,
    String sortBy = 'updated_at',
    bool ascending = false,
  });

  Future<WatchlistItem?> getWatchlistItem(int animeId);

  Future<void> saveWatchlistItem(WatchlistItem item);

  Future<void> updateProgress(int animeId, int progress);

  Future<void> updateStatus(int animeId, WatchStatus status);

  Future<void> updateScore(int animeId, double? score);

  Future<void> deleteWatchlistItem(int animeId);

  Future<bool> isInWatchlist(int animeId);

  Future<List<WatchlistItem>> getContinueWatching({int limit = 10});

  Future<Map<WatchStatus, int>> getWatchlistCounts();
}

class SqfliteWatchlistRepository implements WatchlistRepository {
  final AppDatabase _dbHelper;

  SqfliteWatchlistRepository({AppDatabase? dbHelper})
      : _dbHelper = dbHelper ?? AppDatabase();

  @override
  Future<List<WatchlistItem>> getWatchlist({
    WatchStatus? status,
    String? searchQuery,
    String sortBy = 'updated_at',
    bool ascending = false,
  }) async {
    final db = await _dbHelper.database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (status != null) {
      whereClauses.add('status = ?');
      whereArgs.add(status.toDbString());
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClauses.add('title LIKE ?');
      whereArgs.add('%${searchQuery.trim()}%');
    }

    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final allowedSortColumns = {'updated_at', 'title', 'progress', 'score', 'created_at'};
    final safeSortBy = allowedSortColumns.contains(sortBy) ? sortBy : 'updated_at';
    final orderDirection = ascending ? 'ASC' : 'DESC';
    final orderBy = '$safeSortBy $orderDirection';

    final result = await db.query(
      AppDatabase.tableWatchlist,
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: orderBy,
    );

    return result.map((map) => WatchlistItem.fromMap(map)).toList();
  }

  @override
  Future<WatchlistItem?> getWatchlistItem(int animeId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      AppDatabase.tableWatchlist,
      where: 'anime_id = ?',
      whereArgs: [animeId],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return WatchlistItem.fromMap(result.first);
  }

  @override
  Future<void> saveWatchlistItem(WatchlistItem item) async {
    final db = await _dbHelper.database;
    await db.insert(
      AppDatabase.tableWatchlist,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateProgress(int animeId, int progress) async {
    final db = await _dbHelper.database;
    final current = await getWatchlistItem(animeId);
    if (current == null) return;

    final clampedProgress = progress.clamp(0, 99999);
    var updatedStatus = current.status;

    // Auto-update to Completed if user finishes all episodes
    if (current.totalEpisodes != null &&
        current.totalEpisodes! > 0 &&
        clampedProgress >= current.totalEpisodes!) {
      updatedStatus = WatchStatus.completed;
    } else if (updatedStatus == WatchStatus.planning && clampedProgress > 0) {
      updatedStatus = WatchStatus.watching;
    }

    await db.update(
      AppDatabase.tableWatchlist,
      {
        'progress': clampedProgress,
        'status': updatedStatus.toDbString(),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'anime_id = ?',
      whereArgs: [animeId],
    );
  }

  @override
  Future<void> updateStatus(int animeId, WatchStatus status) async {
    final db = await _dbHelper.database;
    await db.update(
      AppDatabase.tableWatchlist,
      {
        'status': status.toDbString(),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'anime_id = ?',
      whereArgs: [animeId],
    );
  }

  @override
  Future<void> updateScore(int animeId, double? score) async {
    final db = await _dbHelper.database;
    await db.update(
      AppDatabase.tableWatchlist,
      {
        'score': score,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'anime_id = ?',
      whereArgs: [animeId],
    );
  }

  @override
  Future<void> deleteWatchlistItem(int animeId) async {
    final db = await _dbHelper.database;
    await db.delete(
      AppDatabase.tableWatchlist,
      where: 'anime_id = ?',
      whereArgs: [animeId],
    );
  }

  @override
  Future<bool> isInWatchlist(int animeId) async {
    final item = await getWatchlistItem(animeId);
    return item != null;
  }

  @override
  Future<List<WatchlistItem>> getContinueWatching({int limit = 10}) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      AppDatabase.tableWatchlist,
      where: "status = 'WATCHING' OR (progress > 0 AND status != 'COMPLETED' AND status != 'DROPPED')",
      orderBy: 'updated_at DESC',
      limit: limit,
    );

    return result.map((map) => WatchlistItem.fromMap(map)).toList();
  }

  @override
  Future<Map<WatchStatus, int>> getWatchlistCounts() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT status, COUNT(*) as count
      FROM ${AppDatabase.tableWatchlist}
      GROUP BY status
    ''');

    final counts = <WatchStatus, int>{
      WatchStatus.watching: 0,
      WatchStatus.planning: 0,
      WatchStatus.completed: 0,
      WatchStatus.onHold: 0,
      WatchStatus.dropped: 0,
    };

    for (final row in result) {
      final statusStr = row['status'] as String?;
      final count = (row['count'] as num?)?.toInt() ?? 0;
      if (statusStr != null) {
        final status = WatchStatus.fromDbString(statusStr);
        counts[status] = count;
      }
    }

    return counts;
  }
}
