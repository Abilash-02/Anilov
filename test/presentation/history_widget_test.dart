// Widget tests for Watch History screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anilov/core/theme/app_theme.dart';
import 'package:anilov/features/profile/presentation/history_screen.dart';
import 'package:anilov/features/watchlist/domain/models/history_item.dart';
import 'package:anilov/features/watchlist/presentation/providers/watchlist_providers.dart';
import '../fixtures/anime_fixtures.dart';

void main() {
  final now = DateTime.now();
  final sampleHistory = HistoryItem(
    id: 1,
    animeId: 16498,
    title: 'Attack on Titan',
    coverUrl: 'https://example.com/aot.jpg',
    episode: 12,
    watchedAt: now,
  );

  testWidgets('HistoryScreen renders empty state when no history exists', (tester) async {
    final fakeRepo = FakeHistoryRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historyRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HistoryScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Watch History'), findsOneWidget);
    expect(find.text('No Watch History Yet'), findsOneWidget);
  });

  testWidgets('HistoryScreen renders history items and clears with confirmation', (tester) async {
    final fakeRepo = FakeHistoryRepository([sampleHistory]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historyRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HistoryScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Attack on Titan'), findsOneWidget);
    expect(find.text('Episode 12'), findsOneWidget);

    // Tap clear history button in app bar
    await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Clear Watch History?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Tap Clear All
    await tester.tap(find.widgetWithText(FilledButton, 'Clear All'));
    await tester.pumpAndSettle();

    final remaining = await fakeRepo.getHistory();
    expect(remaining.isEmpty, isTrue);
  });
}
