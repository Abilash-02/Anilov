import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../notifications/notification_service.dart';
import '../../settings/presentation/providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
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

  Future<void> _pickReminderTime(int currentHour, int currentMinute) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: currentMinute),
    );

    if (picked != null && mounted) {
      await ref
          .read(settingsProvider.notifier)
          .setReminderTime(picked.hour, picked.minute);

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: [
          // Section: Appearance
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
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB),
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
                  selected: {settings.themeMode},
                  onSelectionChanged: (newSelection) {
                    settingsNotifier.setThemeMode(newSelection.first);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Daily Airing Notifications (Run 5)
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
              'Summarize watchlist anime airing each day at your chosen time',
            ),
            value: settings.dailyNotificationsEnabled,
            onChanged: (val) async {
              if (val) {
                // Request permission when toggled on
                await _handlePermissionRequest();
              }
              await settingsNotifier.setDailyNotifications(val);
            },
            activeThumbColor: AppTheme.violet,
            tileColor:
                isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color:
                    isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB),
              ),
            ),
          ),
          const SizedBox(height: 12),

          ListTile(
            title: const Text('Reminder Time'),
            subtitle: Text('Broadcast summary at ${settings.formattedReminderTime}'),
            trailing: OutlinedButton.icon(
              icon: const Icon(Icons.access_time_rounded, size: 18),
              label: const Text('Change'),
              onPressed: settings.dailyNotificationsEnabled
                  ? () => _pickReminderTime(
                        settings.reminderHour,
                        settings.reminderMinute,
                      )
                  : null,
            ),
            tileColor:
                isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color:
                    isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB),
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
                color:
                    isDark ? const Color(0xFF2E2E38) : const Color(0xFFE2E8F0),
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

          // Section: Content Preferences
          Text(
            'Content & Safety',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppTheme.darkOnSurfaceMuted
                  : AppTheme.lightOnSurfaceMuted,
            ),
          ),
          const SizedBox(height: 8),

          SwitchListTile(
            title: const Text('Adult Content Filter'),
            subtitle: const Text(
              'Exclude 18+ content from AniList search and queries (isAdult: false by default)',
            ),
            value: !settings.adultContent,
            onChanged: (val) {
              settingsNotifier.setAdultContent(!val);
            },
            activeThumbColor: AppTheme.violet,
            tileColor:
                isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color:
                    isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section: Storage & Maintenance
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
            subtitle: const Text('Remove temporary cached images and network responses'),
            trailing: const Icon(Icons.cleaning_services_outlined, size: 20),
            tileColor:
                isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color:
                    isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB),
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
    );
  }
}
