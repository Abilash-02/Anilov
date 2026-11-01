import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../anime/domain/models/anime_media.dart';

class FeaturedCarousel extends StatefulWidget {
  final List<AnimeMedia> items;

  const FeaturedCarousel({
    super.key,
    required this.items,
  });

  @override
  State<FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<FeaturedCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.items.length,
            onPageChanged: (idx) {
              setState(() {
                _currentIndex = idx;
              });
            },
            itemBuilder: (context, index) {
              final anime = widget.items[index];
              final imageUrl = anime.bannerImage ?? anime.coverImage.displayUrl;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Semantics(
                  button: true,
                  label: 'Featured Anime ${anime.title.displayTitle}',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.push('/anime/${anime.id}'),
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                          color: AppTheme.darkSurface,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Backdrop Image
                            if (imageUrl != null && imageUrl.isNotEmpty)
                              CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: AppTheme.darkSurfaceVariant,
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: AppTheme.deepIndigo,
                                ),
                              )
                            else
                              Container(
                                color: AppTheme.deepIndigo,
                              ),

                            // Gradient Overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.4),
                                    Colors.black.withValues(alpha: 0.92),
                                  ],
                                  stops: const [0.2, 0.6, 1.0],
                                ),
                              ),
                            ),

                            // Content Details
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppTheme.violet,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'TRENDING #1',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      if (anime.averageScore != null) ...[
                                        const SizedBox(width: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.star_rounded,
                                                size: 14, color: Colors.amber),
                                            const SizedBox(width: 2),
                                            Text(
                                              '${anime.averageScore}%',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    anime.title.displayTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    anime.genres.take(3).join(' • '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Carousel Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.items.length, (index) {
            final isActive = index == _currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3.0),
              width: isActive ? 20.0 : 6.0,
              height: 6.0,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.violetLight : const Color(0xFF4B5563),
                borderRadius: BorderRadius.circular(3.0),
              ),
            );
          }),
        ),
      ],
    );
  }
}
