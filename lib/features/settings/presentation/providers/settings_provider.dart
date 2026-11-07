import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/app_settings.dart';
import '../../../notifications/workmanager_service.dart';

class SettingsNotifier extends Notifier<AppSettings> {
  static const String _keyThemeMode = 'settings_theme_mode';
  static const String _keyAdultContent = 'settings_adult_content';
  static const String _keyDailyNotifs = 'settings_daily_notifications';
  static const String _keyReminderHour = 'settings_reminder_hour';
  static const String _keyReminderMinute = 'settings_reminder_minute';
  static const String _keyShowReminders = 'settings_show_reminders';

  bool _isCustomized = false;

  @override
  AppSettings build() {
    // Initial default state; loads stored preferences asynchronously
    _loadPreferences();
    return const AppSettings();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_isCustomized) return;

      final themeStr = prefs.getString(_keyThemeMode);
      ThemeMode mode = ThemeMode.system;
      if (themeStr == 'dark') {
        mode = ThemeMode.dark;
      } else if (themeStr == 'light') {
        mode = ThemeMode.light;
      }

      final adult = prefs.getBool(_keyAdultContent) ?? false;
      final dailyNotifs = prefs.getBool(_keyDailyNotifs) ?? true;
      final hour = prefs.getInt(_keyReminderHour) ?? 9;
      final minute = prefs.getInt(_keyReminderMinute) ?? 0;
      final reminderList = prefs.getStringList(_keyShowReminders) ?? [];
      final reminders =
          reminderList.map((e) => int.tryParse(e) ?? 0).where((id) => id > 0).toSet();

      state = AppSettings(
        themeMode: mode,
        adultContent: adult,
        dailyNotificationsEnabled: dailyNotifs,
        reminderHour: hour,
        reminderMinute: minute,
        showReminders: reminders,
      );

      if (dailyNotifs) {
        WorkmanagerService.instance.scheduleDailyCheck(
          hour: hour,
          minute: minute,
        );
      }
    } catch (e) {
      debugPrint('Failed to load settings preferences: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _isCustomized = true;
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    final str = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_keyThemeMode, str);
  }

  Future<void> setAdultContent(bool enabled) async {
    _isCustomized = true;
    state = state.copyWith(adultContent: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAdultContent, enabled);
  }

  Future<void> setDailyNotifications(bool enabled) async {
    _isCustomized = true;
    state = state.copyWith(dailyNotificationsEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDailyNotifs, enabled);

    if (enabled) {
      await WorkmanagerService.instance.scheduleDailyCheck(
        hour: state.reminderHour,
        minute: state.reminderMinute,
      );
    } else {
      await WorkmanagerService.instance.cancelDailyCheck();
    }
  }

  Future<void> setReminderTime(int hour, int minute) async {
    _isCustomized = true;
    state = state.copyWith(reminderHour: hour, reminderMinute: minute);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyReminderHour, hour);
    await prefs.setInt(_keyReminderMinute, minute);

    if (state.dailyNotificationsEnabled) {
      await WorkmanagerService.instance.scheduleDailyCheck(
        hour: hour,
        minute: minute,
      );
    }
  }

  Future<void> toggleShowReminder(int animeId) async {
    _isCustomized = true;
    final current = Set<int>.from(state.showReminders);
    if (current.contains(animeId)) {
      current.remove(animeId);
    } else {
      current.add(animeId);
    }
    state = state.copyWith(showReminders: current);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _keyShowReminders,
      current.map((e) => e.toString()).toList(),
    );
  }

  bool hasShowReminder(int animeId) {
    return state.showReminders.contains(animeId);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider.select((s) => s.themeMode));
});
