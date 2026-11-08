import 'package:flutter_test/flutter_test.dart';
import 'package:anilov/features/anime/domain/models/anime_source.dart';

void main() {
  group('SourceAvailabilityStatus Tests', () {
    test('exposes descriptive display names and policies', () {
      expect(SourceAvailabilityStatus.authorized.displayName, 'Authorized Stream');
      expect(SourceAvailabilityStatus.restrictedEmbedding.displayName,
          'External Playback (SAMEORIGIN)');
      expect(SourceAvailabilityStatus.unauthorizedScraper.displayName,
          'Unauthorized Scraper (Restricted)');
      expect(SourceAvailabilityStatus.unsupported.displayName, 'Unsupported');

      expect(SourceAvailabilityStatus.authorized.description,
          contains('Media3 ExoPlayer'));
      expect(SourceAvailabilityStatus.unauthorizedScraper.description,
          contains('scraping prohibited'));
    });
  });

  group('SourceStreamTrack Tests', () {
    test('creates and serializes HLS track correctly', () {
      const track = SourceStreamTrack(
        label: '1080p (FHD)',
        url: 'https://test-streams.mux.dev/x36xhzz/url_0/1920_1080/index.m3u8',
        type: SourceStreamType.hls,
        bitrate: 5000000,
        headers: {'User-Agent': 'Anilov/1.0.0'},
      );

      final json = track.toJson();
      expect(json['label'], '1080p (FHD)');
      expect(json['url'],
          'https://test-streams.mux.dev/x36xhzz/url_0/1920_1080/index.m3u8');
      expect(json['type'], 'hls');
      expect(json['bitrate'], 5000000);
      expect(json['headers']?['User-Agent'], 'Anilov/1.0.0');

      final reconstructed = SourceStreamTrack.fromJson(json);
      expect(reconstructed.label, '1080p (FHD)');
      expect(reconstructed.url, track.url);
      expect(reconstructed.type, SourceStreamType.hls);
      expect(reconstructed.bitrate, 5000000);
      expect(reconstructed.headers?['User-Agent'], 'Anilov/1.0.0');
    });

    test('SourceStreamTrack.fromJson handles defaults gracefully', () {
      final track = SourceStreamTrack.fromJson({});
      expect(track.label, 'Default');
      expect(track.url, '');
      expect(track.type, SourceStreamType.hls);
      expect(track.bitrate, isNull);
    });
  });

  group('SourceSubtitleTrack Tests', () {
    test('serializes and deserializes subtitle configurations', () {
      const sub = SourceSubtitleTrack(
        label: 'English CC',
        languageCode: 'en',
        url: 'https://test-streams.mux.dev/x36xhzz/url_0/subtitles/en.vtt',
        isDefault: true,
      );

      final json = sub.toJson();
      expect(json['label'], 'English CC');
      expect(json['languageCode'], 'en');
      expect(json['isDefault'], isTrue);

      final reconstructed = SourceSubtitleTrack.fromJson(json);
      expect(reconstructed.label, 'English CC');
      expect(reconstructed.languageCode, 'en');
      expect(reconstructed.url, sub.url);
      expect(reconstructed.isDefault, isTrue);
    });
  });

  group('AnimeSourceEpisode and Season Tests', () {
    test('serializes and deserializes episodes and seasons', () {
      const season = AnimeSourceSeason(
        seasonNumber: 2,
        name: 'Season 2: Entertainment District',
        slug: 'season-2',
        episodesCount: 11,
      );

      final sJson = season.toJson();
      expect(sJson['seasonNumber'], 2);
      expect(sJson['name'], 'Season 2: Entertainment District');

      final sReconstructed = AnimeSourceSeason.fromJson(sJson);
      expect(sReconstructed.seasonNumber, 2);
      expect(sReconstructed.slug, 'season-2');
      expect(sReconstructed.episodesCount, 11);

      const episode = AnimeSourceEpisode(
        episodeNumber: 3,
        title: 'Sound Hashira Tengen Uzui',
        durationSeconds: 1420,
      );

      final epJson = episode.toJson();
      expect(epJson['episodeNumber'], 3);
      expect(epJson['title'], 'Sound Hashira Tengen Uzui');

      final epReconstructed = AnimeSourceEpisode.fromJson(epJson);
      expect(epReconstructed.episodeNumber, 3);
      expect(epReconstructed.durationSeconds, 1420);
    });
  });

  group('EpisodePlaybackInfo Tests', () {
    test('evaluates isDirectPlayable for authorized streams', () {
      const info = EpisodePlaybackInfo(
        episodeNumber: 1,
        episodeTitle: 'Episode 1',
        availability: SourceAvailabilityStatus.authorized,
        streams: [
          SourceStreamTrack(
            label: 'Auto (Adaptive)',
            url: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
          ),
        ],
      );

      expect(info.isDirectPlayable, isTrue);
      expect(info.primaryStream?.label, 'Auto (Adaptive)');
    });

    test('evaluates isDirectPlayable as false for restricted or scraper sources', () {
      const restrictedInfo = EpisodePlaybackInfo(
        episodeNumber: 1,
        episodeTitle: 'Episode 1',
        availability: SourceAvailabilityStatus.restrictedEmbedding,
        externalWatchUrl: 'https://anikoto.cz/watch/solo-leveling/ep-1',
      );

      expect(restrictedInfo.isDirectPlayable, isFalse);
      expect(restrictedInfo.primaryStream, isNull);

      const scraperInfo = EpisodePlaybackInfo(
        episodeNumber: 1,
        episodeTitle: 'Episode 1',
        availability: SourceAvailabilityStatus.unauthorizedScraper,
      );

      expect(scraperInfo.isDirectPlayable, isFalse);
    });
  });
}
