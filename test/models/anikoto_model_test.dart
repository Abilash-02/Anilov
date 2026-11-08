import 'package:flutter_test/flutter_test.dart';
import 'package:anilov/features/anime/domain/models/playback_provider.dart';

void main() {
  group('AnikotoSeason Tests', () {
    test('creates AnikotoSeason and serializes/deserializes correctly', () {
      const season = AnikotoSeason(
        seasonNumber: 1,
        name: 'Season 1',
        slug: 'attack-on-titan-bgaoa',
        bannerUrl: 'https://cdn.anipixcdn.co/banner.jpg',
        episodesCount: 25,
      );

      final json = season.toJson();
      expect(json['seasonNumber'], 1);
      expect(json['name'], 'Season 1');
      expect(json['slug'], 'attack-on-titan-bgaoa');
      expect(json['bannerUrl'], 'https://cdn.anipixcdn.co/banner.jpg');
      expect(json['episodesCount'], 25);

      final deserialized = AnikotoSeason.fromJson(json);
      expect(deserialized.seasonNumber, 1);
      expect(deserialized.name, 'Season 1');
      expect(deserialized.slug, 'attack-on-titan-bgaoa');
      expect(deserialized.bannerUrl, 'https://cdn.anipixcdn.co/banner.jpg');
      expect(deserialized.episodesCount, 25);
    });

    test('AnikotoSeason.fromJson handles null and missing fields gracefully', () {
      final season = AnikotoSeason.fromJson({});
      expect(season.seasonNumber, 1);
      expect(season.name, 'Season 1');
      expect(season.slug, '');
      expect(season.bannerUrl, isNull);
      expect(season.episodesCount, isNull);
    });
  });

  group('AnikotoEpisode Tests', () {
    test('creates AnikotoEpisode and verifies watch URL', () {
      const episode = AnikotoEpisode(
        episodeNumber: 5,
        title: 'Episode 5',
        slug: 'solo-leveling-ilh08',
        watchUrl: 'https://anikoto.cz/watch/solo-leveling-ilh08/ep-5',
      );

      expect(episode.episodeNumber, 5);
      expect(episode.watchUrl, 'https://anikoto.cz/watch/solo-leveling-ilh08/ep-5');

      final json = episode.toJson();
      final reconstructed = AnikotoEpisode.fromJson(json);
      expect(reconstructed.episodeNumber, 5);
      expect(reconstructed.slug, 'solo-leveling-ilh08');
      expect(reconstructed.watchUrl, 'https://anikoto.cz/watch/solo-leveling-ilh08/ep-5');
    });
  });

  group('AnikotoShowDetails Tests', () {
    test('buildEpisodeUrl constructs proper watch link with season slug fallback', () {
      const show = AnikotoShowDetails(
        tipId: 1631,
        title: 'Attack on Titan',
        slug: 'attack-on-titan-bgaoa',
        totalEpisodes: 25,
        seasons: [
          AnikotoSeason(
            seasonNumber: 1,
            name: 'Season 1',
            slug: 'attack-on-titan-bgaoa',
            episodesCount: 25,
          ),
          AnikotoSeason(
            seasonNumber: 2,
            name: 'Season 2',
            slug: 'attack-on-titan-season-2-0rtbh',
            episodesCount: 12,
          ),
        ],
      );

      // Default slug
      expect(
        show.buildEpisodeUrl(1),
        'https://anikoto.cz/watch/attack-on-titan-bgaoa/ep-1',
      );

      // Explicit season 2 slug
      expect(
        show.buildEpisodeUrl(3, seasonSlug: 'attack-on-titan-season-2-0rtbh'),
        'https://anikoto.cz/watch/attack-on-titan-season-2-0rtbh/ep-3',
      );

      expect(show.primarySeason.name, 'Season 1');
      expect(show.primarySeason.slug, 'attack-on-titan-bgaoa');
    });

    test('primarySeason returns fallback when seasons list is empty', () {
      const show = AnikotoShowDetails(
        title: 'Solo Leveling',
        slug: 'solo-leveling-ilh08',
        totalEpisodes: 12,
      );

      expect(show.primarySeason.seasonNumber, 1);
      expect(show.primarySeason.name, 'Season 1');
      expect(show.primarySeason.slug, 'solo-leveling-ilh08');
    });
  });

  group('AnikotoPlaybackEvaluation & Policy Compliance Tests', () {
    test('evaluates AniKoto URL enforcing SAMEORIGIN and external browser policy', () {
      const watchUrl = 'https://anikoto.cz/watch/attack-on-titan-bgaoa/ep-1';
      final evaluation = AnikotoPlaybackEvaluation.evaluate(watchUrl);

      expect(evaluation.url, watchUrl);
      expect(evaluation.isEmbeddingPermitted, isFalse);
      expect(evaluation.xFrameOptions, 'SAMEORIGIN');
      expect(evaluation.canOpenInBrowser, isTrue);
      expect(evaluation.officialWatchUrl, watchUrl);
      expect(evaluation.policyNotice, contains('X-Frame-Options: SAMEORIGIN'));
      expect(evaluation.policyNotice, contains('does not provide an authorized third-party iframe embed API'));
      expect(evaluation.policyNotice, contains('hidden stream URLs are not scraped'));
    });

    test('PlaybackProviderType enum exposes valid display properties', () {
      expect(PlaybackProviderType.anikoto.displayName, 'AniKoto');
      expect(PlaybackProviderType.localPlayer.displayName, 'Local Player');
      expect(PlaybackProviderType.anikoto.description, contains('anikoto.cz'));
      expect(PlaybackProviderType.localPlayer.description, contains('offline local media'));
    });
  });
}
