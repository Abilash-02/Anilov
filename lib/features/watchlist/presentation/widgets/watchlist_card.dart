// Watchlist card widget for displaying an anime in the user's watchlist

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/watch_status.dart';
import '../../domain/models/watchlist_item.dart';
import '../providers/watchlist_providers.dart';

class WatchlistCard extends ConsumerWidget {
  final WatchlistItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const WatchlistCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  Color _statusColor(WatchStatus status) {
    switch (status) {
      case WatchStatus.watching:
        return AppTheme.violetLight;
      case WatchStatus.planning:
        return Colors.blue;
      case WatchStatus.completed:
        return Colors.green;
      case WatchStatus.onHold:
        return Colors.amber;
      case WatchStatus.dropped:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = _statusColor(item.status);

    return InkWell(
      onTap: () => context.push('/anime/${item.animeId}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster thumbnail
            Container(
              width: 68,
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isDark ? AppTheme.darkSurfaceVariant : AppTheme.lightSurfaceVariant,
              ),
              clipBehavior: Clip.antiAlias,
              child: item.coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.coverUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 28),
                    )
                  : const Icon(Icons.movie, size: 28),
            ),
            const SizedBox(width: 12),

            // Anime info and progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Status and Format Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 0.8),
                        ),
                        child: Text(
                          item.status.displayName,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (item.format != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          item.format!,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
                          ),
                        ),
                      ],
                      if (item.score != null) ...[
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              item.score!.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Progress Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.totalEpisodes != null
                                      ? 'Ep ${item.progress} / ${item.totalEpisodes}'
                                      : 'Ep ${item.progress} / ?',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (item.totalEpisodes != null && item.totalEpisodes! > 0)
                                  Text(
                                    '${(item.progressFraction * 100).toInt()}%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppTheme.darkOnSurfaceMuted
                                          : AppTheme.lightOnSurfaceMuted,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: item.totalEpisodes != null && item.totalEpisodes! > 0
                                    ? item.progressFraction
                                    : (item.progress > 0 ? 1.0 : 0.0),
                                minHeight: 5,
                                backgroundColor: isDark
                                    ? AppTheme.darkSurfaceVariant
                                    : AppTheme.lightSurfaceVariant,
                                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Quick +1 Button
                      SizedBox(
                        height: 34,
                        child: OutlinedButton(
                          onPressed: item.canIncrement
                              ? () {
                                  ref.read(watchlistNotifierProvider.notifier).incrementProgress(
                                        item.animeId,
                                        title: item.title,
                                        coverUrl: item.coverUrl,
                                      );
                                }
                              : null,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            side: BorderSide(
                              color: isDark ? const Color(0xFF3E3E4C) : const Color(0xFFD1D5DB),
                            ),
                          ),
                          child: const Text(
                            '+1 Ep',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // More Menu (Edit / Delete)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                size: 20,
                color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
              ),
              onSelected: (action) {
                if (action == 'edit') {
                  onEdit();
                } else if (action == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Edit Status'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text('Remove', style: TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
