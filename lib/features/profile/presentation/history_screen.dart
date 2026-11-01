// Watch History screen backed by SQLite persistence

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../watchlist/presentation/providers/watchlist_providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1 && now.day == dt.day) {
      return 'Today at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 2) {
      return 'Yesterday at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Clear Watch History?'),
        content: const Text(
          'Are you sure you want to clear your entire watch history? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(dialogCtx);
              ref.read(historyNotifierProvider.notifier).clearHistory();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Watch history cleared'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final historyAsync = ref.watch(historyNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Watch History',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear History',
            onPressed: () => _confirmClearAll(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 52, color: Colors.redAccent),
                const SizedBox(height: 12),
                const Text(
                  'Failed to load watch history',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 64,
                      color: AppTheme.violetLight.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Watch History Yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'As you update your watched episode progress or finish anime, your activity will be preserved offline here.',
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
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(historyNotifierProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: items.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB),
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 48,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: isDark ? AppTheme.darkSurfaceVariant : AppTheme.lightSurfaceVariant,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: item.coverUrl != null
                        ? CachedNetworkImage(
                            imageUrl: item.coverUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 20),
                          )
                        : const Icon(Icons.movie, size: 20),
                  ),
                  title: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.violet.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Episode ${item.episode}',
                          style: const TextStyle(
                            color: AppTheme.violetLight,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(item.watchedAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Remove from history',
                    onPressed: () {
                      if (item.id != null) {
                        ref.read(historyNotifierProvider.notifier).removeItem(item.id!);
                      }
                    },
                  ),
                  onTap: () => context.push('/anime/${item.animeId}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
