import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'notification_service.dart';

/// Top-level callback dispatcher required by Workmanager
@pragma('vm:entry-point')
void anilovCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == WorkmanagerService.dailyAiringTask) {
        await NotificationService.instance.init();
        await NotificationService.instance.showDailyAiringNotification(
          id: 1001,
          title: 'Anilov Daily Airing Update',
          body:
              'Check today\'s schedule for newly airing episodes in your watchlist!',
          payload: '/schedule',
        );
      }
      return true;
    } catch (e) {
      debugPrint('Background workmanager task failed: $e');
      return false;
    }
  });
}

/// Service managing periodic background tasks via Android WorkManager
class WorkmanagerService {
  WorkmanagerService._();
  static final WorkmanagerService instance = WorkmanagerService._();

  static const String dailyAiringTask = 'com.anilov.dailyAiringSummary';
  static const String dailyAiringTag = 'anilov-airing-tag';

  bool _initialized = false;

  /// Initialize Workmanager with the background dispatcher
  Future<void> init() async {
    if (_initialized) return;

    try {
      await Workmanager().initialize(
        anilovCallbackDispatcher,
      );
      _initialized = true;
    } catch (e) {
      debugPrint('Failed to initialize Workmanager: $e');
    }
  }

  /// Schedule or replace the daily airing reminder periodic task
  Future<void> scheduleDailyCheck({
    required int hour,
    required int minute,
  }) async {
    try {
      if (!_initialized) await init();

      final initialDelay =
          NotificationService.calculateInitialDelay(hour, minute);

      await Workmanager().registerPeriodicTask(
        dailyAiringTask,
        dailyAiringTask,
        tag: dailyAiringTag,
        frequency: const Duration(hours: 24),
        initialDelay: initialDelay,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      );
      debugPrint(
        'Scheduled daily check at $hour:$minute (delay: ${initialDelay.inMinutes} mins)',
      );
    } catch (e) {
      debugPrint('Failed to schedule daily check: $e');
    }
  }

  /// Cancel scheduled background tasks
  Future<void> cancelDailyCheck() async {
    try {
      await Workmanager().cancelByUniqueName(dailyAiringTask);
      debugPrint('Cancelled daily airing workmanager task');
    } catch (e) {
      debugPrint('Failed to cancel workmanager task: $e');
    }
  }
}
