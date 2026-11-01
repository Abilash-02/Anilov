import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anilov/core/theme/app_theme.dart';
import 'package:anilov/features/explore/presentation/explore_screen.dart';
import 'package:anilov/features/home/presentation/home_screen.dart';
import 'package:anilov/features/profile/presentation/profile_screen.dart';
import 'package:anilov/features/schedule/presentation/schedule_screen.dart';
import 'package:anilov/features/watchlist/presentation/watchlist_screen.dart';

void main() {
  group('Placeholder Screens Render Tests', () {
    testWidgets('HomeScreen renders logo and sections', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HomeScreen(),
        ),
      );

      expect(find.text('FOUNDATION READY'), findsOneWidget);
      expect(find.text('Trending Now'), findsOneWidget);
      expect(find.text('Airing Today'), findsOneWidget);
    });

    testWidgets('ExploreScreen renders search and filter chips', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ExploreScreen(),
        ),
      );

      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('All Genres'), findsOneWidget);
      expect(find.text('Explore Anime Catalog'), findsOneWidget);
    });

    testWidgets('ScheduleScreen renders weekday tabs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ScheduleScreen(),
        ),
      );

      expect(find.text('Broadcast Schedule'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
    });

    testWidgets('WatchlistScreen renders status tabs and empty state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const WatchlistScreen(),
        ),
      );

      expect(find.text('My Watchlist'), findsOneWidget);
      expect(find.text('Watching'), findsOneWidget);
      expect(find.text('Your Watchlist is Empty'), findsOneWidget);
    });

    testWidgets('ProfileScreen renders menu items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ProfileScreen(),
        ),
      );

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Watch History'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('About & Attribution'), findsOneWidget);
    });
  });
}
