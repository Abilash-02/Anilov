import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../anime/domain/models/anime_media.dart';
import '../../anime/domain/models/playback_provider.dart';
import '../../anime/presentation/providers/anikoto_providers.dart';
import '../../anime/presentation/providers/anime_providers.dart';
import '../../watchlist/presentation/providers/watchlist_providers.dart';

/// Dedicated landscape-capable in-app player screen for episode playback,
/// episode navigation, season selection, and source embedding verification.
class EpisodePlayerScreen extends ConsumerStatefulWidget {
  final int animeId;
  final int initialEpisodeNumber;
  final int initialSeasonIndex;

  const EpisodePlayerScreen({
    super.key,
    required this.animeId,
    this.initialEpisodeNumber = 1,
    this.initialSeasonIndex = 0,
  });

  @override
  ConsumerState<EpisodePlayerScreen> createState() =>
      _EpisodePlayerScreenState();
}

class _EpisodePlayerScreenState extends ConsumerState<EpisodePlayerScreen> {
  late int _currentEpisode;
  late int _currentSeasonIndex;
  bool _isLandscape = false;

  @override
  void initState() {
    super.initState();
    _currentEpisode = widget.initialEpisodeNumber;
    _currentSeasonIndex = widget.initialSeasonIndex;
  }

  @override
  void dispose() {
    // Reset orientation preferences when leaving player screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _toggleLandscape() {
    setState(() {
      _isLandscape = !_isLandscape;
    });

    if (_isLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  Future<void> _openOfficialEpisodeUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open $url in external browser.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to launch URL: $e')),
          );
        }
      }
    }
  }

  void _markAsWatched(AnimeMedia anime, int episodeNumber) {
    ref.read(watchlistNotifierProvider.notifier).updateProgress(
          anime.id,
          episodeNumber,
          title: anime.title.displayTitle,
          coverUrl: anime.coverImage.displayUrl,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Marked Episode $episodeNumber as watched!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(animeDetailsProvider(widget.animeId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: SafeArea(
        child: detailsAsync.when(
          loading: () => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Loading anime details...'),
              ],
            ),
          ),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 48, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load anime for playback',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    err.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () =>
                        ref.refresh(animeDetailsProvider(widget.animeId)),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          ),
          data: (anime) {
            final anikotoAsync = ref.watch(anikotoShowProvider(anime));

            return anikotoAsync.when(
              loading: () => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Connecting to AniKoto source...'),
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
                          size: 48, color: Colors.amber),
                      const SizedBox(height: 12),
                      const Text(
                        'Failed to resolve AniKoto source',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        err.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () =>
                            ref.refresh(anikotoShowProvider(anime)),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry AniKoto Source'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (showDetails) => _buildPlayerLayout(
                context,
                anime,
                showDetails,
                isDark,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlayerLayout(
    BuildContext context,
    AnimeMedia anime,
    AnikotoShowDetails showDetails,
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

    final currentSeason = seasons[_currentSeasonIndex.clamp(0, seasons.length - 1)];
    final totalEpisodes = currentSeason.episodesCount ?? showDetails.totalEpisodes;
    final clampedEp = _currentEpisode.clamp(1, totalEpisodes > 0 ? totalEpisodes : 1);
    final officialEpisodeUrl =
        showDetails.buildEpisodeUrl(clampedEp, seasonSlug: currentSeason.slug);
    final evaluation =
        AnikotoPlaybackEvaluation.evaluate(officialEpisodeUrl);

    final watchlistItem =
        ref.watch(watchlistItemProvider(anime.id)).asData?.value;
    final isWatched = (watchlistItem?.progress ?? 0) >= clampedEp;

    return OrientationBuilder(
      builder: (context, orientation) {
        final isScreenLandscape = orientation == Orientation.landscape;

        if (isScreenLandscape) {
          // Fullscreen / Landscape layout
          return Stack(
            fit: StackFit.expand,
            children: [
              _buildPlayerSurface(
                context,
                anime,
                currentSeason,
                clampedEp,
                officialEpisodeUrl,
                evaluation,
                isDark,
                isLandscape: true,
              ),
              // Top control bar
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Row(
                  children: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      ),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/anime/${anime.id}');
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${anime.title.displayTitle} — ${currentSeason.name}: Ep $clampedEp',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          shadows: [
                            Shadow(color: Colors.black87, blurRadius: 4),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.crop_portrait_rounded,
                            color: Colors.white, size: 20),
                      ),
                      tooltip: 'Switch to Portrait',
                      onPressed: _toggleLandscape,
                    ),
                  ],
                ),
              ),
              // Bottom episode navigation bar
              Positioned(
                bottom: 8,
                left: 16,
                right: 16,
                child: _buildNavigationControls(
                  anime,
                  seasons,
                  currentSeason,
                  clampedEp,
                  totalEpisodes,
                  isWatched,
                  isDark,
                  isLandscape: true,
                ),
              ),
            ],
          );
        }

        // Portrait layout
        return Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/anime/${anime.id}');
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          anime.title.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${currentSeason.name} • Episode $clampedEp of $totalEpisodes',
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
                    icon: const Icon(Icons.crop_landscape_rounded),
                    tooltip: 'Switch to Landscape Player',
                    onPressed: _toggleLandscape,
                  ),
                ],
              ),
            ),

            // Video Player Surface
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildPlayerSurface(
                context,
                anime,
                currentSeason,
                clampedEp,
                officialEpisodeUrl,
                evaluation,
                isDark,
                isLandscape: false,
              ),
            ),

            // Episode Navigation Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _buildNavigationControls(
                anime,
                seasons,
                currentSeason,
                clampedEp,
                totalEpisodes,
                isWatched,
                isDark,
                isLandscape: false,
              ),
            ),

            const Divider(height: 1),

            // Seasons & Episode Selector Drawer in portrait
            Expanded(
              child: _buildEpisodeSelectorList(
                anime,
                seasons,
                currentSeason,
                clampedEp,
                totalEpisodes,
                isDark,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlayerSurface(
    BuildContext context,
    AnimeMedia anime,
    AnikotoSeason currentSeason,
    int episodeNumber,
    String officialUrl,
    AnikotoPlaybackEvaluation evaluation,
    bool isDark, {
    required bool isLandscape,
  }) {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.all(isLandscape ? 24.0 : 16.0),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.violet.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.open_in_browser_rounded,
                  color: AppTheme.violetLight,
                  size: 32,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Official Episode $episodeNumber on AniKoto',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Text(
                  'AniKoto (anikoto.cz) enforces "X-Frame-Options: SAMEORIGIN" and does not offer an authorized third-party embed API. '
                  'In compliance with safety policies, hidden streams are not scraped or bypassed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: isLandscape ? 11 : 12,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.violet,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    icon: const Icon(Icons.launch_rounded, size: 18),
                    label: Text('Watch Episode $episodeNumber on AniKoto'),
                    onPressed: () => _openOfficialEpisodeUrl(officialUrl),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                    ),
                    icon: const Icon(Icons.video_library_outlined, size: 16),
                    label: const Text('Open Local Player'),
                    onPressed: () => context.push('/player'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationControls(
    AnimeMedia anime,
    List<AnikotoSeason> seasons,
    AnikotoSeason currentSeason,
    int episodeNumber,
    int totalEpisodes,
    bool isWatched,
    bool isDark, {
    required bool isLandscape,
  }) {
    final hasPrev = episodeNumber > 1;
    final hasNext = episodeNumber < totalEpisodes;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isLandscape
            ? Colors.black87
            : (isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLandscape
              ? Colors.white24
              : (isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Episode Button
          IconButton.filledTonal(
            tooltip: 'Previous Episode',
            icon: const Icon(Icons.skip_previous_rounded),
            onPressed: hasPrev
                ? () {
                    setState(() {
                      _currentEpisode = episodeNumber - 1;
                    });
                  }
                : null,
          ),

          // Center Episode Indicator & Quick Switcher
          InkWell(
            onTap: () => _showEpisodeSelectionModal(
              context,
              anime,
              seasons,
              currentSeason,
              episodeNumber,
              totalEpisodes,
              isDark,
            ),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.list_alt_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Ep $episodeNumber / $totalEpisodes',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down_rounded, size: 20),
                ],
              ),
            ),
          ),

          // Mark Watched Action
          IconButton(
            tooltip: isWatched ? 'Watched' : 'Mark as Watched',
            icon: Icon(
              isWatched ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
              color: isWatched ? Colors.green : (isDark ? Colors.white60 : Colors.black54),
            ),
            onPressed: () => _markAsWatched(anime, episodeNumber),
          ),

          // Next Episode Button
          IconButton.filledTonal(
            tooltip: 'Next Episode',
            icon: const Icon(Icons.skip_next_rounded),
            onPressed: hasNext
                ? () {
                    setState(() {
                      _currentEpisode = episodeNumber + 1;
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeSelectorList(
    AnimeMedia anime,
    List<AnikotoSeason> seasons,
    AnikotoSeason currentSeason,
    int currentEpisode,
    int totalEpisodes,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Season selector tabs
        if (seasons.length > 1) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Text(
              'Seasons',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
              ),
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: seasons.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final s = seasons[idx];
                final isSelected = idx == _currentSeasonIndex;
                return ChoiceChip(
                  label: Text(s.name),
                  selected: isSelected,
                  selectedColor: AppTheme.violet,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _currentSeasonIndex = idx;
                        _currentEpisode = 1;
                      });
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 6),
        ],

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            'Episodes in ${currentSeason.name}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),

        // Episode List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            itemCount: totalEpisodes,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final epNum = index + 1;
              final isCurrent = epNum == currentEpisode;

              return ListTile(
                dense: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isCurrent
                        ? AppTheme.violetLight
                        : (isDark
                            ? const Color(0xFF2E2E38)
                            : const Color(0xFFE5E7EB)),
                  ),
                ),
                tileColor: isCurrent
                    ? AppTheme.violet.withValues(alpha: 0.15)
                    : (isDark
                        ? AppTheme.darkSurface
                        : AppTheme.lightSurfaceVariant),
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: isCurrent
                      ? AppTheme.violet
                      : (isDark ? AppTheme.darkSurfaceVariant : Colors.black12),
                  child: Text(
                    '$epNum',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isCurrent ? Colors.white : null,
                    ),
                  ),
                ),
                title: Text(
                  'Episode $epNum',
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                    color: isCurrent ? AppTheme.violetLight : null,
                  ),
                ),
                trailing: isCurrent
                    ? const Icon(Icons.play_arrow_rounded, color: AppTheme.violetLight)
                    : null,
                onTap: () {
                  setState(() {
                    _currentEpisode = epNum;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showEpisodeSelectionModal(
    BuildContext context,
    AnimeMedia anime,
    List<AnikotoSeason> seasons,
    AnikotoSeason currentSeason,
    int currentEpisode,
    int totalEpisodes,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          builder: (_, scrollCtrl) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Select Episode (${currentSeason.name})',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: totalEpisodes,
                    itemBuilder: (context, idx) {
                      final epNum = idx + 1;
                      final isCurrent = epNum == currentEpisode;

                      return InkWell(
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          setState(() {
                            _currentEpisode = epNum;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppTheme.violet
                                : (isDark
                                    ? AppTheme.darkSurface
                                    : AppTheme.lightSurfaceVariant),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isCurrent
                                  ? AppTheme.violetLight
                                  : (isDark
                                      ? const Color(0xFF2E2E38)
                                      : const Color(0xFFE5E7EB)),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$epNum',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isCurrent ? Colors.white : null,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
