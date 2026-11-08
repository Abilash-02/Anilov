import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:anilov/core/theme/app_theme.dart';
import 'package:anilov/features/anime/data/anikoto_client.dart';
import 'package:anilov/features/anime/domain/models/anime_media.dart';
import 'package:anilov/features/anime/domain/models/playback_provider.dart';
import 'package:anilov/features/anime/presentation/providers/anikoto_providers.dart';
import 'package:anilov/features/anime/presentation/providers/anime_providers.dart';
import 'package:anilov/features/anime/presentation/screens/anime_details_screen.dart';
import 'package:anilov/features/anime/presentation/widgets/watch_now_sheet.dart';
import 'package:anilov/features/player/presentation/episode_player_screen.dart';
import 'package:anilov/features/watchlist/presentation/providers/watchlist_providers.dart';
import '../fixtures/anime_fixtures.dart';

class MockAnikotoClient extends AnikotoClient {
  final AnikotoShowDetails mockShow;

  MockAnikotoClient(this.mockShow);

  @override
  Future<AnikotoShowDetails> resolveShow(AnimeMedia anime) async {
    return mockShow;
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  final sampleAnime = AnimeMedia.fromJson(sampleAnimeJson);

  const testShowDetails = AnikotoShowDetails(
    tipId: 1631,
    title: 'Attack on Titan',
    slug: 'attack-on-titan-bgaoa',
    totalEpisodes: 25,
    subEpisodes: 25,
    dubEpisodes: 25,
    seasons: [
      AnikotoSeason(
        seasonNumber: 1,
        name: 'Season 1',
        slug: 'attack-on-titan-bgaoa',
        episodesCount: 25,
      ),
      AnikotoSeason(
        seasonNumber: 2,
        name: 'Season 2',
        slug: 'attack-on-titan-season-2-0rtbh',
        episodesCount: 12,
      ),
    ],
  );

  group('WatchNowSheet Widget Tests', () {
    testWidgets('renders title, provider tabs, season chips, and episode grid', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeWatchlist = FakeWatchlistRepository();
      final fakeHistory = FakeHistoryRepository();
      final mockClient = MockAnikotoClient(testShowDetails);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            watchlistRepositoryProvider.overrideWithValue(fakeWatchlist),
            historyRepositoryProvider.overrideWithValue(fakeHistory),
            anikotoClientProvider.overrideWithValue(mockClient),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: WatchNowSheet(anime: sampleAnime),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Title & header
      expect(find.text('Watch Now'), findsOneWidget);
      expect(find.text(sampleAnime.title.displayTitle), findsOneWidget);

      // Provider tabs
      expect(find.text('AniKoto Source'), findsOneWidget);
      expect(find.text('Local Player'), findsOneWidget);

      // Season chips
      expect(find.text('Season 1'), findsOneWidget);
      expect(find.text('Season 2'), findsOneWidget);

      // Episodes header & Play Ep 1 quick action
      expect(find.text('Episodes (25)'), findsOneWidget);
      expect(find.text('Play Ep 1'), findsOneWidget);

      // Episode grid numbers
      expect(find.text('1'), findsWidgets);
      expect(find.text('2'), findsWidgets);
      expect(find.text('25'), findsWidgets);

      // Switch to Local Player tab
      await tester.tap(find.text('Local Player'));
      await tester.pumpAndSettle();

      expect(find.text('Local Media & Direct Stream Player'), findsOneWidget);
      expect(find.text('Open Local Player'), findsOneWidget);
    });
  });

