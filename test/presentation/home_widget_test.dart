import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anilov/core/theme/app_theme.dart';
import 'package:anilov/features/anime/domain/models/anime_media.dart';
import 'package:anilov/features/anime/presentation/providers/anime_providers.dart';
import 'package:anilov/features/home/presentation/home_screen.dart';
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

    // Verify sections
    expect(find.text('TRENDING #1'), findsOneWidget);
    expect(find.text('Airing Today'), findsOneWidget);
    expect(find.text('Trending Now'), findsOneWidget);
    expect(find.text('All-Time Popular'), findsOneWidget);
    expect(find.text('Top Rated'), findsOneWidget);
    expect(find.text('Currently Airing'), findsOneWidget);

    // Verify anime title renders
    expect(find.text('Attack on Titan'), findsWidgets);
  });

  testWidgets('HomeScreen displays error state and retry button on failure', (tester) async {
    final fakeRepo = FakeAnimeRepository([sampleAnime], shouldFail: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          animeRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HomeScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Unable to load anime catalog'), findsOneWidget);
    expect(find.textContaining('Network timeout error'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
