import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../common/widgets/anilov_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About & Attribution'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Centered App Logo
            const Center(
              child: AnilovLogo(
                size: 64,
                direction: Axis.vertical,
                showWordmark: true,
                showTagline: true,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Version 1.0.0 (RUN 5 — Daily Updates & Polish)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppTheme.darkOnSurfaceMuted
                      : AppTheme.lightOnSurfaceMuted,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Legal & Data Boundaries
            Text(
              'Legal Boundaries & Policy',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
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
              child: Text(
                'Anilov strictly adheres to authorized sources only:\n\n'
                '• Video playback is restricted to official YouTube trailer embeds, '
                'official "Where to watch" links from AniList data, and user-selected local video files.\n'
                '• Never scrapes websites, never integrates unlicensed streaming providers, '
                'and never bypasses DRM or copyright restrictions.\n'
                '• Adult content is excluded by default (isAdult: false).\n'
                '• No fabricated data, fake ratings, or fake video streams are used.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color:
                      isDark ? AppTheme.darkOnSurface : AppTheme.lightOnSurface,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Attributions
            Text(
              'Data Sources & Attribution',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
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
                    'AniList GraphQL API',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Anime metadata, airing schedules, and official streaming links are provided by the official public AniList API (https://anilist.co).',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark
                          ? AppTheme.darkOnSurfaceMuted
                          : AppTheme.lightOnSurfaceMuted,
                    ),
                  ),
                  const Divider(height: 24),
                  const Text(
                    'ani.zip Community Service',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Episode enrichment titles and metadata mappings are provided by ani.zip (https://api.ani.zip). ani.zip is used exclusively for episode metadata and never for video streams.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark
                          ? AppTheme.darkOnSurfaceMuted
                          : AppTheme.lightOnSurfaceMuted,
                    ),
                  ),
                  const Divider(height: 24),
                  const Text(
                    'YouTube & Google',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Official anime trailers are played via the YouTube IFrame Player API in compliance with YouTube Terms of Service.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark
                          ? AppTheme.darkOnSurfaceMuted
                          : AppTheme.lightOnSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Open Source Packages
            Text(
              'Open Source Technologies',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
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
              child: Text(
                'Built with Flutter, Material 3, flutter_riverpod, go_router, sqflite, dio, '
                'cached_network_image, chewie, video_player, flutter_local_notifications, '
                'workmanager, and file_picker.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: isDark
                    ? AppTheme.darkOnSurfaceMuted
                    : AppTheme.lightOnSurfaceMuted,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
