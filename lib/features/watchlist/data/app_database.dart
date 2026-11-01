// SQLite Database Helper for Anilov

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const String databaseName = 'anilov.db';
  static const int databaseVersion = 1;

  static const String tableWatchlist = 'watchlist';
  static const String tableHistory = 'watch_history';

  final Database? _injectedDb;
  Database? _db;

  AppDatabase([this._injectedDb]);

  Future<Database> get database async {
    if (_injectedDb != null) {
      return _injectedDb;
    }
    if (_db != null && _db!.isOpen) {
      return _db!;
    }
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, databaseName);

    return await openDatabase(
      path,
      version: databaseVersion,
      onCreate: (db, version) async {
        await _createTables(db);
      },
    );
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE $tableWatchlist (
        anime_id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        cover_url TEXT,
        format TEXT,
        total_episodes INTEGER,
        status TEXT NOT NULL,
        progress INTEGER NOT NULL DEFAULT 0,
        score REAL,
        updated_at INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_watchlist_status ON $tableWatchlist(status)
    ''');

    await db.execute('''
      CREATE INDEX idx_watchlist_updated_at ON $tableWatchlist(updated_at DESC)
    ''');

    await db.execute('''
      CREATE TABLE $tableHistory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        anime_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        cover_url TEXT,
        episode INTEGER NOT NULL,
        watched_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_history_anime_id ON $tableHistory(anime_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_history_watched_at ON $tableHistory(watched_at DESC)
    ''');
  }

  // Exposed for tests creating in-memory DB
  static Future<void> initializeSchema(Database db) async {
    await _createTables(db);
  }

  Future<void> close() async {
    if (_injectedDb != null) {
      await _injectedDb.close();
      return;
    }
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
