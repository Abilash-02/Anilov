import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anilov/core/theme/app_theme.dart';

void main() {
  group('AppTheme Tests', () {
    test('Dark theme configured properly with Material 3', () {
      final darkTheme = AppTheme.darkTheme;

      expect(darkTheme.useMaterial3, isTrue);
      expect(darkTheme.brightness, Brightness.dark);
      expect(darkTheme.scaffoldBackgroundColor, AppTheme.darkBackground);
      expect(darkTheme.colorScheme.primary, AppTheme.violet);
      expect(darkTheme.colorScheme.primaryContainer, AppTheme.deepIndigo);
      expect(darkTheme.materialTapTargetSize, MaterialTapTargetSize.padded);
    });

    test('Light theme configured properly with Material 3', () {
      final lightTheme = AppTheme.lightTheme;

      expect(lightTheme.useMaterial3, isTrue);
      expect(lightTheme.brightness, Brightness.light);
      expect(lightTheme.scaffoldBackgroundColor, AppTheme.lightBackground);
      expect(lightTheme.materialTapTargetSize, MaterialTapTargetSize.padded);
    });

    test('Button touch targets satisfy accessible minimum of 48dp', () {
      final darkTheme = AppTheme.darkTheme;
      final filledBtnStyle = darkTheme.filledButtonTheme.style;
      final minSize = filledBtnStyle?.minimumSize?.resolve({});

      expect(minSize, isNotNull);
      expect(minSize!.width, greaterThanOrEqualTo(48.0));
      expect(minSize.height, greaterThanOrEqualTo(48.0));
    });

    test('Card theme radius is rounded to 16dp', () {
      final darkTheme = AppTheme.darkTheme;
      final cardShape = darkTheme.cardTheme.shape as RoundedRectangleBorder?;

      expect(cardShape, isNotNull);
      expect(cardShape!.borderRadius, BorderRadius.circular(16.0));
    });
  });
}
