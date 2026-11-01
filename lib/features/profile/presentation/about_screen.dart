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
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
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
              'Version 1.0.0 (Run 1 Foundation)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
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
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB),
              ),
            ),
            child: Text(
              'Anilov strictly adheres to authorized sources only. '
              'Trailers are streamed through official YouTube embeds. '
              'Where to watch directs to official licensed providers returned by AniList. '
              'No unauthorized scraping or unlicensed streaming is performed.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark ? AppTheme.darkOnSurface : AppTheme.lightOnSurface,
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
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB),
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
                  'Anime metadata, schedules, and airing details are provided by the official public AniList API (https://anilist.co).',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
                  ),
                ),
                const Divider(height: 24),
                const Text(
                  'ani.zip Community Service',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Episode enrichment titles and metadata mappings are provided by ani.zip (https://api.ani.zip).',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
