import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anilov/core/theme/app_theme.dart';
import 'package:anilov/features/anime/domain/models/anime_media.dart';
import 'package:anilov/features/anime/presentation/providers/anime_providers.dart';
import 'package:anilov/features/home/presentation/home_screen.dart';
import 'package:anilov/features/watchlist/presentation/providers/watchlist_providers.dart';
import '../fixtures/anime_fixtures.dart';

void main() {
  final sampleAnime = AnimeMedia.fromJson(sampleAnimeJson);

  testWidgets('HomeScreen renders search entry point, genre chips, and anime sections', (tester) async {
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
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HomeScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify search bar entry point
    expect(find.text('Search anime titles, genres, studios...'), findsOneWidget);

    // Verify genre shortcuts
    expect(find.text('Action'), findsWidgets);
    expect(find.text('Adventure'), findsOneWidget);

    // Verify sections visible initially
    expect(find.text('TRENDING #1'), findsOneWidget);
    expect(find.text('Airing Today'), findsOneWidget);
    expect(find.text('Trending Now'), findsOneWidget);
    expect(find.text('All-Time Popular'), findsOneWidget);

    // Scroll to see remaining sections
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pump();

    expect(find.text('Top Rated'), findsOneWidget);
    expect(find.text('Currently Airing'), findsOneWidget);

    // Verify anime title renders
    expect(find.text('Attack on Titan'), findsWidgets);
  });

  testWidgets('HomeScreen displays error state and retry button on failure', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeDataProvider.overrideWith((ref) async {
            throw Exception('Network timeout error');
          }),
          watchlistRepositoryProvider.overrideWithValue(FakeWatchlistRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HomeScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Unable to load anime catalog'), findsOneWidget);
    expect(find.textContaining('Network timeout error'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
