import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service managing local notifications for daily anime airing updates
/// and per-show broadcast reminders.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const String channelId = 'anilov_daily_airing';
  static const String channelName = 'Daily Airing Reminders';
  static const String channelDescription =
      'Notifications for watchlist anime broadcasting today';

  /// Initialize local notification channels and handlers
  Future<void> init() async {
    if (_initialized) return;

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked with payload: ${response.payload}');
        },
      );
      _initialized = true;
    } catch (e) {
      debugPrint('Failed to initialize NotificationService: $e');
    }
  }

  /// Request POST_NOTIFICATIONS runtime permission on Android 13+ (API 33+)
  Future<bool> requestPermission() async {
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('Notification permission request error: $e');
    }
    return false;
  }

  /// Show an immediate notification summarizing today's airing shows
  Future<void> showDailyAiringNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to display notification: $e');
    }
  }

  /// Cancel a specific notification
  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('Failed to cancel notification $id: $e');
    }
  }

  /// Cancel all active notifications
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Failed to cancel all notifications: $e');
    }
  }

  /// Utility to calculate the duration until the next target hour and minute
  static Duration calculateInitialDelay(
    int targetHour,
    int targetMinute, [
    DateTime? from,
  ]) {
    final now = from ?? DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      targetHour,
      targetMinute,
    );

    if (scheduled.isBefore(now)) {
      // If time has already passed today, schedule for tomorrow
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled.difference(now);
  }
}
