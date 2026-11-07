// History repository interface and SQLite implementation

import '../domain/models/history_item.dart';
import 'app_database.dart';

abstract class HistoryRepository {
  Future<void> recordHistory({
    required int animeId,
    required String title,
    String? coverUrl,
    required int episode,
  });

  Future<List<HistoryItem>> getHistory({int limit = 50, int offset = 0});

  Future<void> deleteHistoryItem(int id);

  Future<void> deleteHistoryForAnime(int animeId);

  Future<void> clearHistory();

  Future<int?> getLatestWatchedEpisode(int animeId);
}

class SqfliteHistoryRepository implements HistoryRepository {
  final AppDatabase _dbHelper;

  SqfliteHistoryRepository({AppDatabase? dbHelper})
      : _dbHelper = dbHelper ?? AppDatabase();

  @override
  Future<void> recordHistory({
    required int animeId,
    required String title,
    String? coverUrl,
    required int episode,
  }) async {
    final db = await _dbHelper.database;
    final item = HistoryItem(
      animeId: animeId,
      title: title,
      coverUrl: coverUrl,
      episode: episode,
      watchedAt: DateTime.now(),
    );

    // Delete existing entry for this anime + episode so we record the newest timestamp
    await db.delete(
      AppDatabase.tableHistory,
      where: 'anime_id = ? AND episode = ?',
      whereArgs: [animeId, episode],
    );

    await db.insert(
      AppDatabase.tableHistory,
      item.toMap(),
    );
  }

  @override
  Future<List<HistoryItem>> getHistory({int limit = 50, int offset = 0}) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      AppDatabase.tableHistory,
      orderBy: 'watched_at DESC, id DESC',
      limit: limit,
      offset: offset,
    );

    return result.map((map) => HistoryItem.fromMap(map)).toList();
  }

  @override
  Future<void> deleteHistoryItem(int id) async {
    final db = await _dbHelper.database;
    await db.delete(
      AppDatabase.tableHistory,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteHistoryForAnime(int animeId) async {
    final db = await _dbHelper.database;
    await db.delete(
      AppDatabase.tableHistory,
      where: 'anime_id = ?',
      whereArgs: [animeId],
    );
  }

  @override
  Future<void> clearHistory() async {
    final db = await _dbHelper.database;
    await db.delete(AppDatabase.tableHistory);
  }

  @override
  Future<int?> getLatestWatchedEpisode(int animeId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      AppDatabase.tableHistory,
      columns: ['episode'],
      where: 'anime_id = ?',
      whereArgs: [animeId],
      orderBy: 'watched_at DESC',
      limit: 1,
    );

    if (result.isEmpty) return null;
    return (result.first['episode'] as num?)?.toInt();
  }
}
