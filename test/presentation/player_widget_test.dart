import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:anilov/core/router/app_router.dart';
import 'package:anilov/core/theme/app_theme.dart';
import 'package:anilov/features/anime/domain/models/anime_media.dart';
import 'package:anilov/features/anime/presentation/providers/anime_providers.dart';
import 'package:anilov/features/player/domain/video_source_evaluator.dart';
import 'package:anilov/features/player/presentation/local_player_screen.dart';
import 'package:anilov/features/watchlist/presentation/providers/watchlist_providers.dart';
import '../fixtures/anime_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final sampleAnime = AnimeMedia.fromJson(sampleAnimeJson);

  group('LocalPlayerScreen Widget & Flow Tests', () {
    testWidgets(
        'LocalPlayerScreen renders empty state, instructions, picker and URL buttons',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const LocalPlayerScreen(),
          ),
        ),
      );

      // Header & Empty State Title
      expect(find.text('Local Media Player'), findsWidgets);
      expect(find.byIcon(Icons.video_collection_outlined), findsOneWidget);

      // Descriptive explanation
      expect(
        find.textContaining('Play your own legally acquired video files'),
        findsOneWidget,
      );

      // Primary file action button
      expect(find.text('Select Video File'), findsOneWidget);
      expect(find.byIcon(Icons.folder_open_rounded), findsWidgets);

      // URL Stream action button
      expect(find.text('Open Video URL / Stream'), findsOneWidget);
      expect(find.byIcon(Icons.link_rounded), findsWidgets);

      // Quick test chip for Google Share link
      expect(find.text('Test Google Share Link'), findsOneWidget);

      // Supported formats note
      expect(
        find.textContaining('Supports MP4, MKV, WebM'),
        findsOneWidget,
      );
    });

    testWidgets('Tapping URL Stream button displays prompt dialog with Google Share preset',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const LocalPlayerScreen(),
          ),
        ),
      );

      // Tap "Open Video URL / Stream" button
      await tester.tap(find.text('Open Video URL / Stream'));
      await tester.pumpAndSettle();

      // Verify dialog is open
      expect(find.text('Open Video URL / Stream'), findsWidgets);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Google Share Link'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);

      // Tap "Google Share Link" preset chip
      await tester.tap(find.text('Google Share Link'));
      await tester.pumpAndSettle();

      // Verify text field contains Google Share URL
      expect(
        find.text(VideoSourceEvaluator.defaultGoogleShareUrl),
        findsOneWidget,
      );

      // Close dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets(
        'Testing Google Share link triggers External Webpage dialog with Open Externally option',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const LocalPlayerScreen(),
          ),
        ),
      );

      // Tap quick test chip
      await tester.tap(find.text('Test Google Share Link'));
      await tester.pumpAndSettle();

      // Should display unsupported webpage dialog
      expect(find.text('External Webpage Detected'), findsOneWidget);
      expect(find.textContaining('Google Share webpage'), findsOneWidget);
      expect(find.textContaining('external web browser'), findsOneWidget);
      expect(find.text('Open Externally'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('External Webpage Detected'), findsNothing);
    });

    testWidgets('LocalPlayerScreen handles controller disposal safely', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const LocalPlayerScreen(initialUrl: 'https://cdn.example.org/nonexistent.mp4'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Replace widget tree to force dispose()
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Replacement Screen')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Replacement Screen'), findsOneWidget);
    });
  });

  group('Navigation Regression Tests: Local Player', () {
    testWidgets('Navigate to /player from AnimeDetailsScreen without GlobalKey collision',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = FakeAnimeRepository([sampleAnime]);
      final fakeWatchlist = FakeWatchlistRepository();
      final fakeHistory = FakeHistoryRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            animeRepositoryProvider.overrideWithValue(fakeRepo),
            watchlistRepositoryProvider.overrideWithValue(fakeWatchlist),
            historyRepositoryProvider.overrideWithValue(fakeHistory),
          ],
          child: MaterialApp.router(
            routerConfig: appRouter,
            theme: AppTheme.darkTheme,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to /anime/16498 on root navigator
      appRouter.push('/anime/16498');
      await tester.pumpAndSettle();

      expect(find.text('Attack on Titan'), findsOneWidget);
      expect(find.text('Local Player'), findsOneWidget);

      // Tap Local Player button - must not trigger "!keyReservation.contains(key)" assertion!
      await tester.tap(find.text('Local Player'));
      await tester.pumpAndSettle();

      // Verify Local Media Player is now active on top of stack
      expect(find.text('Local Media Player'), findsWidgets);
      expect(find.text('Select Video File'), findsOneWidget);
      expect(find.text('Open Video URL / Stream'), findsOneWidget);

      // Pop player to return to details
      appRouter.pop();
      await tester.pumpAndSettle();

      expect(find.text('Attack on Titan'), findsOneWidget);
    });

    testWidgets('Navigate to /player from ProfileScreen without crash',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            watchlistRepositoryProvider.overrideWithValue(FakeWatchlistRepository()),
            historyRepositoryProvider.overrideWithValue(FakeHistoryRepository()),
          ],
          child: MaterialApp.router(
            routerConfig: appRouter,
            theme: AppTheme.darkTheme,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to Profile tab
      appRouter.go('/profile');
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Local Media Player'), findsOneWidget);

      // Tap Local Media Player
      await tester.tap(find.text('Local Media Player'));
      await tester.pumpAndSettle();

      expect(find.text('Local Media Player'), findsWidgets);
      expect(find.text('Select Video File'), findsOneWidget);
    });
  });
}
