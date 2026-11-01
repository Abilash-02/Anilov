import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anilov/core/theme/app_theme.dart';
import 'package:anilov/features/anime/domain/models/anime_media.dart';
import 'package:anilov/features/anime/presentation/providers/anime_providers.dart';
import 'package:anilov/features/anime/presentation/screens/anime_details_screen.dart';
import '../fixtures/anime_fixtures.dart';

void main() {
  final sampleAnime = AnimeMedia.fromJson(sampleAnimeJson);

  testWidgets('AnimeDetailsScreen renders metadata, synopsis, trailer, and official sources', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          animeDetailsProvider(16498).overrideWith((ref) => Future.value(sampleAnime)),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AnimeDetailsScreen(id: 16498),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify title and metadata
    expect(find.text('Attack on Titan'), findsOneWidget);
    expect(find.text('85%'), findsOneWidget);
    expect(find.text('(AniList)'), findsOneWidget);
    expect(find.text('TV Series'), findsOneWidget);
    expect(find.text('WIT Studio'), findsOneWidget);

    // Quick stats
    expect(find.text('Episodes'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);

    // Synopsis
    expect(find.text('Synopsis'), findsOneWidget);
    expect(find.text('Read more'), findsOneWidget);

    // Tap Read more to expand
    await tester.tap(find.text('Read more'));
    await tester.pump(const Duration(milliseconds: 300));
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
    await tester.pump();
    expect(find.text('Watchlist & offline persistence will activate in RUN 3.'), findsOneWidget);
  });

  testWidgets('AnimeDetailsScreen renders error state and retry button on failure', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          animeDetailsProvider(16498).overrideWith((ref) => Future.error('Error fetching details')),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AnimeDetailsScreen(id: 16498),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Failed to load anime details'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
