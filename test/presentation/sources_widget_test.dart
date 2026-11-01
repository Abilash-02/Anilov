// Unit and widget tests for PlaybackSource and LinkEvaluationResult

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anilov/core/theme/app_theme.dart';
import 'package:anilov/features/anime/domain/models/playback_source.dart';
import 'package:anilov/features/anime/presentation/widgets/trailer_player_dialog.dart';

void main() {
  group('LinkEvaluationResult Tests (User Link Evaluation)', () {
    test('evaluates https://share.google/0XKcrS1PHQZW2NgkN safely without scraping', () {
      const targetUrl = 'https://share.google/0XKcrS1PHQZW2NgkN';
      final result = LinkEvaluationResult.evaluate(targetUrl);

      expect(result.url, targetUrl);
      expect(result.isDirectVideoUrl, isFalse);
      expect(result.isAuthorizedApi, isFalse);
      expect(result.requiresExternalApp, isTrue);
      expect(result.description, contains('Google Cloud Shared Link'));
      expect(result.policyNotice, contains('does not scrape web pages'));
      expect(result.policyNotice, contains('bypass Google authentication/DRM'));
    });

    test('evaluates official YouTube link as authorized player', () {
      const ytUrl = 'https://www.youtube.com/watch?v=MGRm4IzK1SQ';
      final result = LinkEvaluationResult.evaluate(ytUrl);

      expect(result.isAuthorizedApi, isTrue);
      expect(result.requiresExternalApp, isFalse);
      expect(result.description, 'Official YouTube Trailer');
    });

    test('evaluates generic web links as external-only', () {
      const genericUrl = 'https://example.com/anime';
      final result = LinkEvaluationResult.evaluate(genericUrl);

      expect(result.isDirectVideoUrl, isFalse);
      expect(result.requiresExternalApp, isTrue);
      expect(result.description, contains('External Web Link'));
    });
  });

  group('ExternalLinkNoticeDialog Widget Tests', () {
    testWidgets('renders link policy explanation and open button', (tester) async {
      final evaluation = LinkEvaluationResult.evaluate('https://share.google/0XKcrS1PHQZW2NgkN');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: ExternalLinkNoticeDialog(evaluation: evaluation),
          ),
        ),
      );

      expect(find.textContaining('Google Cloud Shared Link'), findsOneWidget);
      expect(find.textContaining('does not scrape web pages'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Open in Browser'), findsOneWidget);
    });
  });
}
