import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/anime_providers.dart';

class AnimeDetailsScreen extends ConsumerStatefulWidget {
  final int id;

  const AnimeDetailsScreen({
    super.key,
    required this.id,
  });

  @override
  ConsumerState<AnimeDetailsScreen> createState() => _AnimeDetailsScreenState();
}

class _AnimeDetailsScreenState extends ConsumerState<AnimeDetailsScreen> {
  bool _isSynopsisExpanded = false;

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(animeDetailsProvider(widget.id));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: detailsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, stack) => Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 56, color: AppTheme.violetLight),
                const SizedBox(height: 16),
                Text(
                  'Failed to load anime details',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
                  onPressed: () => ref.refresh(animeDetailsProvider(widget.id)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (anime) => CustomScrollView(
          slivers: [
            // App Bar with Banner
            SliverAppBar(
              expandedHeight: 220.0,
              pinned: true,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (anime.bannerImage != null && anime.bannerImage!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: anime.bannerImage!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(color: AppTheme.deepIndigo),
                      )
                    else if (anime.coverImage.displayUrl != null)
                      CachedNetworkImage(
                        imageUrl: anime.coverImage.displayUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(color: AppTheme.deepIndigo),
                      )
                    else
                      Container(color: AppTheme.deepIndigo),

                    // Gradient Scrim
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.4),
                            isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Main Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row: Poster + Title + Rating
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Poster Card
                        Container(
                          width: 110,
                          height: 160,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB),
                              width: 1.5,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: anime.coverImage.displayUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: anime.coverImage.displayUrl!,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                                )
                              : const Icon(Icons.movie),
                        ),
                        const SizedBox(width: 14),

                        // Title, Studio, Scores
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                anime.title.displayTitle,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  height: 1.25,
                                ),
                              ),
                              if (anime.title.romaji != null &&
                                  anime.title.romaji != anime.title.displayTitle) ...[
                                const SizedBox(height: 3),
                                Text(
                                  anime.title.romaji!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),

                              // Score & Format Badges
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  if (anime.averageScore != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppTheme.violet.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppTheme.violetLight.withValues(alpha: 0.4)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${anime.averageScore}%',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            '(AniList)',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppTheme.darkSurfaceVariant : AppTheme.lightSurfaceVariant,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      anime.displayFormat,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                                    ),
                                  ),
                                  if (anime.status != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppTheme.darkSurfaceVariant : AppTheme.lightSurfaceVariant,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        anime.status!,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                                      ),
                                    ),
                                ],
                              ),
                              if (anime.studio != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.business_outlined, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      anime.studio!,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Watchlist button stub (persistence activates in RUN 3)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Watchlist & offline persistence will activate in RUN 3.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.bookmark_add_outlined),
                        label: const Text('Add to Watchlist'),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick Stats Bar
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Episodes', anime.episodes != null ? '${anime.episodes}' : '?'),
                          _buildStatDivider(isDark),
                          _buildStatItem('Duration', anime.duration != null ? '${anime.duration}m' : '?'),
                          _buildStatDivider(isDark),
                          _buildStatItem('Year', anime.seasonYear != null ? '${anime.seasonYear}' : '?'),
                          _buildStatDivider(isDark),
                          _buildStatItem('Popularity', anime.popularity != null ? '#${anime.popularity}' : '-'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Genres
                    if (anime.genres.isNotEmpty) ...[
                      Text(
                        'Genres',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: anime.genres.map((genre) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Text(
                              genre,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Synopsis
                    Text(
                      'Synopsis',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      anime.cleanDescription,
                      maxLines: _isSynopsisExpanded ? null : 4,
                      overflow: _isSynopsisExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: isDark ? AppTheme.darkOnSurface : AppTheme.lightOnSurface,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isSynopsisExpanded = !_isSynopsisExpanded;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          _isSynopsisExpanded ? 'Show less' : 'Read more',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.violetLight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Official Trailer (Section 4 Legal Boundaries)
                    if (anime.trailer != null && anime.trailer!.isYouTube) ...[
                      Text(
                        'Official Trailer',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 170,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppTheme.darkSurface,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (anime.trailer!.thumbnailUrl != null)
                              CachedNetworkImage(
                                imageUrl: anime.trailer!.thumbnailUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(color: Colors.black54),
                              ),
                            Container(
                              color: Colors.black.withValues(alpha: 0.4),
                            ),
                            Center(
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              left: 12,
                              child: Text(
                                'YouTube Official Embed (Run 4)',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Official Where to Watch Links (AniList returned data only)
                    Text(
                      'Where to Watch',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Official streaming providers supplied by AniList data.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (anime.externalLinks.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14.0),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Text(
                          'No official streaming links listed by AniList for this title.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: anime.externalLinks.map((link) {
                          return OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Official provider: ${link.site} (${link.url})'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: Text(link.site),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(48, 40),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 24),

                    // Related Anime
                    if (anime.relations.isNotEmpty) ...[
                      Text(
                        'Related Anime',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 170,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: anime.relations.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final rel = anime.relations[index];
                            return InkWell(
                              onTap: () => context.push('/anime/${rel.id}'),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 110,
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB),
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: rel.coverUrl != null
                                          ? CachedNetworkImage(
                                              imageUrl: rel.coverUrl!,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              errorWidget: (_, __, ___) => const Icon(Icons.movie),
                                            )
                                          : const Icon(Icons.movie),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            rel.relationType,
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.violetLight,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            rel.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildStatDivider(bool isDark) {
    return Container(
      width: 1,
      height: 24,
      color: isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB),
    );
  }
}
