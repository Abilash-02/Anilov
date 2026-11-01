import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:anilov/core/theme/app_theme.dart';
import 'package:anilov/features/anime/domain/models/anime_media.dart';
import 'package:anilov/features/anime/presentation/providers/anime_providers.dart';
import 'package:anilov/features/explore/presentation/explore_screen.dart';
import 'package:anilov/features/home/presentation/home_screen.dart';
import 'package:anilov/features/profile/presentation/profile_screen.dart';
import 'package:anilov/features/schedule/presentation/schedule_screen.dart';
import 'package:anilov/features/watchlist/presentation/providers/watchlist_providers.dart';
import 'package:anilov/features/watchlist/presentation/watchlist_screen.dart';
import 'fixtures/anime_fixtures.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final sampleAnime = AnimeMedia.fromJson(sampleAnimeJson);

  group('Navigation & Tab Screens Render Tests', () {
    testWidgets('HomeScreen renders with live anime sections', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = FakeAnimeRepository([sampleAnime]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            animeRepositoryProvider.overrideWithValue(fakeRepo),
            watchlistRepositoryProvider.overrideWithValue(FakeWatchlistRepository()),
            historyRepositoryProvider.overrideWithValue(FakeHistoryRepository()),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const HomeScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Trending Now'), findsOneWidget);
      expect(find.text('Airing Today'), findsOneWidget);
      expect(find.text('Search anime titles, genres, studios...'), findsOneWidget);
    });

    testWidgets('ExploreScreen renders search and filter chips', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ExploreScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('All Genres'), findsOneWidget);
    });

    testWidgets('ScheduleScreen renders weekday tabs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ScheduleScreen(),
        ),
      );

      expect(find.text('Broadcast Schedule'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
    });

    testWidgets('WatchlistScreen renders status tabs and empty state', (tester) async {
      final fakeWatchlist = FakeWatchlistRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            watchlistRepositoryProvider.overrideWithValue(fakeWatchlist),
            historyRepositoryProvider.overrideWithValue(FakeHistoryRepository()),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const WatchlistScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('My Watchlist'), findsOneWidget);
      expect(find.textContaining('Watching'), findsOneWidget);
      expect(find.text('Your Watchlist is Empty'), findsOneWidget);
    });

    testWidgets('ProfileScreen renders menu items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ProfileScreen(),
        ),
      );

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Watch History'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('About & Attribution'), findsOneWidget);
    });
  });
}
