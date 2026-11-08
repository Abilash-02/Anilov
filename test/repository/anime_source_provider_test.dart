import 'package:flutter_test/flutter_test.dart';
import 'package:anilov/features/anime/data/providers/anikoto_source_provider.dart';
import 'package:anilov/features/anime/data/providers/authorized_anime_source_provider.dart';
import 'package:anilov/features/anime/data/providers/fetch_kickass_source_provider.dart';
import 'package:anilov/features/anime/data/providers/local_media_source_provider.dart';
import 'package:anilov/features/anime/domain/models/anime_media.dart';
import 'package:anilov/features/anime/domain/models/anime_source.dart';
import '../fixtures/anime_fixtures.dart';

void main() {
  final sampleAnime = AnimeMedia.fromJson(sampleAnimeJson);

  group('AuthorizedAnimeSourceProvider Tests', () {
    final provider = AuthorizedAnimeSourceProvider();

    test('verifies provider properties and streaming capability', () {
      expect(provider.id, 'authorized_open_stream');
      expect(provider.name, 'Authorized Anime Stream');
      expect(provider.availability, SourceAvailabilityStatus.authorized);
      expect(provider.canStreamInApp, isTrue);
    });

    test('searches curated authorized open anime catalog', () async {
      final results = await provider.searchAnime('Sintel');
      expect(results, isNotEmpty);
      expect(results.first.title.displayTitle, contains('Sintel'));

      final empty = await provider.searchAnime('NonExistentTitleXYZ');
      expect(empty, isEmpty);
    });

    test('retrieves anime details and metadata by id and title', () async {
      final byId = await provider.getAnimeDetails('99001');
      expect(byId, isNotNull);
      expect(byId!.title.displayTitle, contains('Sintel'));
      expect(byId.episodes, 1);

      final byTitle = await provider.getAnimeDetails('Tears of Steel: Cyberpunk Tokyo');
      expect(byTitle, isNotNull);
      expect(byTitle!.episodes, 12);

      final notFound = await provider.getAnimeDetails('Unknown99999');
      expect(notFound, isNull);
    });

    test('discovers seasons and generates episode listings', () async {
      final seasons = await provider.getSeasons(sampleAnime);
      expect(seasons, isNotEmpty);
      expect(seasons.first.seasonNumber, 1);

      final episodes = await provider.getEpisodes(sampleAnime);
      expect(episodes.length, sampleAnime.episodes ?? 12);
      expect(episodes.first.episodeNumber, 1);
      expect(episodes.first.title, 'Episode 1');
    });

    test('resolves full playback info with multi-bitrate HLS and subtitles', () async {
      final playback = await provider.getEpisodePlayback(sampleAnime, 1);

      expect(playback.episodeNumber, 1);
      expect(playback.availability, SourceAvailabilityStatus.authorized);
      expect(playback.isDirectPlayable, isTrue);
      expect(playback.streams.length, greaterThanOrEqualTo(3));

      // Quality tracks: Auto, 1080p, 720p, 360p
      final labels = playback.streams.map((s) => s.label).toList();
      expect(labels, contains('Auto (Adaptive)'));
      expect(labels, contains('1080p (FHD)'));
      expect(labels, contains('720p (HD)'));
      expect(labels, contains('360p (SD)'));

      // Subtitles: English, Japanese
      expect(playback.subtitles.length, greaterThanOrEqualTo(2));
      expect(playback.subtitles.any((s) => s.languageCode == 'en'), isTrue);
    });
  });

  group('AnikotoSourceProvider Tests', () {
    final provider = AnikotoSourceProvider();

    test('verifies provider properties and SAMEORIGIN policy', () {
      expect(provider.id, 'anikoto');
      expect(provider.name, 'AniKoto');
      expect(provider.availability, SourceAvailabilityStatus.restrictedEmbedding);
      expect(provider.canStreamInApp, isFalse);
    });

    test('resolves episode playback with external browser URL and notice', () async {
      final playback = await provider.getEpisodePlayback(sampleAnime, 1);

      expect(playback.episodeNumber, 1);
      expect(playback.availability, SourceAvailabilityStatus.restrictedEmbedding);
      expect(playback.isDirectPlayable, isFalse);
      expect(playback.externalWatchUrl, isNotNull);
      expect(playback.notice, contains('X-Frame-Options: SAMEORIGIN'));
      expect(playback.notice, contains('hidden stream URLs are not scraped'));
    });
  });

  group('FetchKickassSourceProvider Tests', () {
    final provider = FetchKickassSourceProvider();

    test('verifies provider properties and scraper restriction status', () {
      expect(provider.id, 'fetch_kickass');
      expect(provider.name, 'Fetch (KickassAnime)');
      expect(provider.availability, SourceAvailabilityStatus.unauthorizedScraper);
      expect(provider.canStreamInApp, isFalse);
    });

    test('searchAnime returns empty without scraping', () async {
      final results = await provider.searchAnime('Naruto');
      expect(results, isEmpty);
    });

    test('resolves playback info with detailed Fetch analysis and limitation notice', () async {
      final playback = await provider.getEpisodePlayback(sampleAnime, 1);

      expect(playback.episodeNumber, 1);
      expect(playback.availability, SourceAvailabilityStatus.unauthorizedScraper);
      expect(playback.isDirectPlayable, isFalse);
      expect(playback.notice, contains('Fetch (github.com/snehilrx/Fetch)'));
      expect(playback.notice, contains('player.php'));
      expect(playback.notice, contains('CustomWebView'));
      expect(playback.notice, contains('Cloudflare'));
      expect(playback.notice, contains('Authorized Anime Stream'));
    });
  });

  group('LocalMediaSourceProvider Tests', () {
    final provider = LocalMediaSourceProvider();

    test('verifies provider properties and local playback capability', () {
      expect(provider.id, 'local_player');
      expect(provider.name, 'Local Media & Direct Stream');
      expect(provider.canStreamInApp, isTrue);
    });

    test('getSeasons and getEpisodes construct local entries', () async {
      final seasons = await provider.getSeasons(sampleAnime);
      expect(seasons.length, 1);
      expect(seasons.first.name, 'Local Collection');

      final episodes = await provider.getEpisodes(sampleAnime);
      expect(episodes.isNotEmpty, isTrue);
    });
  });
}
