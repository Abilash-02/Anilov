import 'package:flutter/material.dart';

/// Application configuration and user preferences for Anilov.
class AppSettings {
  final ThemeMode themeMode;
  final bool adultContent;
  final bool dailyNotificationsEnabled;
  final int reminderHour;
  final int reminderMinute;
  final Set<int> showReminders;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.adultContent = false,
    this.dailyNotificationsEnabled = true,
    this.reminderHour = 9,
    this.reminderMinute = 0,
    this.showReminders = const {},
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? adultContent,
    bool? dailyNotificationsEnabled,
    int? reminderHour,
    int? reminderMinute,
    Set<int>? showReminders,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      adultContent: adultContent ?? this.adultContent,
      dailyNotificationsEnabled:
          dailyNotificationsEnabled ?? this.dailyNotificationsEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      showReminders: showReminders ?? this.showReminders,
    );
  }

  String get formattedReminderTime {
    final period = reminderHour >= 12 ? 'PM' : 'AM';
    final displayHour = reminderHour == 0
        ? 12
        : (reminderHour > 12 ? reminderHour - 12 : reminderHour);
    final displayMin = reminderMinute.toString().padLeft(2, '0');
    return '$displayHour:$displayMin $period';
  }
}
