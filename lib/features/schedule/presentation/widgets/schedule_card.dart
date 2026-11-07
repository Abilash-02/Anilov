// Airing schedule item card widget

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/airing_schedule.dart';

class ScheduleCard extends StatelessWidget {
  final AiringSchedule schedule;
  final bool isReminderSet;
  final VoidCallback? onToggleReminder;

  const ScheduleCard({
    super.key,
    required this.schedule,
    this.isReminderSet = false,
    this.onToggleReminder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final media = schedule.media;
    final title = media?.title.displayTitle ?? 'Anime #${schedule.mediaId}';

    return InkWell(
      onTap: () => context.push('/anime/${schedule.mediaId}'),
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
              width: 72,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isDark
                    ? AppTheme.darkSurfaceVariant
                    : AppTheme.lightSurfaceVariant,
              ),
              clipBehavior: Clip.antiAlias,
              child: media?.coverImage.displayUrl != null
                  ? CachedNetworkImage(
                      imageUrl: media!.coverImage.displayUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.broken_image, size: 28),
                    )
                  : const Icon(Icons.movie, size: 28),
            ),
            const SizedBox(width: 12),

            // Schedule info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Airing Time and Countdown Badge + Reminder Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.violet.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppTheme.violetLight.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time_rounded,
                                size: 13, color: AppTheme.violetLight),
                            const SizedBox(width: 4),
                            Text(
                              schedule.formattedTime,
                              style: const TextStyle(
                                color: AppTheme.violetLight,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            schedule.countdownText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: schedule.hasAired
                                  ? (isDark
                                      ? AppTheme.darkOnSurfaceMuted
                                      : AppTheme.lightOnSurfaceMuted)
                                  : Colors.amber,
                            ),
                          ),
                          if (onToggleReminder != null) ...[
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: onToggleReminder,
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Icon(
                                  isReminderSet
                                      ? Icons.notifications_active_rounded
                                      : Icons.notifications_none_rounded,
                                  size: 18,
                                  color: isReminderSet
                                      ? AppTheme.violetLight
                                      : (isDark
                                          ? AppTheme.darkOnSurfaceMuted
                                          : AppTheme.lightOnSurfaceMuted),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Episode Badge and Media Format
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.darkSurfaceVariant
                              : AppTheme.lightSurfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Episode ${schedule.episode}',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (media?.displayFormat != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          media!.displayFormat,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppTheme.darkOnSurfaceMuted
                                : AppTheme.lightOnSurfaceMuted,
                          ),
                        ),
                      ],
                      if (media?.averageScore != null) ...[
                        const Spacer(),
                        const Icon(Icons.star_rounded,
                            size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          '${media!.averageScore}%',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
