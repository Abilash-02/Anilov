import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/anime/presentation/screens/anime_details_screen.dart';
import '../../features/explore/presentation/explore_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/player/presentation/episode_player_screen.dart';
import '../../features/player/presentation/local_player_screen.dart';
import '../../features/profile/presentation/about_screen.dart';
import '../../features/profile/presentation/history_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';
import '../../features/schedule/presentation/schedule_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/watchlist/presentation/watchlist_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/anime/:id',
      builder: (context, state) {
        final idStr = state.pathParameters['id'] ?? '0';
        final id = int.tryParse(idStr) ?? 0;
        return AnimeDetailsScreen(id: id);
      },
    ),
    GoRoute(
      path: '/watch/:id',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final idStr = state.pathParameters['id'] ?? '0';
        final id = int.tryParse(idStr) ?? 0;
        final epStr = state.uri.queryParameters['ep'];
        final ep = int.tryParse(epStr ?? '1') ?? 1;
        final seasonStr = state.uri.queryParameters['season'];
        final season = int.tryParse(seasonStr ?? '0') ?? 0;
        return EpisodePlayerScreen(
          animeId: id,
          initialEpisodeNumber: ep,
          initialSeasonIndex: season,
        );
      },
    ),
    GoRoute(
      path: '/player',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final filePath = state.uri.queryParameters['file'];
        final url = state.uri.queryParameters['url'];
        return LocalPlayerScreen(
          initialFilePath: filePath,
          initialUrl: url,
        );
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        // Tab 1: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),

        // Tab 2: Explore
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/explore',
              builder: (context, state) => const ExploreScreen(),
            ),
          ],
        ),

        // Tab 3: Schedule
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/schedule',
              builder: (context, state) => const ScheduleScreen(),
            ),
          ],
        ),

        // Tab 4: Watchlist
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/watchlist',
              builder: (context, state) => const WatchlistScreen(),
            ),
          ],
        ),

        // Tab 5: Profile (contains History, Settings, About)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
              routes: [
                GoRoute(
                  path: 'history',
                  builder: (context, state) => const HistoryScreen(),
                ),
                GoRoute(
                  path: 'settings',
                  builder: (context, state) => const SettingsScreen(),
                ),
                GoRoute(
                  path: 'player',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) {
                    final filePath = state.uri.queryParameters['file'];
                    final url = state.uri.queryParameters['url'];
                    return LocalPlayerScreen(
                      initialFilePath: filePath,
                      initialUrl: url,
                    );
                  },
                ),
                GoRoute(
                  path: 'about',
                  builder: (context, state) => const AboutScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
