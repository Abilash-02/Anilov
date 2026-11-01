import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anilov/core/theme/app_theme.dart';
import 'package:anilov/features/anime/domain/models/anime_media.dart';
import 'package:anilov/features/anime/presentation/providers/anime_providers.dart';
import 'package:anilov/features/explore/presentation/explore_screen.dart';
import '../fixtures/anime_fixtures.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final sampleAnime = AnimeMedia.fromJson(sampleAnimeJson);

  testWidgets('ExploreScreen renders search field, filters, and anime items', (tester) async {
    final fakeRepo = FakeAnimeRepository([sampleAnime]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          animeRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ExploreScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Explore'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('All Genres'), findsOneWidget);
    expect(find.text('Attack on Titan'), findsWidgets);
  });

  testWidgets('ExploreScreen shows sort bottom sheet on icon tap', (tester) async {
    final fakeRepo = FakeAnimeRepository([sampleAnime]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          animeRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ExploreScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(Icons.sort_rounded));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Sort Anime By'), findsOneWidget);
    expect(find.text('Trending'), findsOneWidget);
    expect(find.text('Most Popular'), findsOneWidget);
  });
}
