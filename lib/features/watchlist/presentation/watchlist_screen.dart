// Full Watchlist Screen with local SQLite persistence and progress tracking

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/models/watch_status.dart';
import '../domain/models/watchlist_item.dart';
import 'providers/watchlist_providers.dart';
import 'widgets/watchlist_card.dart';
import 'widgets/watchlist_edit_sheet.dart';

class WatchlistScreen extends ConsumerStatefulWidget {
  const WatchlistScreen({super.key});

  @override
  ConsumerState<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends ConsumerState<WatchlistScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSortSheet(BuildContext context) {
    final filter = ref.read(watchlistFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Text(
                  'Sort Watchlist By',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.access_time_rounded),
                title: const Text('Recently Updated'),
                selected: filter.sortBy == 'updated_at',
                onTap: () {
                  ref.read(watchlistFilterProvider.notifier).setSortBy('updated_at');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sort_by_alpha_rounded),
                title: const Text('Title (A to Z)'),
                selected: filter.sortBy == 'title',
                onTap: () {
                  ref.read(watchlistFilterProvider.notifier).setSortBy('title', ascending: true);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_play_rounded),
                title: const Text('Progress (Most Watched)'),
                selected: filter.sortBy == 'progress',
                onTap: () {
                  ref.read(watchlistFilterProvider.notifier).setSortBy('progress');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.star_rounded),
                title: const Text('Score (Highest Rated)'),
                selected: filter.sortBy == 'score',
                onTap: () {
                  ref.read(watchlistFilterProvider.notifier).setSortBy('score');
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(WatchlistItem item) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Remove from Watchlist?'),
        content: Text(
          'Are you sure you want to remove "${item.title}" and your watched progress from your watchlist?',
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
              ref.read(watchlistNotifierProvider.notifier).removeItem(item.animeId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Removed "${item.title}" from watchlist'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filterState = ref.watch(watchlistFilterProvider);
    final watchlistAsync = ref.watch(watchlistNotifierProvider);
    final countsAsync = ref.watch(watchlistCountsProvider);

    final counts = countsAsync.valueOrNull ?? {};
    final totalCount = counts.values.fold<int>(0, (sum, val) => sum + val);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search your watchlist...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
                  ),
                ),
                style: const TextStyle(fontSize: 16),
                onChanged: (val) {
                  ref.read(watchlistFilterProvider.notifier).setSearchQuery(val);
                },
              )
            : const Text(
                'My Watchlist',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: _isSearching ? 'Close Search' : 'Search Watchlist',
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  ref.read(watchlistFilterProvider.notifier).setSearchQuery('');
                  _isSearching = false;
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort List',
            onPressed: () => _showSortSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                // "All" chip
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text('All ($totalCount)'),
                    selected: filterState.status == null,
                    onSelected: (_) {
                      ref.read(watchlistFilterProvider.notifier).setStatus(null);
                    },
                    selectedColor: AppTheme.violet.withValues(alpha: 0.25),
                    checkmarkColor: AppTheme.violetLight,
                    backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
                    side: BorderSide(
                      color: filterState.status == null
                          ? AppTheme.violetLight
                          : (isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB)),
                    ),
                  ),
                ),
                // Status chips
                ...WatchStatus.values.map((status) {
                  final isSelected = filterState.status == status;
                  final count = counts[status] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text('${status.displayName} ($count)'),
                      selected: isSelected,
                      onSelected: (_) {
                        ref.read(watchlistFilterProvider.notifier).setStatus(status);
                      },
                      selectedColor: AppTheme.violet.withValues(alpha: 0.25),
                      checkmarkColor: AppTheme.violetLight,
                      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
                      side: BorderSide(
                        color: isSelected
                            ? AppTheme.violetLight
                            : (isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB)),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Main Watchlist Content
          Expanded(
            child: watchlistAsync.when(
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
                        'Failed to load watchlist',
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
                            Icons.bookmark_border_outlined,
                            size: 64,
                            color: AppTheme.violetLight.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            filterState.searchQuery.isNotEmpty
                                ? 'No results found'
                                : filterState.status != null
                                    ? 'No anime in "${filterState.status!.displayName}"'
                                    : 'Your Watchlist is Empty',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            filterState.searchQuery.isNotEmpty
                                ? 'Try searching for a different anime title.'
                                : 'Explore trending and popular titles and tap "Add to Watchlist" to track your progress offline.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () => context.go('/explore'),
                            icon: const Icon(Icons.explore_outlined),
                            label: const Text('Explore Anime'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(watchlistNotifierProvider);
                    ref.invalidate(watchlistCountsProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return WatchlistCard(
                        key: ValueKey('watchlist_${item.animeId}'),
                        item: item,
                        onEdit: () {
                          WatchlistEditSheet.show(
                            context,
                            animeId: item.animeId,
                            title: item.title,
                            coverUrl: item.coverUrl,
                            format: item.format,
                            totalEpisodes: item.totalEpisodes,
                            existingItem: item,
                          );
                        },
                        onDelete: () => _confirmDelete(item),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
