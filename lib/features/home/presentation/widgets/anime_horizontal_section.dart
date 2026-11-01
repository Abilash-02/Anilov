import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../anime/domain/models/anime_media.dart';
import '../../../anime/presentation/widgets/anime_card.dart';

class AnimeHorizontalSection extends StatelessWidget {
  final String title;
  final List<AnimeMedia> items;
  final bool isLoading;
  final VoidCallback? onSeeAll;

  const AnimeHorizontalSection({
    super.key,
    required this.title,
    this.items = const [],
    this.isLoading = false,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.violetLight,
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 16, color: AppTheme.violetLight),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Cards List / Skeleton
        SizedBox(
          height: 215,
          child: isLoading
              ? ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => _buildSkeletonCard(isDark),
                )
              : items.isEmpty
                  ? Center(
                      child: Text(
                        'No anime available',
                        style: TextStyle(
                          color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return AnimeCard(
                          anime: items[index],
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildSkeletonCard(bool isDark) {
    return Container(
      width: 135,
      height: 210,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262630) : const Color(0xFFE2E8F0),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.cardRadius - 1)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 90,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF333340) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 50,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF262630) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
