import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../anime/presentation/providers/anime_providers.dart';
import '../../anime/presentation/widgets/anime_card.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const List<String> _genres = [
    'All Genres',
    'Action',
    'Adventure',
    'Comedy',
    'Drama',
    'Fantasy',
    'Horror',
    'Mecha',
    'Mystery',
    'Psychological',
    'Romance',
    'Sci-Fi',
    'Slice of Life',
    'Sports',
    'Supernatural',
    'Thriller',
  ];

  static const List<Map<String, String>> _formats = [
    {'label': 'All Formats', 'value': 'ALL'},
    {'label': 'TV Series', 'value': 'TV'},
    {'label': 'Movie', 'value': 'MOVIE'},
    {'label': 'TV Short', 'value': 'TV_SHORT'},
    {'label': 'OVA', 'value': 'OVA'},
    {'label': 'ONA', 'value': 'ONA'},
    {'label': 'Special', 'value': 'SPECIAL'},
  ];

  static const List<Map<String, String>> _statuses = [
    {'label': 'All Statuses', 'value': 'ALL'},
    {'label': 'Releasing', 'value': 'RELEASING'},
    {'label': 'Finished', 'value': 'FINISHED'},
    {'label': 'Upcoming', 'value': 'NOT_YET_RELEASED'},
  ];

  static const List<Map<String, String>> _sortOptions = [
    {'label': 'Trending', 'value': 'TRENDING_DESC'},
    {'label': 'Most Popular', 'value': 'POPULARITY_DESC'},
    {'label': 'Top Rated', 'value': 'SCORE_DESC'},
    {'label': 'Newest First', 'value': 'START_DATE_DESC'},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(exploreStateProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exploreStateProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Explore',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort By',
            onPressed: () => _showSortBottomSheet(context, state.sort),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                ref.read(exploreStateProvider.notifier).onQueryChanged(val);
              },
              decoration: InputDecoration(
                hintText: 'Search anime titles, genres, studios...',
                hintStyle: TextStyle(
                  color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(exploreStateProvider.notifier).onQueryChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                  borderSide: const BorderSide(color: AppTheme.violet, width: 1.5),
                ),
              ),
            ),
          ),

          // Search History Chips (when query is empty and history exists)
          if (_searchController.text.isEmpty && state.searchHistory.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  const Icon(Icons.history, size: 16, color: AppTheme.violetLight),
                  const SizedBox(width: 6),
                  Text(
                    'Recent:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: state.searchHistory.map((query) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: ActionChip(
                              label: Text(query, style: const TextStyle(fontSize: 11)),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                _searchController.text = query;
                                ref.read(exploreStateProvider.notifier).onQueryChanged(query);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    tooltip: 'Clear History',
                    onPressed: () {
                      ref.read(exploreStateProvider.notifier).clearSearchHistory();
                    },
                  ),
                ],
              ),
            ),

          // Filters Bar: Format, Status & Genre Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: Row(
              children: [
                // Format filter chips
                ..._formats.map((f) {
                  final val = f['value']!;
                  final isSelected = (state.format == null && val == 'ALL') || state.format == val;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: FilterChip(
                      label: Text(f['label']!),
                      selected: isSelected,
                      onSelected: (_) {
                        ref.read(exploreStateProvider.notifier).onFormatSelected(val);
                      },
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
                }),
                // Status filter chips
                ..._statuses.map((s) {
                  final val = s['value']!;
                  final isSelected = (state.status == null && val == 'ALL') || state.status == val;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: FilterChip(
                      label: Text(s['label']!),
                      selected: isSelected,
                      onSelected: (_) {
                        ref.read(exploreStateProvider.notifier).onStatusSelected(val);
                      },
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
                }),
                // Genre filter chips
                ..._genres.map((g) {
                  final isSelected = (state.genre == null && g == 'All Genres') || state.genre == g;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: FilterChip(
                      label: Text(g),
                      selected: isSelected,
                      onSelected: (_) {
                        ref.read(exploreStateProvider.notifier).onGenreSelected(g);
                      },
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
                }),
              ],
            ),
          ),
          const Divider(height: 1),

          // Grid Results / Empty / Error State
          Expanded(
            child: _buildBody(state, isDark, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ExploreState state, bool isDark, ThemeData theme) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 56, color: AppTheme.violetLight),
              const SizedBox(height: 16),
              Text(
                'Failed to load search results',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.read(exploreStateProvider.notifier).search(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 64,
                color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
              ),
              const SizedBox(height: 16),
              Text(
                'No anime found',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search query, genre, or format filters.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : (constraints.maxWidth > 400 ? 3 : 2);
        final cardWidth = (constraints.maxWidth - (16 * 2) - ((crossAxisCount - 1) * 12)) / crossAxisCount;
        final cardHeight = cardWidth * 1.55;

        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12.0,
                  crossAxisSpacing: 12.0,
                  childAspectRatio: cardWidth / cardHeight,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return AnimeCard(
                      anime: state.items[index],
                      width: cardWidth,
                      height: cardHeight,
                    );
                  },
                  childCount: state.items.length,
                ),
              ),
            ),
            if (state.isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showSortBottomSheet(BuildContext context, String currentSort) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Text(
                    'Sort Anime By',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                ..._sortOptions.map((opt) {
                  final isSelected = opt['value'] == currentSort;
                  return ListTile(
                    title: Text(opt['label']!),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppTheme.violetLight)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(exploreStateProvider.notifier).onSortSelected(opt['value']!);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
