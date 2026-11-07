// Airing broadcast schedule screen with weekly navigation and local timezone handling

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../notifications/notification_service.dart';
import '../../settings/presentation/providers/settings_provider.dart';
import 'providers/schedule_providers.dart';
import 'widgets/schedule_card.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  void initState() {
    super.initState();
    // Weekday is 1 (Mon) to 7 (Sun); map to index 0..6
    final initialIndex = (DateTime.now().weekday - 1).clamp(0, 6);
    _tabController = TabController(
      length: _weekdays.length,
      vsync: this,
      initialIndex: initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final watchlistOnly = ref.watch(scheduleWatchlistOnlyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Broadcast Schedule',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          Tooltip(
            message: watchlistOnly ? 'Show all airing anime' : 'Filter by my watchlist',
            child: FilterChip(
              avatar: Icon(
                watchlistOnly ? Icons.bookmark : Icons.bookmark_border,
                size: 16,
                color: watchlistOnly ? AppTheme.violetLight : null,
              ),
              label: const Text('Watchlist', style: TextStyle(fontSize: 12)),
              selected: watchlistOnly,
              onSelected: (val) {
                ref.read(scheduleWatchlistOnlyProvider.notifier).setFilter(val);
              },
              selectedColor: AppTheme.violet.withValues(alpha: 0.25),
              checkmarkColor: AppTheme.violetLight,
              backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
              side: BorderSide(
                color: watchlistOnly
                    ? AppTheme.violetLight
                    : (isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB)),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppTheme.violetLight,
          labelColor: isDark ? Colors.white : AppTheme.violetDark,
          unselectedLabelColor:
              isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
          tabs: _weekdays.map((day) => Tab(text: day)).toList(),
        ),
      ),
      body: Column(
        children: [
          // Original Broadcast Time Disclaimer (Master prompt legal requirement)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: isDark ? AppTheme.darkSurfaceVariant : AppTheme.lightSurfaceVariant,
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: AppTheme.violetLight),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Original broadcast times converted to your local time zone. Does not imply regional streaming availability.',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab views per weekday
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(7, (index) {
                final weekdayNumber = index + 1; // 1 = Monday .. 7 = Sunday
                return _WeekdayScheduleList(weekday: weekdayNumber);
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekdayScheduleList extends ConsumerWidget {
  final int weekday;

  const _WeekdayScheduleList({required this.weekday});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(dailyScheduleProvider(weekday));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final watchlistOnly = ref.watch(scheduleWatchlistOnlyProvider);

    return scheduleAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 52, color: AppTheme.violetLight),
              const SizedBox(height: 12),
              const Text(
                'Failed to load airing schedule',
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
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.refresh(weeklyScheduleProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
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
                    Icons.calendar_today_outlined,
                    size: 60,
                    color: AppTheme.violetLight.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    watchlistOnly
                        ? 'No Watchlist Anime Airing Today'
                        : 'No Broadcasts Scheduled',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    watchlistOnly
                        ? 'None of your saved anime have episodes airing on this weekday.'
                        : 'There are no Japanese broadcast television releases recorded for this day.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.darkOnSurfaceMuted
                          : AppTheme.lightOnSurfaceMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final settings = ref.watch(settingsProvider);

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(weeklyScheduleProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final schedule = items[index];
              final isReminderSet =
                  settings.showReminders.contains(schedule.mediaId);

              return ScheduleCard(
                schedule: schedule,
                isReminderSet: isReminderSet,
                onToggleReminder: () async {
                  final granted =
                      await NotificationService.instance.requestPermission();
                  if (granted || isReminderSet) {
                    await ref
                        .read(settingsProvider.notifier)
                        .toggleShowReminder(schedule.mediaId);
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}