  group('EpisodePlayerScreen Widget & Flow Tests', () {
    testWidgets('renders player header, embed restriction notice, and external browser button',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = FakeAnimeRepository([sampleAnime]);
      final fakeWatchlist = FakeWatchlistRepository();
      final fakeHistory = FakeHistoryRepository();
      final mockClient = MockAnikotoClient(testShowDetails);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            animeRepositoryProvider.overrideWithValue(fakeRepo),
            watchlistRepositoryProvider.overrideWithValue(fakeWatchlist),
            historyRepositoryProvider.overrideWithValue(fakeHistory),
            anikotoClientProvider.overrideWithValue(mockClient),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const EpisodePlayerScreen(
              animeId: 16498,
              initialEpisodeNumber: 1,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Header title and episode info
      expect(find.text('Attack on Titan'), findsOneWidget);
      expect(find.textContaining('Season 1 • Episode 1 of 25'), findsOneWidget);

      // Embedding restriction notice (Section 4 Compliance)
      expect(find.text('Official Episode 1 on AniKoto'), findsOneWidget);
      expect(find.textContaining('X-Frame-Options: SAMEORIGIN'), findsOneWidget);
      expect(find.textContaining('hidden streams are not scraped or bypassed'), findsOneWidget);

      // External browser button
      expect(find.text('Watch Episode 1 on AniKoto'), findsOneWidget);

      // Local player secondary button
      expect(find.text('Open Local Player'), findsOneWidget);

      // Episode navigation controls
      expect(find.byTooltip('Previous Episode'), findsOneWidget);
      expect(find.byTooltip('Next Episode'), findsOneWidget);
      expect(find.text('Ep 1 / 25'), findsOneWidget);
    });

    testWidgets('episode navigation boundaries and next episode increment', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = FakeAnimeRepository([sampleAnime]);
      final fakeWatchlist = FakeWatchlistRepository();
      final fakeHistory = FakeHistoryRepository();
      final mockClient = MockAnikotoClient(testShowDetails);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            animeRepositoryProvider.overrideWithValue(fakeRepo),
            watchlistRepositoryProvider.overrideWithValue(fakeWatchlist),
            historyRepositoryProvider.overrideWithValue(fakeHistory),
            anikotoClientProvider.overrideWithValue(mockClient),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const EpisodePlayerScreen(
              animeId: 16498,
              initialEpisodeNumber: 1,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Initially at Ep 1
      expect(find.text('Ep 1 / 25'), findsOneWidget);

      // Tap Next Episode
      await tester.tap(find.byTooltip('Next Episode'));
      await tester.pumpAndSettle();

      // Now at Ep 2
      expect(find.text('Ep 2 / 25'), findsOneWidget);
      expect(find.text('Official Episode 2 on AniKoto'), findsOneWidget);
      expect(find.text('Watch Episode 2 on AniKoto'), findsOneWidget);

      // Tap Previous Episode
      await tester.tap(find.byTooltip('Previous Episode'));
      await tester.pumpAndSettle();

      // Returned to Ep 1
      expect(find.text('Ep 1 / 25'), findsOneWidget);
    });

    testWidgets('episode selection modal opens and switches active episode', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = FakeAnimeRepository([sampleAnime]);
      final fakeWatchlist = FakeWatchlistRepository();
      final fakeHistory = FakeHistoryRepository();
      final mockClient = MockAnikotoClient(testShowDetails);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            animeRepositoryProvider.overrideWithValue(fakeRepo),
            watchlistRepositoryProvider.overrideWithValue(fakeWatchlist),
            historyRepositoryProvider.overrideWithValue(fakeHistory),
            anikotoClientProvider.overrideWithValue(mockClient),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const EpisodePlayerScreen(
              animeId: 16498,
              initialEpisodeNumber: 1,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Episode selector button in center of nav bar
      await tester.tap(find.text('Ep 1 / 25'));
      await tester.pumpAndSettle();

      // Modal is open
      expect(find.text('Select Episode (Season 1)'), findsOneWidget);

      // Select Episode 5
      await tester.tap(find.text('5').last);
      await tester.pumpAndSettle();

      // Navigated to Ep 5
      expect(find.text('Ep 5 / 25'), findsOneWidget);
      expect(find.text('Watch Episode 5 on AniKoto'), findsOneWidget);
    });

    testWidgets('orientation toggle button toggles landscape and portrait player modes',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = FakeAnimeRepository([sampleAnime]);
      final fakeWatchlist = FakeWatchlistRepository();
      final fakeHistory = FakeHistoryRepository();
      final mockClient = MockAnikotoClient(testShowDetails);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            animeRepositoryProvider.overrideWithValue(fakeRepo),
            watchlistRepositoryProvider.overrideWithValue(fakeWatchlist),
            historyRepositoryProvider.overrideWithValue(fakeHistory),
            anikotoClientProvider.overrideWithValue(mockClient),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const EpisodePlayerScreen(
              animeId: 16498,
              initialEpisodeNumber: 1,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Landscape toggle button is present
      expect(find.byTooltip('Switch to Landscape Player'), findsOneWidget);

      await tester.tap(find.byTooltip('Switch to Landscape Player'));
      await tester.pumpAndSettle();

      // Orientation toggled without exception
      expect(find.text('Attack on Titan'), findsWidgets);
    });
  });

  group('AnimeDetailsScreen Watch Now Integration Tests', () {
    testWidgets('renders prominent Watch Now button and opens WatchNowSheet on tap',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = FakeAnimeRepository([sampleAnime]);
      final fakeWatchlist = FakeWatchlistRepository();
      final fakeHistory = FakeHistoryRepository();
      final mockClient = MockAnikotoClient(testShowDetails);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            animeRepositoryProvider.overrideWithValue(fakeRepo),
            watchlistRepositoryProvider.overrideWithValue(fakeWatchlist),
            historyRepositoryProvider.overrideWithValue(fakeHistory),
            anikotoClientProvider.overrideWithValue(mockClient),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const AnimeDetailsScreen(id: 16498),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Watch Now button exists
      expect(find.text('Watch Now'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsWidgets);

      // Tap Watch Now button
      await tester.tap(find.text('Watch Now'));
      await tester.pumpAndSettle();

      // WatchNowSheet opened
      expect(find.byType(WatchNowSheet), findsOneWidget);
      expect(find.text('AniKoto Source'), findsOneWidget);
      expect(find.text('Episodes (25)'), findsWidgets);
    });
  });
}
