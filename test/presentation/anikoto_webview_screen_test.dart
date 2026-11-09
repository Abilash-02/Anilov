import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anilov/core/theme/app_theme.dart';
import 'package:anilov/features/anime/presentation/screens/anikoto_webview_screen.dart';
import 'package:anilov/features/anime/presentation/widgets/anikoto_inapp_player.dart';

void main() {
  group('AnikotoWebViewScreen Tests', () {
    testWidgets('renders AniKoto WebView screen with homepage and controls',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const homepageUrl = 'https://anikoto.cz/home';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AnikotoWebViewScreen(
            initialUrl: homepageUrl,
            title: 'AniKoto Home',
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Header controls bar
      expect(find.text('AniKoto Home'), findsWidgets);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsWidgets);
      expect(find.byIcon(Icons.open_in_browser_rounded), findsWidgets);

      // Verify initial URL is displayed in preview
      expect(find.text(homepageUrl), findsOneWidget);
      expect(find.textContaining('AniKoto In-App WebView Player'), findsOneWidget);
    });

    testWidgets('renders episode page URL and handles orientation toggle',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const episodeUrl = 'https://anikoto.cz/watch/solo-leveling-ilh08/ep-1';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AnikotoWebViewScreen(
            initialUrl: episodeUrl,
            title: 'Solo Leveling — Ep 1',
            episodeNumber: 1,
            animeId: 151807,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Title & URL
      expect(find.text('Solo Leveling — Ep 1'), findsWidgets);
      expect(find.text(episodeUrl), findsOneWidget);

      // Orientation button
      expect(find.byIcon(Icons.crop_landscape_rounded), findsWidgets);

      // Tap orientation toggle button
      await tester.tap(find.byIcon(Icons.crop_landscape_rounded).first);
      await tester.pumpAndSettle();

      // Toggled to landscape controls
      expect(find.byIcon(Icons.crop_portrait_rounded), findsWidgets);
    });

    testWidgets('provides retry and external browser options in fallback/error state',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AnikotoWebViewScreen(
            initialUrl: 'https://anikoto.cz/login',
            title: 'AniKoto Login',
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Options for reload and external fallback
      expect(find.text('Reload WebView'), findsOneWidget);
      expect(find.text('Open in External Browser'), findsOneWidget);

      // Tap reload
      await tester.tap(find.text('Reload WebView'));
      await tester.pumpAndSettle();

      expect(find.text('AniKoto Login'), findsWidgets);
    });
  });

  group('AnikotoInAppPlayer Embedded Widget Tests', () {
    testWidgets('renders embedded in-app player with full-screen and external options',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const testUrl = 'https://anikoto.cz/watch/attack-on-titan-bgaoa/ep-1';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: SizedBox(
              width: 400,
              height: 250,
              child: AnikotoInAppPlayer(
                watchUrl: testUrl,
                title: 'Attack on Titan — Ep 1',
                episodeNumber: 1,
                animeId: 16498,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Header and notices
      expect(find.text('Official Episode 1 on AniKoto'), findsOneWidget);
      expect(find.textContaining('X-Frame-Options: SAMEORIGIN'), findsOneWidget);
      expect(find.textContaining('hidden streams are not scraped or bypassed'), findsOneWidget);

      // Buttons
      expect(find.text('Watch Episode 1 on AniKoto'), findsOneWidget);
      expect(find.text('Open Full-Screen WebView'), findsOneWidget);
      expect(find.text('Open Local Player'), findsOneWidget);
      expect(find.byIcon(Icons.fullscreen_rounded), findsWidgets);
    });

    testWidgets('lifecycle dispose cleans up gracefully without errors',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnikotoInAppPlayer(
              watchUrl: 'https://anikoto.cz/home',
              title: 'AniKoto',
              episodeNumber: 1,
            ),
          ),
        ),
      );

      await tester.pump();
      // Replace with empty container to trigger dispose
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox.shrink())));
      await tester.pump();

      // Successfully disposed
      expect(find.byType(AnikotoInAppPlayer), findsNothing);
    });
  });
}
