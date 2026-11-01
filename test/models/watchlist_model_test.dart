// Unit tests for Watchlist and History models

import 'package:flutter_test/flutter_test.dart';
import 'package:anilov/features/watchlist/domain/models/history_item.dart';
import 'package:anilov/features/watchlist/domain/models/watch_status.dart';
import 'package:anilov/features/watchlist/domain/models/watchlist_item.dart';

void main() {
  group('WatchStatus Tests', () {
    test('converts strings and handles case variations safely', () {
      expect(WatchStatus.fromString('watching'), WatchStatus.watching);
      expect(WatchStatus.fromString('current'), WatchStatus.watching);
      expect(WatchStatus.fromString('Planning'), WatchStatus.planning);
      expect(WatchStatus.fromString('plan_to_watch'), WatchStatus.planning);
      expect(WatchStatus.fromString('Completed'), WatchStatus.completed);
      expect(WatchStatus.fromString('Finished'), WatchStatus.completed);
      expect(WatchStatus.fromString('on_hold'), WatchStatus.onHold);
      expect(WatchStatus.fromString('dropped'), WatchStatus.dropped);
      expect(WatchStatus.fromString(null), WatchStatus.planning);
      expect(WatchStatus.fromString('unknown_value'), WatchStatus.planning);
    });

    test('toDbString and fromDbString are bijective', () {
      for (final status in WatchStatus.values) {
        final dbStr = status.toDbString();
        expect(WatchStatus.fromDbString(dbStr), status);
      }
    });
  });

  group('WatchlistItem Model Tests', () {
    final now = DateTime(2026, 11, 1, 12, 0);

    test('serializes to and from Map correctly', () {
      final item = WatchlistItem(
        animeId: 16498,
        title: 'Attack on Titan',
        coverUrl: 'https://example.com/aot.jpg',
        format: 'TV',
        totalEpisodes: 25,
        status: WatchStatus.watching,
        progress: 12,
        score: 9.5,
        updatedAt: now,
        createdAt: now,
      );

      final map = item.toMap();
      expect(map['anime_id'], 16498);
      expect(map['title'], 'Attack on Titan');
      expect(map['cover_url'], 'https://example.com/aot.jpg');
      expect(map['format'], 'TV');
      expect(map['total_episodes'], 25);
      expect(map['status'], 'WATCHING');
      expect(map['progress'], 12);
      expect(map['score'], 9.5);
      expect(map['updated_at'], now.millisecondsSinceEpoch);
      expect(map['created_at'], now.millisecondsSinceEpoch);

      final fromMap = WatchlistItem.fromMap(map);
      expect(fromMap.animeId, item.animeId);
      expect(fromMap.title, item.title);
      expect(fromMap.coverUrl, item.coverUrl);
      expect(fromMap.format, item.format);
      expect(fromMap.totalEpisodes, item.totalEpisodes);
      expect(fromMap.status, item.status);
      expect(fromMap.progress, item.progress);
      expect(fromMap.score, item.score);
    });

    test('handles null and missing fields with safe defaults', () {
      final item = WatchlistItem.fromMap(const {
        'anime_id': 99999,
      });

      expect(item.animeId, 99999);
      expect(item.title, 'Unknown Title');
      expect(item.coverUrl, isNull);
      expect(item.format, isNull);
      expect(item.totalEpisodes, isNull);
      expect(item.status, WatchStatus.planning);
      expect(item.progress, 0);
      expect(item.score, isNull);
      expect(item.isFinished, isFalse);
      expect(item.canIncrement, isTrue);
      expect(item.progressFraction, 0.0);
    });

    test('progress calculations with known total episodes', () {
      final item = WatchlistItem(
        animeId: 1,
        title: 'Sample',
        totalEpisodes: 10,
        progress: 5,
        status: WatchStatus.watching,
        updatedAt: now,
        createdAt: now,
      );

      expect(item.progressFraction, 0.5);
      expect(item.canIncrement, isTrue);
      expect(item.isFinished, isFalse);

      final completedItem = item.copyWith(progress: 10);
      expect(completedItem.progressFraction, 1.0);
      expect(completedItem.canIncrement, isFalse);
      expect(completedItem.isFinished, isTrue);
    });

    test('progress calculations with unknown total episodes', () {
      final item = WatchlistItem(
        animeId: 2,
        title: 'Ongoing One Piece',
        totalEpisodes: null,
        progress: 1080,
        status: WatchStatus.watching,
        updatedAt: now,
        createdAt: now,
      );

      expect(item.progressFraction, 0.0);
      expect(item.canIncrement, isTrue);
      expect(item.isFinished, isFalse);
    });
  });

  group('HistoryItem Model Tests', () {
    final now = DateTime(2026, 11, 1, 14, 0);

    test('serializes to and from Map correctly', () {
      final item = HistoryItem(
        id: 42,
        animeId: 16498,
        title: 'Attack on Titan',
        coverUrl: 'https://example.com/aot.jpg',
        episode: 15,
        watchedAt: now,
      );

      final map = item.toMap();
      expect(map['id'], 42);
      expect(map['anime_id'], 16498);
      expect(map['title'], 'Attack on Titan');
      expect(map['cover_url'], 'https://example.com/aot.jpg');
      expect(map['episode'], 15);
      expect(map['watched_at'], now.millisecondsSinceEpoch);

      final fromMap = HistoryItem.fromMap(map);
      expect(fromMap.id, 42);
      expect(fromMap.animeId, 16498);
      expect(fromMap.title, 'Attack on Titan');
      expect(fromMap.coverUrl, 'https://example.com/aot.jpg');
      expect(fromMap.episode, 15);
      expect(fromMap.watchedAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('handles missing fields gracefully', () {
      final item = HistoryItem.fromMap(const {
        'anime_id': 100,
      });

      expect(item.id, isNull);
      expect(item.animeId, 100);
      expect(item.title, 'Unknown Title');
      expect(item.coverUrl, isNull);
      expect(item.episode, 1);
    });
  });
}
