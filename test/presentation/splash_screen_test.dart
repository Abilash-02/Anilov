import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anilov/features/splash/presentation/splash_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'has_seen_onboarding': true});
  });

  group('SplashScreen Branding Tests', () {
    testWidgets(
        'renders supplied splash image centered on black background with BoxFit.contain',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );

      // Verify Scaffold has solid black background
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);

      // Verify Center widget is present
      expect(find.byType(Center), findsWidgets);

      // Verify Image widget is configured with supplied anizen_splash.png asset and BoxFit.contain
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final imageWidget = tester.widget<Image>(imageFinder);
      expect(imageWidget.fit, BoxFit.contain);
      expect(imageWidget.image, isA<AssetImage>());
      final assetImage = imageWidget.image as AssetImage;
      expect(assetImage.assetName, 'assets/images/anizen_splash.png');

      // Verify fade-in transition
      expect(
        find.descendant(
          of: find.byType(SplashScreen),
          matching: find.byType(FadeTransition),
        ),
        findsOneWidget,
      );
    });
  });
}
