// Continue watching horizontal section for Home screen

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../watchlist/domain/models/watchlist_item.dart';

class ContinueWatchingSection extends StatelessWidget {
  final List<WatchlistItem> items;
  final VoidCallback onSeeAll;

  const ContinueWatchingSection({
    super.key,
    required this.items,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

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
              Row(
                children: [
                  const Icon(
                    Icons.play_circle_fill_rounded,
                    color: AppTheme.violetLight,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Continue Watching',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onSeeAll,
                child: const Text(
                  'My Watchlist',
                  style: TextStyle(
                    color: AppTheme.violetLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Horizontal List
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12.0),
                child: InkWell(
                  onTap: () => context.push('/anime/${item.animeId}'),
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Poster with progress overlay
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          children: [
                            Container(
                              height: 135,
                              width: 120,
                              color: isDark
                                  ? AppTheme.darkSurfaceVariant
                                  : AppTheme.lightSurfaceVariant,
                              child: item.coverUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: item.coverUrl!,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => const Center(
                                        child: Icon(Icons.broken_image, size: 28),
                                      ),
                                    )
                                  : const Center(
                                      child: Icon(Icons.movie, size: 28),
                                    ),
                            ),
                            // Progress bar at bottom of card
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.65),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.totalEpisodes != null
                                          ? 'Ep ${item.progress} / ${item.totalEpisodes}'
                                          : 'Ep ${item.progress}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: LinearProgressIndicator(
                                        value: item.totalEpisodes != null && item.totalEpisodes! > 0
                                            ? item.progressFraction
                                            : 1.0,
                                        minHeight: 3,
                                        backgroundColor: Colors.white24,
                                        valueColor: const AlwaysStoppedAnimation<Color>(
                                          AppTheme.violetLight,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Title
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
