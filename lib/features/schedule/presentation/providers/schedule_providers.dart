// Riverpod providers for airing schedule and weekly timetable

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anilov/features/anime/domain/models/episode_metadata.dart';
import 'package:anilov/features/anime/presentation/providers/anime_providers.dart';
import 'package:anilov/features/schedule/domain/models/airing_schedule.dart';
import 'package:anilov/features/watchlist/presentation/providers/watchlist_providers.dart';

// Controls whether only watchlist anime are displayed in the schedule
class ScheduleWatchlistFilterNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void setFilter(bool val) => state = val;
}

final scheduleWatchlistOnlyProvider =
    NotifierProvider<ScheduleWatchlistFilterNotifier, bool>(
  ScheduleWatchlistFilterNotifier.new,
);

// Loads the full airing schedule for the current 7-day week
final weeklyScheduleProvider =
    FutureProvider.autoDispose<List<AiringSchedule>>((ref) async {
  final repo = ref.watch(animeRepositoryProvider);

  final nowLocal = DateTime.now();
  // Find Monday 00:00:00 local time
  final daysFromMonday = nowLocal.weekday - 1;
  final mondayLocal = DateTime(
    nowLocal.year,
    nowLocal.month,
    nowLocal.day - daysFromMonday,
    0,
    0,
    0,
  );
  // Find Sunday 23:59:59 local time
  final sundayLocal = mondayLocal.add(const Duration(days: 7, seconds: -1));

  final startTimestamp = mondayLocal.toUtc().millisecondsSinceEpoch ~/ 1000;
  final endTimestamp = sundayLocal.toUtc().millisecondsSinceEpoch ~/ 1000;

  return repo.getAiringSchedules(
    startTimestamp: startTimestamp,
    endTimestamp: endTimestamp,
    perPage: 50,
  );
});

// Filters the weekly schedule for a specific weekday (1 = Mon .. 7 = Sun)
final dailyScheduleProvider =
    Provider.family.autoDispose<AsyncValue<List<AiringSchedule>>, int>((ref, weekday) {
  final weeklyAsync = ref.watch(weeklyScheduleProvider);
  final watchlistOnly = ref.watch(scheduleWatchlistOnlyProvider);
  final watchlistItemsAsync = ref.watch(watchlistNotifierProvider);

  return weeklyAsync.whenData((schedules) {
    var filtered = schedules.where((s) => s.weekday == weekday).toList();

    if (watchlistOnly) {
      final savedIds = (watchlistItemsAsync.asData?.value ?? [])
          .map((item) => item.animeId)
          .toSet();
      filtered = filtered.where((s) => savedIds.contains(s.mediaId)).toList();
    }

    // Sort by local airing time ascending
    filtered.sort((a, b) => a.airingAtLocal.compareTo(b.airingAtLocal));
    return filtered;
  });
});

// Provides optional enriched episode metadata from ani.zip
final episodeListProvider = FutureProvider.family
    .autoDispose<List<EpisodeMetadata>, ({int animeId, int? totalEpisodes})>(
  (ref, params) async {
    final repo = ref.watch(animeRepositoryProvider);
    return repo.getEpisodesMetadata(
      params.animeId,
      fallbackCount: params.totalEpisodes,
    );
  },
);
