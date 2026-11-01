import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return DefaultTabController(
      length: weekdays.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Broadcast Schedule',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppTheme.violetLight,
            labelColor: isDark ? Colors.white : AppTheme.violetDark,
            unselectedLabelColor: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
            tabs: weekdays.map((day) => Tab(text: day)).toList(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 64,
                  color: AppTheme.violetLight.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  'Airing Schedules',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'AniList broadcast schedule with automatic local time zone conversion will be active in RUN 4.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
