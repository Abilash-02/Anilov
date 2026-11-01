import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Explore',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input Placeholder
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                border: Border.all(
                  color: isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Search anime titles, genres, studios...',
                    style: TextStyle(
                      color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Filter Chips Placeholder
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  'All Genres',
                  'Action',
                  'Adventure',
                  'Fantasy',
                  'Sci-Fi',
                  'Romance',
                ].map((genre) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Chip(
                      label: Text(genre),
                      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
                      side: BorderSide(
                        color: isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),

            // Empty state placeholder
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.explore_outlined,
                    size: 64,
                    color: AppTheme.violetLight.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Explore Anime Catalog',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Search filters, pagination, and sorting connect in RUN 2.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
