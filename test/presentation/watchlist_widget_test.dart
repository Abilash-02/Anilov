// Widget tests for Watchlist screen and WatchlistCard

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:anilov/core/theme/app_theme.dart';
import 'package:anilov/features/watchlist/domain/models/watch_status.dart';
import 'package:anilov/features/watchlist/domain/models/watchlist_item.dart';
import 'package:anilov/features/watchlist/presentation/providers/watchlist_providers.dart';
import 'package:anilov/features/watchlist/presentation/watchlist_screen.dart';
import '../fixtures/anime_fixtures.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  final now = DateTime.now();
  final sampleItem = WatchlistItem(
    animeId: 16498,
    title: 'Attack on Titan',
    coverUrl: 'https://example.com/aot.jpg',
    format: 'TV',
    totalEpisodes: 25,
    status: WatchStatus.watching,
    progress: 10,
    score: 9.0,
    updatedAt: now,
    createdAt: now,
  );

  testWidgets('WatchlistScreen renders empty state when no anime in watchlist', (tester) async {
    final fakeRepo = FakeWatchlistRepository();
    final fakeHistory = FakeHistoryRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          watchlistRepositoryProvider.overrideWithValue(fakeRepo),
          historyRepositoryProvider.overrideWithValue(fakeHistory),
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
    expect(find.text('Your Watchlist is Empty'), findsOneWidget);
    expect(find.text('Explore Anime'), findsOneWidget);
  });

  testWidgets('WatchlistScreen renders watchlist items with progress and status badge', (tester) async {
    final fakeRepo = FakeWatchlistRepository([sampleItem]);
    final fakeHistory = FakeHistoryRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          watchlistRepositoryProvider.overrideWithValue(fakeRepo),
          historyRepositoryProvider.overrideWithValue(fakeHistory),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const WatchlistScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Attack on Titan'), findsOneWidget);
    expect(find.text('Watching'), findsWidgets);
    expect(find.text('Ep 10 / 25'), findsOneWidget);
    expect(find.text('+1 Ep'), findsOneWidget);

    // Tap +1 Ep
    await tester.tap(find.text('+1 Ep'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Progress updated in repository
    final updated = await fakeRepo.getWatchlistItem(16498);
    expect(updated!.progress, 11);
  });

  testWidgets('WatchlistScreen removes item with confirmation dialog', (tester) async {
    final fakeRepo = FakeWatchlistRepository([sampleItem]);
    final fakeHistory = FakeHistoryRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          watchlistRepositoryProvider.overrideWithValue(fakeRepo),
          historyRepositoryProvider.overrideWithValue(fakeHistory),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const WatchlistScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Tap more menu
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Tap Remove
    expect(find.text('Remove'), findsOneWidget);
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    // Confirmation dialog
    expect(find.text('Remove from Watchlist?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Confirm removal
    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await tester.pumpAndSettle();

    expect(await fakeRepo.isInWatchlist(16498), isFalse);
  });
}
