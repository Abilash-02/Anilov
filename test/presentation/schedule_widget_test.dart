// Widget tests for ScheduleScreen and ScheduleCard

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anilov/core/theme/app_theme.dart';
import 'package:anilov/features/anime/presentation/providers/anime_providers.dart';
import 'package:anilov/features/schedule/domain/models/airing_schedule.dart';
import 'package:anilov/features/schedule/presentation/providers/schedule_providers.dart';
import 'package:anilov/features/schedule/presentation/schedule_screen.dart';
import 'package:anilov/features/schedule/presentation/widgets/schedule_card.dart';
import 'package:anilov/features/watchlist/presentation/providers/watchlist_providers.dart';
import '../fixtures/anime_fixtures.dart';

void main() {
  final sampleSchedule = AiringSchedule.fromJson(sampleAiringScheduleJson);

  testWidgets('ScheduleScreen renders weekday tabs, disclaimer notice, and schedule cards',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeAnime = FakeAnimeRepository(
      [sampleSchedule.media!],
      schedules: [sampleSchedule],
    );
    final fakeWatchlist = FakeWatchlistRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          animeRepositoryProvider.overrideWithValue(fakeAnime),
          watchlistRepositoryProvider.overrideWithValue(fakeWatchlist),
          // Override weeklyScheduleProvider to return sample schedule directly
          weeklyScheduleProvider.overrideWith((ref) async => [sampleSchedule]),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ScheduleScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // App Bar & Tabs
    expect(find.text('Broadcast Schedule'), findsOneWidget);
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Tue'), findsOneWidget);
    expect(find.text('Wed'), findsOneWidget);
    expect(find.text('Sun'), findsOneWidget);

    // Watchlist Filter Chip
    expect(find.text('Watchlist'), findsOneWidget);

    // Legal disclaimer
    expect(
      find.textContaining('Original broadcast times converted to your local time zone'),
      findsOneWidget,
    );
  });

  testWidgets('ScheduleCard displays airing time, episode number, and anime title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: ScheduleCard(schedule: sampleSchedule),
        ),
      ),
    );

    expect(find.text('Attack on Titan'), findsOneWidget);
    expect(find.text('Episode 5'), findsOneWidget);
    expect(find.text(sampleSchedule.formattedTime), findsOneWidget);
    expect(find.byType(ScheduleCard), findsOneWidget);
  });
}
