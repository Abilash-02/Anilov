import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anilov/features/settings/domain/models/app_settings.dart';
import 'package:anilov/features/settings/presentation/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppSettings Domain Model', () {
    test('default values are conservative and legal boundaries compliant', () {
      const settings = AppSettings();
      expect(settings.themeMode, ThemeMode.system);
      expect(settings.adultContent, false); // Section 4: isAdult: false by default
      expect(settings.dailyNotificationsEnabled, true);
      expect(settings.reminderHour, 9);
      expect(settings.reminderMinute, 0);
      expect(settings.showReminders, isEmpty);
    });

    test('formattedReminderTime formats 12-hour AM/PM correctly', () {
      const am = AppSettings(reminderHour: 9, reminderMinute: 5);
      expect(am.formattedReminderTime, '9:05 AM');

      const pm = AppSettings(reminderHour: 18, reminderMinute: 30);
      expect(pm.formattedReminderTime, '6:30 PM');

      const midnight = AppSettings(reminderHour: 0, reminderMinute: 0);
      expect(midnight.formattedReminderTime, '12:00 AM');

      const noon = AppSettings(reminderHour: 12, reminderMinute: 45);
      expect(noon.formattedReminderTime, '12:45 PM');
    });

    test('copyWith updates specified fields only', () {
      const initial = AppSettings();
      final updated = initial.copyWith(
        themeMode: ThemeMode.dark,
        adultContent: true,
        reminderHour: 20,
        reminderMinute: 15,
        showReminders: {1001, 1002},
      );

      expect(updated.themeMode, ThemeMode.dark);
      expect(updated.adultContent, true);
      expect(updated.reminderHour, 20);
      expect(updated.reminderMinute, 15);
      expect(updated.showReminders, {1001, 1002});
      expect(updated.dailyNotificationsEnabled, true);
    });
  });

  group('SettingsNotifier Riverpod Provider', () {
    test('loads default settings and updates themeMode', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(settingsProvider.notifier);

      expect(container.read(settingsProvider).themeMode, ThemeMode.system);
      expect(container.read(themeModeProvider), ThemeMode.system);

      await notifier.setThemeMode(ThemeMode.dark);
      expect(container.read(settingsProvider).themeMode, ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);

      await notifier.setThemeMode(ThemeMode.light);
      expect(container.read(settingsProvider).themeMode, ThemeMode.light);
      expect(container.read(themeModeProvider), ThemeMode.light);
    });

    test('updates adult content filter', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(settingsProvider.notifier);
      expect(container.read(settingsProvider).adultContent, false);

      await notifier.setAdultContent(true);
      expect(container.read(settingsProvider).adultContent, true);

      await notifier.setAdultContent(false);
      expect(container.read(settingsProvider).adultContent, false);
    });

    test('updates reminder time and toggles per-show reminders', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(settingsProvider.notifier);

      await notifier.setReminderTime(14, 30);
      expect(container.read(settingsProvider).reminderHour, 14);
      expect(container.read(settingsProvider).reminderMinute, 30);

      expect(notifier.hasShowReminder(16498), false);
      await notifier.toggleShowReminder(16498);
      expect(notifier.hasShowReminder(16498), true);
      expect(container.read(settingsProvider).showReminders.contains(16498), true);

      await notifier.toggleShowReminder(16498);
      expect(notifier.hasShowReminder(16498), false);
    });
  });
}
