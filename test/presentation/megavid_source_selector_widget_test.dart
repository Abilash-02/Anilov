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

  const blueBoxAnime = AnimeMedia(
    id: 170942,
    title: AnimeTitle(
      romaji: 'Ao no Hako',
      english: 'Blue Box',
      native: 'アオのハコ',
    ),
    coverImage: AnimeCover(
      extraLarge: 'https://example.com/blue_box.jpg',
      large: 'https://example.com/blue_box.jpg',
    ),
    format: 'TV',
    status: 'RELEASING',
    episodes: 25,
  );

  final sampleAnime = AnimeMedia.fromJson(sampleAnimeJson);

  const testShowDetails = AnikotoShowDetails(
    tipId: 170942,
    title: 'Blue Box',
    slug: 'blue-box',
    totalEpisodes: 25,
    seasons: [
      AnikotoSeason(
        seasonNumber: 1,
        name: 'Season 1',
        slug: 'blue-box-season-1',
        episodesCount: 25,
      ),
    ],
  );

  group('WatchNowSheet MegaVid Source Selector Tests', () {
    testWidgets('displays MegaVid provider tab for Blue Box and renders S01E01 source link',
        (tester) async {
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
            home: const Scaffold(
              body: WatchNowSheet(anime: blueBoxAnime),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // MegaVid source tab is displayed under episode source selector for Blue Box
      expect(find.text('MegaVid'), findsOneWidget);

      // Scroll into view and tap MegaVid provider tab
      await tester.ensureVisible(find.text('MegaVid'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('MegaVid'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Displays Blue Box Season 1 Episode 1 title and unmodified source URL
      expect(find.text('Blue Box — Season 1 Episode 1'), findsOneWidget);
      expect(find.text('https://megavid.buzz/ani/170942/1/sub'), findsOneWidget);
      expect(find.text('In-App Browser Supported'), findsOneWidget);
      expect(find.text('Open in In-App Browser'), findsOneWidget);
      expect(find.text('Open Externally'), findsOneWidget);
      expect(find.text('Open in Player'), findsOneWidget);
    });

    testWidgets('does NOT display MegaVid provider tab for non-Blue Box anime',
        (tester) async {
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
              body: WatchNowSheet(anime: sampleAnime), // Attack on Titan
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // MegaVid is NOT displayed for non-Blue Box anime
      expect(find.text('MegaVid'), findsNothing);
      expect(find.text('AniKoto Source'), findsOneWidget);
      expect(find.text('Authorized Stream'), findsOneWidget);
    });
  });

  group('EpisodePlayerScreen MegaVid Source Selector Tests', () {
    testWidgets('displays MegaVid pill for Blue Box S01E01 and renders in-app browser surface',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = FakeAnimeRepository([blueBoxAnime]);
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
              animeId: 170942,
              initialEpisodeNumber: 1,
              initialSeasonIndex: 0,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // In source switcher, MegaVid pill is present for Episode 1
      expect(find.text('MegaVid'), findsOneWidget);

      // Scroll into view and tap MegaVid pill to switch source
      await tester.ensureVisible(find.text('MegaVid'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('MegaVid'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Renders MegaVid player surface with preserved URL and in-app browser action
      expect(find.text('Blue Box — Season 1 Episode 1'), findsOneWidget);
      expect(find.text('https://megavid.buzz/ani/170942/1/sub'), findsOneWidget);
      expect(find.text('Open in In-App Browser'), findsOneWidget);
      expect(find.text('Open in External Browser'), findsOneWidget);
      expect(find.text('Switch to In-App Player'), findsOneWidget);
    });

    testWidgets('directly launches Blue Box S01E01 with megavid provider',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = FakeAnimeRepository([blueBoxAnime]);
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
              animeId: 170942,
              initialEpisodeNumber: 1,
              initialSeasonIndex: 0,
              initialProvider: 'megavid',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text('Blue Box — Season 1 Episode 1'), findsOneWidget);
      expect(find.text('https://megavid.buzz/ani/170942/1/sub'), findsOneWidget);
      expect(find.text('Open in In-App Browser'), findsOneWidget);
    });

    testWidgets('hides MegaVid pill for Episode 2 and renders clear error if selected',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = FakeAnimeRepository([blueBoxAnime]);
      final fakeWatchlist = FakeWatchlistRepository();
      final fakeHistory = FakeHistoryRepository();
      final mockClient = MockAnikotoClient(testShowDetails);

      // Launch directly on Episode 2 with megavid provider requested
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
              animeId: 170942,
              initialEpisodeNumber: 2,
              initialSeasonIndex: 0,
              initialProvider: 'megavid',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // MegaVid is NOT in the source switcher for Episode 2
      expect(find.text('MegaVid'), findsNothing);

      // Clear error surface is rendered per Requirement 9
      expect(find.text('MegaVid Unavailable for Episode 2'), findsOneWidget);
      expect(
        find.textContaining('The MegaVid source entry is strictly associated only with Blue Box Season 1 Episode 1'),
        findsOneWidget,
      );
      expect(find.text('Switch to Authorized Player'), findsOneWidget);
    });
  });
}
