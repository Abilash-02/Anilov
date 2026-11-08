import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../watchlist/presentation/providers/watchlist_providers.dart';
import '../../domain/models/anime_media.dart';
import '../../domain/models/playback_provider.dart';
import '../providers/anikoto_providers.dart';

/// Modal bottom sheet allowing users to browse seasons, select episodes,
/// switch playback providers, and launch the dedicated episode player.
class WatchNowSheet extends ConsumerStatefulWidget {
  final AnimeMedia anime;

  const WatchNowSheet({
    super.key,
    required this.anime,
  });

  static Future<void> show(
    BuildContext context, {
    required AnimeMedia anime,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WatchNowSheet(anime: anime),
    );
  }

  @override
  ConsumerState<WatchNowSheet> createState() => _WatchNowSheetState();
}

class _WatchNowSheetState extends ConsumerState<WatchNowSheet> {
  int _selectedSeasonIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentProvider = ref.watch(selectedPlaybackProvider);
    final anikotoShowAsync = ref.watch(anikotoShowProvider(widget.anime));
    final watchlistItem =
        ref.watch(watchlistItemProvider(widget.anime.id)).asData?.value;
    final watchedProgress = watchlistItem?.progress ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Watch Now',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.anime.title.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppTheme.darkOnSurfaceMuted
                              : AppTheme.lightOnSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Playback Provider Selection
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color:
                    isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2E2E38)
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildProviderTab(
                      label: 'AniKoto Source',
                      icon: Icons.language_rounded,
                      isSelected: currentProvider == PlaybackProviderType.anikoto,
                      onTap: () {
                        ref
                            .read(selectedPlaybackProvider.notifier)
                            .setProvider(PlaybackProviderType.anikoto);
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(width: 4),
                    _buildProviderTab(
                      label: 'Authorized Stream',
                      icon: Icons.play_circle_fill_rounded,
                      isSelected:
                          currentProvider == PlaybackProviderType.authorizedStream,
                      onTap: () {
                        ref
                            .read(selectedPlaybackProvider.notifier)
                            .setProvider(PlaybackProviderType.authorizedStream);
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(width: 4),
                    _buildProviderTab(
                      label: 'Fetch (Kickass)',
                      icon: Icons.shield_outlined,
                      isSelected:
                          currentProvider == PlaybackProviderType.fetchKickass,
                      onTap: () {
                        ref
                            .read(selectedPlaybackProvider.notifier)
                            .setProvider(PlaybackProviderType.fetchKickass);
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(width: 4),
                    _buildProviderTab(
                      label: 'Local Player',
                      icon: Icons.video_library_outlined,
                      isSelected:
                          currentProvider == PlaybackProviderType.localPlayer,
                      onTap: () {
                        ref
                            .read(selectedPlaybackProvider.notifier)
                            .setProvider(PlaybackProviderType.localPlayer);
                      },
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Content body based on Provider
          if (currentProvider == PlaybackProviderType.localPlayer)
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: _buildLocalPlayerOption(context, isDark),
                ),
              ),
            )
          else if (currentProvider == PlaybackProviderType.fetchKickass)
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: _buildFetchContent(context, isDark),
                ),
              ),
            )
          else if (currentProvider == PlaybackProviderType.authorizedStream)
            Expanded(
              child: _buildAuthorizedContent(context, watchedProgress, isDark),
            )
          else
            Expanded(
              child: anikotoShowAsync.when(
                loading: () => const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Connecting to AniKoto source...',
                          style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded,
                            size: 40, color: Colors.amber),
                        const SizedBox(height: 8),
                        const Text(
                          'Could not connect to AniKoto',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          err.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => ref.refresh(
                              anikotoShowProvider(widget.anime)),
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (showDetails) => _buildAnikotoContent(
                  context,
                  showDetails,
                  watchedProgress,
                  isDark,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProviderTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.violet
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorizedContent(
    BuildContext context,
    int watchedProgress,
    bool isDark,
  ) {
    final totalEps = widget.anime.episodes ?? 12;
    final nextEp = (watchedProgress < totalEps) ? watchedProgress + 1 : 1;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Authorized HLS Episodes ($totalEps)',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push(
                    '/watch/${widget.anime.id}?ep=$nextEp&provider=authorized',
                  );
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(
                  watchedProgress > 0 ? 'Continue Ep $nextEp' : 'Play Ep 1',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.1,
            ),
            itemCount: totalEps,
            itemBuilder: (context, index) {
              final epNum = index + 1;
              final isWatched = epNum <= watchedProgress;
              final isNext = epNum == nextEp;

              return InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  context.push(
                    '/watch/${widget.anime.id}?ep=$epNum&provider=authorized',
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isNext
                        ? AppTheme.violet.withValues(alpha: 0.2)
                        : (isDark
                            ? AppTheme.darkSurface
                            : AppTheme.lightSurfaceVariant),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isNext
                          ? AppTheme.violetLight
                          : (isWatched
                              ? Colors.green.withValues(alpha: 0.5)
                              : (isDark
                                  ? const Color(0xFF2E2E38)
                                  : const Color(0xFFE5E7EB))),
                      width: isNext ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$epNum',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: isNext ? AppTheme.violetLight : null,
                        ),
                      ),
                      if (isWatched)
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: Colors.green,
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

  Widget _buildFetchContent(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield_outlined, size: 48, color: Colors.amber),
          const SizedBox(height: 12),
          const Text(
            'Fetch (KickassAnime) Source Limitation',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            'Fetch (github.com/snehilrx/Fetch) relied on a hidden headless WebView script injection into "player.php" '
            'to scrape pirate playlist streams and bypass Cloudflare protection without an authorized API.\n\n'
            'In strict compliance with Anilov security and legal guidelines, hidden scraping and DRM bypass are rejected. '
            'Please use the Authorized Anime Stream provider for full in-app playback.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () {
              ref
                  .read(selectedPlaybackProvider.notifier)
                  .setProvider(PlaybackProviderType.authorizedStream);
            },
            icon: const Icon(Icons.play_circle_fill_rounded),
            label: const Text('Switch to Authorized Stream'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalPlayerOption(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.folder_open_rounded, size: 48, color: AppTheme.violetLight),
          const SizedBox(height: 12),
          const Text(
            'Local Media & Direct Stream Player',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            'Play offline downloaded video files or authorized direct video streams.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/player');
            },
            icon: const Icon(Icons.play_circle_fill_rounded),
            label: const Text('Open Local Player'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnikotoContent(
    BuildContext context,
    AnikotoShowDetails showDetails,
    int watchedProgress,
    bool isDark,
  ) {
    final seasons = showDetails.seasons.isNotEmpty
        ? showDetails.seasons
        : [
            AnikotoSeason(
              seasonNumber: 1,
              name: 'Season 1',
              slug: showDetails.slug,
              episodesCount: showDetails.totalEpisodes,
            ),
          ];

    final currentSeasonIndex = _selectedSeasonIndex.clamp(0, seasons.length - 1);
    final currentSeason = seasons[currentSeasonIndex];
    final totalEps = currentSeason.episodesCount ?? showDetails.totalEpisodes;

    // Next episode to watch
    final nextEp = (watchedProgress < totalEps) ? watchedProgress + 1 : 1;

    return Column(
      children: [
        // Seasons Selector (if multiple seasons exist)
        if (seasons.length > 1) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Available Seasons',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: seasons.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final s = seasons[idx];
                final isSelected = idx == currentSeasonIndex;
                return ChoiceChip(
                  label: Text(s.name),
                  selected: isSelected,
                  selectedColor: AppTheme.violet,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedSeasonIndex = idx;
                      });
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Episodes Header & Quick Play Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Episodes ($totalEps)',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push(
                    '/watch/${widget.anime.id}?ep=$nextEp&season=$currentSeasonIndex',
                  );
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(
                  watchedProgress > 0 ? 'Continue Ep $nextEp' : 'Play Ep 1',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Episode Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.1,
            ),
            itemCount: totalEps,
            itemBuilder: (context, index) {
              final epNum = index + 1;
              final isWatched = epNum <= watchedProgress;
              final isNext = epNum == nextEp;

              return InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  context.push(
                    '/watch/${widget.anime.id}?ep=$epNum&season=$currentSeasonIndex',
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isNext
                        ? AppTheme.violet.withValues(alpha: 0.2)
                        : (isDark
                            ? AppTheme.darkSurface
                            : AppTheme.lightSurfaceVariant),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isNext
                          ? AppTheme.violetLight
                          : (isWatched
                              ? Colors.green.withValues(alpha: 0.5)
                              : (isDark
                                  ? const Color(0xFF2E2E38)
                                  : const Color(0xFFE5E7EB))),
                      width: isNext ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isWatched)
                            const Icon(Icons.check_circle_rounded,
                                size: 12, color: Colors.green)
                          else if (isNext)
                            const Icon(Icons.play_circle_fill_rounded,
                                size: 12, color: AppTheme.violetLight),
                          if (isWatched || isNext) const SizedBox(width: 3),
                          Text(
                            '$epNum',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: (isWatched || isNext)
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isNext
                                  ? AppTheme.violetLight
                                  : (isWatched ? Colors.green : null),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'EP',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppTheme.darkOnSurfaceMuted
                              : AppTheme.lightOnSurfaceMuted,
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
