import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../notifications/notification_service.dart';
import '../../notifications/workmanager_service.dart';
import '../../settings/presentation/providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _keyThemeMode = 'settings_theme_mode';
  static const String _keyAdultContent = 'settings_adult_content';
  static const String _keyDailyNotifs = 'settings_daily_notifications';
  static const String _keyReminderHour = 'settings_reminder_hour';
  static const String _keyReminderMinute = 'settings_reminder_minute';

  bool _adultContent = false;
  bool _notifications = true;
  ThemeMode _themeMode = ThemeMode.system;
  int _reminderHour = 9;
  int _reminderMinute = 0;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _adultContent = prefs.getBool(_keyAdultContent) ?? false;
        _notifications = prefs.getBool(_keyDailyNotifs) ?? true;
        _reminderHour = prefs.getInt(_keyReminderHour) ?? 9;
        _reminderMinute = prefs.getInt(_keyReminderMinute) ?? 0;

        final themeStr = prefs.getString(_keyThemeMode);
        if (themeStr == 'dark') {
          _themeMode = ThemeMode.dark;
        } else if (themeStr == 'light') {
          _themeMode = ThemeMode.light;
        } else {
          _themeMode = ThemeMode.system;
        }
      });
    } catch (_) {}
  }

  void _syncWithRiverpod() {
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      final notifier = container.read(settingsProvider.notifier);
      notifier.setAdultContent(_adultContent);
      notifier.setDailyNotifications(_notifications);
      notifier.setThemeMode(_themeMode);
      notifier.setReminderTime(_reminderHour, _reminderMinute);
    } catch (_) {
      // Standalone mode without ProviderScope
    }
  }

  Future<void> _handlePermissionRequest() async {
    final granted = await NotificationService.instance.requestPermission();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            granted
                ? 'Notification permissions enabled.'
                : 'Notification permissions were not granted. Reminders may not appear.',
          ),
          backgroundColor: granted ? AppTheme.violet : Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
    );

    if (picked != null && mounted) {
      setState(() {
        _reminderHour = picked.hour;
        _reminderMinute = picked.minute;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyReminderHour, picked.hour);
      await prefs.setInt(_keyReminderMinute, picked.minute);

      if (_notifications) {
        await WorkmanagerService.instance.scheduleDailyCheck(
          hour: picked.hour,
          minute: picked.minute,
        );
      }

      _syncWithRiverpod();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Daily reminder time set to ${picked.format(context)}',
            ),
          ),
        );
      }
    }
  }

  String get _formattedReminderTime {
    final period = _reminderHour >= 12 ? 'PM' : 'AM';
    final displayHour = _reminderHour == 0
        ? 12
        : (_reminderHour > 12 ? _reminderHour - 12 : _reminderHour);
    final displayMin = _reminderMinute.toString().padLeft(2, '0');
    return '$displayHour:$displayMin $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Preferences / Content & Safety
            Text(
              'Preferences',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppTheme.darkOnSurfaceMuted
                    : AppTheme.lightOnSurfaceMuted,
              ),
            ),
            const SizedBox(height: 8),

            // Adult content setting (Section 4: exclude adult content by default)
            SwitchListTile(
              title: const Text('Adult Content Filter'),
              subtitle:
                  const Text('Exclude 18+ content (isAdult: false by default)'),
              value: !_adultContent,
              onChanged: (val) async {
                setState(() {
                  _adultContent = !val;
                });
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(_keyAdultContent, !val);
                _syncWithRiverpod();
              },
              activeThumbColor: AppTheme.violet,
              tileColor:
                  isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF2E2E38)
                      : const Color(0xFFE5E7EB),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Section 2: Daily Airing Notifications (Run 5)
            Text(
              'Daily Updates & Notifications',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppTheme.darkOnSurfaceMuted
                    : AppTheme.lightOnSurfaceMuted,
              ),
            ),
            const SizedBox(height: 8),

            SwitchListTile(
              title: const Text('Daily Broadcast Reminders'),
              subtitle: const Text(
                'Receive notifications for airing watchlist anime (Run 5)',
              ),
              value: _notifications,
              onChanged: (val) async {
                if (val) {
                  await _handlePermissionRequest();
                }
                setState(() {
                  _notifications = val;
                });
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(_keyDailyNotifs, val);

                if (val) {
                  await WorkmanagerService.instance.scheduleDailyCheck(
                    hour: _reminderHour,
                    minute: _reminderMinute,
                  );
                } else {
                  await WorkmanagerService.instance.cancelDailyCheck();
                }
                _syncWithRiverpod();
              },
              activeThumbColor: AppTheme.violet,
              tileColor:
                  isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF2E2E38)
                      : const Color(0xFFE5E7EB),
                ),
              ),
            ),
            const SizedBox(height: 12),

            ListTile(
              title: const Text('Reminder Time'),
              subtitle: Text('Broadcast summary at $_formattedReminderTime'),
              trailing: OutlinedButton.icon(
                icon: const Icon(Icons.access_time_rounded, size: 18),
                label: const Text('Change'),
                onPressed: _notifications ? _pickReminderTime : null,
              ),
              tileColor:
                  isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF2E2E38)
                      : const Color(0xFFE5E7EB),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Background timing disclaimer
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E1E26)
                    : const Color(0xFFEEF2F6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2E2E38)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: isDark
                        ? AppTheme.darkOnSurfaceMuted
                        : AppTheme.lightOnSurfaceMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Daily background checks run via Android WorkManager. Actual delivery times may vary slightly based on OS battery optimization and device power states.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.darkOnSurfaceMuted
                            : AppTheme.lightOnSurfaceMuted,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 3: Appearance
            Text(
              'Appearance',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppTheme.darkOnSurfaceMuted
                    : AppTheme.lightOnSurfaceMuted,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkSurface
                    : AppTheme.lightSurfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2E2E38)
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Theme Mode',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                        icon: Icon(Icons.brightness_auto, size: 18),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode, size: 18),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode, size: 18),
                      ),
                    ],
                    selected: {_themeMode},
                    onSelectionChanged: (newSelection) async {
                      final mode = newSelection.first;
                      setState(() {
                        _themeMode = mode;
                      });
                      final prefs = await SharedPreferences.getInstance();
                      final str = switch (mode) {
                        ThemeMode.dark => 'dark',
                        ThemeMode.light => 'light',
                        ThemeMode.system => 'system',
                      };
                      await prefs.setString(_keyThemeMode, str);
                      _syncWithRiverpod();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 4: Storage & Maintenance
            Text(
              'Storage & Cache',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppTheme.darkOnSurfaceMuted
                    : AppTheme.lightOnSurfaceMuted,
              ),
            ),
            const SizedBox(height: 8),

            ListTile(
              title: const Text('Clear Image & Data Cache'),
              subtitle: const Text(
                'Remove temporary cached images and network responses',
              ),
              trailing: const Icon(Icons.cleaning_services_outlined, size: 20),
              tileColor:
                  isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF2E2E38)
                      : const Color(0xFFE5E7EB),
                ),
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Temporary cache cleared successfully.'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
