// Unit tests for EpisodeMetadata (ani.zip enrichment) model

import 'package:flutter_test/flutter_test.dart';
import 'package:anilov/features/anime/domain/models/episode_metadata.dart';
import '../fixtures/anime_fixtures.dart';

void main() {
  group('EpisodeMetadata Model Tests', () {
    test('parses enriched ani.zip JSON with localized title map', () {
      final ep1Json = (sampleAniZipJson['episodes'] as Map)['1'] as Map<String, dynamic>;
      final ep = EpisodeMetadata.fromJson(1, ep1Json);

      expect(ep.episodeNumber, 1);
      expect(ep.title, 'To You, in 2000 Years');
      expect(ep.displayTitle, 'To You, in 2000 Years');
      expect(ep.image, 'https://example.com/ep1.jpg');
      expect(ep.airDate, '2013-04-07');
      expect(ep.runtime, 24);
      expect(ep.overview, contains('Humanity was forced'));
    });

    test('parses plain string title correctly', () {
      final ep = EpisodeMetadata.fromJson(2, {
        'title': 'That Day',
        'runtime': 25,
      });

      expect(ep.episodeNumber, 2);
      expect(ep.title, 'That Day');
      expect(ep.displayTitle, 'That Day');
      expect(ep.runtime, 25);
    });

    test('falls back gracefully to Episode X when title is missing or null', () {
      final ep = EpisodeMetadata.fromJson(7, const {});

      expect(ep.episodeNumber, 7);
      expect(ep.title, isNull);
      expect(ep.displayTitle, 'Episode 7');
      expect(ep.image, isNull);
      expect(ep.overview, isNull);
      expect(ep.airDate, isNull);
      expect(ep.runtime, isNull);
    });

    test('fallback constructor creates safe plain numbered episode', () {
      final fallbackEp = EpisodeMetadata.fallback(12);

      expect(fallbackEp.episodeNumber, 12);
      expect(fallbackEp.title, isNull);
      expect(fallbackEp.displayTitle, 'Episode 12');
    });
  });
}
