import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../anime/presentation/providers/anime_providers.dart';
import '../../common/widgets/anilov_logo.dart';
import 'widgets/anime_horizontal_section.dart';
import 'widgets/featured_carousel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(homeDataProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final genres = [
      'Action',
      'Adventure',
      'Comedy',
      'Fantasy',
      'Romance',
      'Sci-Fi',
      'Drama',
      'Supernatural',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const AnilovLogo(size: 32, fontSize: 20),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Anime',
            onPressed: () => context.go('/explore'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(homeDataProvider.future),
        child: homeAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            children: const [
              AnimeHorizontalSection(title: 'Featured', isLoading: true),
              SizedBox(height: 20),
              AnimeHorizontalSection(title: 'Airing Today', isLoading: true),
              SizedBox(height: 20),
              AnimeHorizontalSection(title: 'Trending Now', isLoading: true),
            ],
          ),
          error: (err, stack) => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 56,
                    color: AppTheme.violetLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Unable to load anime catalog',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    err.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => ref.refresh(homeDataProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (data) => ListView(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            children: [
              // Search Bar Entry Point
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Semantics(
                  button: true,
                  label: 'Search anime titles, genres, studios',
                  child: InkWell(
                    onTap: () => context.go('/explore'),
                    borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                    child: Container(
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
                          Expanded(
                            child: Text(
                              'Search anime titles, genres, studios...',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Genre shortcuts
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: genres.map((g) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        label: Text(g),
                        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
                        side: BorderSide(
                          color: isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB),
                        ),
                        onPressed: () {
                          ref.read(exploreStateProvider.notifier).onGenreSelected(g);
                          context.go('/explore');
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Featured Carousel
              if (data.featured.isNotEmpty) ...[
                FeaturedCarousel(items: data.featured),
                const SizedBox(height: 24),
              ],

              // Airing Today
              if (data.airingToday.isNotEmpty) ...[
                AnimeHorizontalSection(
                  title: 'Airing Today',
                  items: data.airingToday,
                  onSeeAll: () {
                    ref.read(exploreStateProvider.notifier).onStatusSelected('RELEASING');
                    context.go('/explore');
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Trending Now
              if (data.trending.isNotEmpty) ...[
                AnimeHorizontalSection(
                  title: 'Trending Now',
                  items: data.trending,
                  onSeeAll: () {
                    ref.read(exploreStateProvider.notifier).onSortSelected('TRENDING_DESC');
                    context.go('/explore');
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Popular Anime
              if (data.popular.isNotEmpty) ...[
                AnimeHorizontalSection(
                  title: 'All-Time Popular',
                  items: data.popular,
                  onSeeAll: () {
                    ref.read(exploreStateProvider.notifier).onSortSelected('POPULARITY_DESC');
                    context.go('/explore');
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Top Rated
              if (data.topRated.isNotEmpty) ...[
                AnimeHorizontalSection(
                  title: 'Top Rated',
                  items: data.topRated,
                  onSeeAll: () {
                    ref.read(exploreStateProvider.notifier).onSortSelected('SCORE_DESC');
                    context.go('/explore');
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Currently Airing
              if (data.currentlyAiring.isNotEmpty) ...[
                AnimeHorizontalSection(
                  title: 'Currently Airing',
                  items: data.currentlyAiring,
                  onSeeAll: () {
                    ref.read(exploreStateProvider.notifier).onStatusSelected('RELEASING');
                    context.go('/explore');
                  },
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
