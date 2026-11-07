import 'package:flutter_test/flutter_test.dart';
import 'package:anilov/features/notifications/notification_service.dart';

void main() {
  group('NotificationService Utilities', () {
    test('calculateInitialDelay returns difference for time later today', () {
      final base = DateTime(2026, 11, 7, 8, 0, 0); // 8:00 AM
      final delay = NotificationService.calculateInitialDelay(10, 30, base); // 10:30 AM
      expect(delay.inMinutes, 150); // 2 hours 30 mins
      expect(delay.isNegative, false);
    });

    test('calculateInitialDelay schedules for tomorrow if target time has passed', () {
      final base = DateTime(2026, 11, 7, 15, 0, 0); // 3:00 PM
      final delay = NotificationService.calculateInitialDelay(9, 0, base); // 9:00 AM
      // Delay to next day 9:00 AM = 9 hours until midnight + 9 hours = 18 hours
      expect(delay.inHours, 18);
      expect(delay.isNegative, false);
    });

    test('channel configuration constants are defined', () {
      expect(NotificationService.channelId, 'anilov_daily_airing');
      expect(NotificationService.channelName, 'Daily Airing Reminders');
      expect(NotificationService.channelDescription.isNotEmpty, true);
    });
  });
}
