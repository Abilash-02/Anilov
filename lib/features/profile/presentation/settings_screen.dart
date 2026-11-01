import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _adultContent = false;
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: [
          Text(
            'Preferences',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
            ),
          ),
          const SizedBox(height: 8),

          // Adult content setting (Section 4: exclude adult content by default)
          SwitchListTile(
            title: const Text('Adult Content Filter'),
            subtitle: const Text('Exclude 18+ content (isAdult: false by default)'),
            value: !_adultContent,
            onChanged: (val) {
              setState(() {
                _adultContent = !val;
              });
            },
            activeThumbColor: AppTheme.violet,
            tileColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Notification setting placeholder (Run 5)
          SwitchListTile(
            title: const Text('Daily Broadcast Reminders'),
            subtitle: const Text('Receive notifications for airing watchlist anime (Run 5)'),
            value: _notifications,
            onChanged: (val) {
              setState(() {
                _notifications = val;
              });
            },
            activeThumbColor: AppTheme.violet,
            tileColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
