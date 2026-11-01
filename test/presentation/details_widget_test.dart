import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:anilov/core/theme/app_theme.dart';
import 'package:anilov/features/anime/domain/models/anime_media.dart';
import 'package:anilov/features/anime/presentation/providers/anime_providers.dart';
import 'package:anilov/features/anime/presentation/screens/anime_details_screen.dart';
import 'package:anilov/features/watchlist/presentation/providers/watchlist_providers.dart';
import '../fixtures/anime_fixtures.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  final sampleAnime = AnimeMedia.fromJson(sampleAnimeJson);

  testWidgets('AnimeDetailsScreen renders metadata, synopsis, trailer, and official sources', (tester) async {
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
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AnimeDetailsScreen(id: 16498),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify title and metadata
    expect(find.text('Attack on Titan'), findsOneWidget);
    expect(find.text('85%'), findsOneWidget);
    expect(find.text('(AniList)'), findsOneWidget);
    expect(find.text('TV Series'), findsOneWidget);
    expect(find.text('WIT Studio'), findsOneWidget);

    // Quick stats and episode section
    expect(find.text('Episodes'), findsWidgets);
    expect(find.text('25'), findsWidgets);

    // Synopsis
    expect(find.text('Synopsis'), findsOneWidget);
    expect(find.text('Read more'), findsOneWidget);

    // Tap Read more to expand
    await tester.tap(find.text('Read more'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Show less'), findsOneWidget);

    // Official Trailer
    expect(find.text('Official Trailer'), findsOneWidget);

    // Official Where to Watch links
    expect(find.text('Where to Watch'), findsOneWidget);
    expect(find.text('Crunchyroll'), findsOneWidget);
    expect(find.text('Netflix'), findsOneWidget);

    // Related anime
    expect(find.text('Related Anime'), findsOneWidget);
    expect(find.text('Attack on Titan Season 2'), findsOneWidget);

    // Watchlist action button
    expect(find.text('Add to Watchlist'), findsOneWidget);
    await tester.tap(find.text('Add to Watchlist'));
    await tester.pumpAndSettle();
    expect(find.text('Status'), findsOneWidget);
  });

  testWidgets('AnimeDetailsScreen renders error state and retry button on failure', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          animeDetailsProvider(16498).overrideWith((ref) async {
            throw Exception('Failed to load anime details');
          }),
          watchlistRepositoryProvider.overrideWithValue(FakeWatchlistRepository()),
          historyRepositoryProvider.overrideWithValue(FakeHistoryRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AnimeDetailsScreen(id: 16498),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('Failed to load anime details'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
