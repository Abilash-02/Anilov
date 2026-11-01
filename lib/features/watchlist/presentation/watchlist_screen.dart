import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const statuses = ['Watching', 'Planning', 'Completed', 'On Hold', 'Dropped'];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Watchlist',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Status Chips Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: statuses.map((status) {
                final isSelected = status == 'Watching';
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (_) {},
                    selectedColor: AppTheme.violet.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.violetLight,
                    backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.violetLight
                          : (isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Spacer(),

          // Empty State
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmark_border_outlined,
                  size: 64,
                  color: AppTheme.violetLight.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your Watchlist is Empty',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Local sqflite database persistence with offline progress tracking will be added in RUN 3.',
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
          const Spacer(),
        ],
      ),
    );
  }
}
