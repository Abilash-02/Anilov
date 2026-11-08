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

  group('Media3 Native In-App Player & Provider Switching Tests', () {
    testWidgets('renders in-app authorized Media3 player with source switcher and controls',
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
              initialProvider: 'authorized',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Header title and episode info
      expect(find.text('Attack on Titan'), findsOneWidget);
      expect(find.textContaining('Season 1 • Episode 1 of 25'), findsOneWidget);

      // Source switcher bar options
      expect(find.text('Authorized Stream'), findsOneWidget);
      expect(find.text('AniKoto'), findsOneWidget);
      expect(find.text('Fetch (Kickass)'), findsOneWidget);
      expect(find.text('Local Player'), findsOneWidget);

      // Episode navigation controls
      expect(find.byTooltip('Previous Episode'), findsOneWidget);
      expect(find.byTooltip('Next Episode'), findsOneWidget);
      expect(find.text('Ep 1 / 25'), findsOneWidget);
      expect(find.byTooltip('Switch to Landscape Player'), findsOneWidget);

      // Switch to Fetch (Kickass) provider
      await tester.tap(find.text('Fetch (Kickass)'));
      await tester.pumpAndSettle();

      expect(find.text('Fetch (KickassAnime) Scraper Limitation'), findsOneWidget);
      expect(find.text('Switch to In-App Player'), findsOneWidget);

      // Switch back to Authorized In-App Player via source switcher pill
      await tester.tap(find.text('Authorized Stream'));
      await tester.pumpAndSettle();

      // Switch to AniKoto provider
      await tester.tap(find.text('AniKoto'));
      await tester.pumpAndSettle();

      expect(find.text('Official Episode 1 on AniKoto'), findsOneWidget);
      expect(find.textContaining('X-Frame-Options: SAMEORIGIN'), findsOneWidget);
      expect(find.text('Watch Episode 1 on AniKoto'), findsOneWidget);
    });

    testWidgets('WatchNowSheet multi-provider browsing and switching', (tester) async {
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

      // Check all 4 provider tabs are present
      expect(find.text('AniKoto Source'), findsOneWidget);
      expect(find.text('Authorized Stream'), findsOneWidget);
      expect(find.text('Fetch (Kickass)'), findsOneWidget);
      expect(find.text('Local Player'), findsOneWidget);

      // Switch to Authorized Stream tab
      await tester.tap(find.text('Authorized Stream'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Authorized HLS Episodes'), findsOneWidget);
      expect(find.text('Play Ep 1'), findsOneWidget);

      // Switch to Fetch (Kickass) tab
      await tester.ensureVisible(find.text('Fetch (Kickass)'));
      await tester.tap(find.text('Fetch (Kickass)'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Fetch (KickassAnime) Source Limitation'), findsOneWidget);
      expect(find.text('Switch to Authorized Stream'), findsOneWidget);

      // Switch to Local Player tab
      await tester.ensureVisible(find.text('Local Player'));
      await tester.tap(find.text('Local Player'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Local Media & Direct Stream Player'), findsOneWidget);
      expect(find.text('Open Local Player'), findsOneWidget);
    });
  });
}
