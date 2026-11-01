// Unit tests for AiringSchedule domain model

import 'package:flutter_test/flutter_test.dart';
import 'package:anilov/features/schedule/domain/models/airing_schedule.dart';
import '../fixtures/anime_fixtures.dart';

void main() {
  group('AiringSchedule Model Tests', () {
    test('parses from AniList GraphQL JSON correctly', () {
      final schedule = AiringSchedule.fromJson(sampleAiringScheduleJson);

      expect(schedule.id, 12345);
      expect(schedule.mediaId, 16498);
      expect(schedule.episode, 5);
      expect(schedule.timeUntilAiring, 3600);
      expect(schedule.media, isNotNull);
      expect(schedule.media!.id, 16498);
      expect(schedule.media!.title.displayTitle, 'Attack on Titan');
    });

    test('converts UTC airing timestamp to local timezone and weekday accurately', () {
      // 1700000000 = 2023-11-14 22:13:20 UTC (Tuesday)
      final schedule = AiringSchedule.fromJson({
        'id': 1,
        'airingAt': 1700000000,
        'timeUntilAiring': 0,
        'episode': 1,
        'mediaId': 100,
      });

      final localDt = schedule.airingAtLocal;
      expect(schedule.weekday, localDt.weekday);
      expect(schedule.formattedTime,
          '${localDt.hour.toString().padLeft(2, '0')}:${localDt.minute.toString().padLeft(2, '0')}');
    });

    test('countdownText formats future and past airings cleanly', () {
      final nowUtc = DateTime.now().toUtc();

      // Future airing: 2 hours from now
      final futureSchedule = AiringSchedule(
        id: 2,
        airingAt: nowUtc.add(const Duration(hours: 2, minutes: 15)),
        timeUntilAiring: 8100,
        episode: 3,
        mediaId: 101,
      );

      expect(futureSchedule.hasAired, isFalse);
      expect(futureSchedule.countdownText, contains('Airs in'));

      // Past airing: 3 hours ago
      final pastSchedule = AiringSchedule(
        id: 3,
        airingAt: nowUtc.subtract(const Duration(hours: 3)),
        timeUntilAiring: -10800,
        episode: 2,
        mediaId: 101,
      );

      expect(pastSchedule.hasAired, isTrue);
      expect(pastSchedule.countdownText, contains('Aired'));
    });

    test('handles missing and null fields gracefully', () {
      final schedule = AiringSchedule.fromJson(const {});

      expect(schedule.id, 0);
      expect(schedule.mediaId, 0);
      expect(schedule.episode, 1);
      expect(schedule.media, isNull);
    });
  });
}
