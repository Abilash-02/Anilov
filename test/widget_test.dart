import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anilov/core/theme/app_theme.dart';
import 'package:anilov/features/common/widgets/anilov_logo.dart';
import 'package:anilov/features/onboarding/presentation/onboarding_screen.dart';
import 'package:anilov/features/profile/presentation/about_screen.dart';
import 'package:anilov/features/profile/presentation/settings_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AnilovLogo Widget Tests', () {
    testWidgets('renders wordmark and logo', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnilovLogo(
              showWordmark: true,
              showTagline: true,
            ),
          ),
        ),
      );

      expect(find.text('Anilov'), findsOneWidget);
      expect(find.text('Discover anime. Track every episode.'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders icon only when showWordmark is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnilovLogo(
              showWordmark: false,
            ),
          ),
        ),
      );

      expect(find.text('Anilov'), findsNothing);
      expect(find.descendant(of: find.byType(AnilovLogo), matching: find.byType(CustomPaint)), findsOneWidget);
    });
  });

  group('OnboardingScreen Widget Tests', () {
    testWidgets('displays first onboarding page with Discover Anime', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const OnboardingScreen(),
        ),
      );

      expect(find.text('Discover Anime'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('tapping Continue advances page', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const OnboardingScreen(),
        ),
      );

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Track Every Episode'), findsOneWidget);
    });
  });

  group('AboutScreen Attribution Tests', () {
    testWidgets('displays required AniList and ani.zip attributions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AboutScreen(),
        ),
      );

      expect(find.text('About & Attribution'), findsOneWidget);
      expect(find.text('AniList GraphQL API'), findsOneWidget);
      expect(find.text('ani.zip Community Service'), findsOneWidget);
      expect(find.text('Legal Boundaries & Policy'), findsOneWidget);
    });
  });

  group('SettingsScreen Tests', () {
    testWidgets('toggles adult content switch', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const SettingsScreen(),
        ),
      );

      expect(find.text('Adult Content Filter'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsNWidgets(2));

      await tester.tap(find.byType(SwitchListTile).first);
      await tester.pumpAndSettle();
    });
  });
}
