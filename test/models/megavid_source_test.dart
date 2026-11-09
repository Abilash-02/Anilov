import 'package:flutter_test/flutter_test.dart';
import 'package:anilov/features/anime/data/providers/megavid_source_provider.dart';
import 'package:anilov/features/anime/domain/models/anime_media.dart';
import 'package:anilov/features/anime/domain/models/anime_source.dart';
import 'package:anilov/features/anime/domain/models/playback_provider.dart';

void main() {
  const blueBoxAnime = AnimeMedia(
    id: 170942,
    title: AnimeTitle(
      romaji: 'Ao no Hako',
      english: 'Blue Box',
      native: 'アオのハコ',
    ),
    coverImage: AnimeCover(
      extraLarge: 'https://example.com/blue_box.jpg',
      large: 'https://example.com/blue_box.jpg',
    ),
    format: 'TV',
    status: 'RELEASING',
    episodes: 25,
  );

  const otherAnime = AnimeMedia(
    id: 16498,
    title: AnimeTitle(
      romaji: 'Shingeki no Kyojin',
      english: 'Attack on Titan',
    ),
    coverImage: AnimeCover(
      extraLarge: 'https://example.com/aot.jpg',
      large: 'https://example.com/aot.jpg',
    ),
    format: 'TV',
    status: 'FINISHED',
    episodes: 25,
  );

  group('MegavidSourceProvider Mapping Tests', () {
    test('strictly associates source URL with Blue Box Season 1 Episode 1', () {
      expect(
        MegavidSourceProvider.isBlueBoxS01E01(
          animeId: 170942,
          season: 1,
          episode: 1,
        ),
        isTrue,
      );

      final url = MegavidSourceProvider.getSourceUrl(
        animeId: 170942,
        season: 1,
        episode: 1,
      );
      expect(url, 'https://megavid.buzz/ani/170942/1/sub');
    });

    test('preserves original source URL identically without modification', () {
      const expectedUrl = 'https://megavid.buzz/ani/170942/1/sub';
      expect(MegavidSourceProvider.blueBoxS01E01Url, expectedUrl);
      expect(
        MegavidSourceProvider.getSourceUrl(
          animeId: blueBoxAnime.id,
          title: blueBoxAnime.title.displayTitle,
          season: 1,
          episode: 1,
        ),
        expectedUrl,
      );
    });

    test('matches Blue Box by title variants (English and Romaji)', () {
      expect(
        MegavidSourceProvider.isBlueBoxS01E01(
          animeId: 999999, // custom ID with title
          title: 'Blue Box (TV)',
          season: 1,
          episode: 1,
        ),
        isTrue,
      );

      expect(
        MegavidSourceProvider.isBlueBoxS01E01(
          animeId: 999999,
          title: 'Ao no Hako: Season 1',
          season: 1,
          episode: 1,
        ),
        isTrue,
      );
    });

    test('does NOT associate with Blue Box Season 1 Episode 2 or other episodes', () {
      expect(
        MegavidSourceProvider.isBlueBoxS01E01(
          animeId: 170942,
          season: 1,
          episode: 2,
        ),
        isFalse,
      );

      expect(
        MegavidSourceProvider.getSourceUrl(
          animeId: 170942,
          season: 1,
          episode: 2,
        ),
        isNull,
      );

      expect(
        MegavidSourceProvider.isBlueBoxS01E01(
          animeId: 170942,
          season: 2,
          episode: 1,
        ),
        isFalse,
      );
    });

    test('does NOT associate with other anime titles', () {
      expect(
        MegavidSourceProvider.isBlueBox(otherAnime),
        isFalse,
      );

      expect(
        MegavidSourceProvider.isBlueBoxS01E01(
          animeId: otherAnime.id,
          title: otherAnime.title.displayTitle,
          season: 1,
          episode: 1,
        ),
        isFalse,
      );

      expect(
        MegavidSourceProvider.getSourceUrl(
          animeId: otherAnime.id,
          title: otherAnime.title.displayTitle,
          season: 1,
          episode: 1,
        ),
        isNull,
      );
    });
  });

  group('MegavidPlaybackEvaluation & Security Compliance Tests', () {
    test('evaluates URL confirming in-app browser permission and no direct Media3 claim', () {
      const url = 'https://megavid.buzz/ani/170942/1/sub';
      final evaluation = MegavidPlaybackEvaluation.evaluate(url);

      expect(evaluation.url, url);
      // Requirement 8: Do not claim native Media3 playback unless an officially supported stream is available
      expect(evaluation.isDirectMedia3Supported, isFalse);
      // Requirement 5 & 6: Provider permits opening URL inside Anilov via in-app browser
      expect(evaluation.canOpenInAppBrowser, isTrue);
      expect(evaluation.statusDescription, contains('In-App Browser Supported'));
      // Requirement 7: Do not extract hidden video URLs or bypass Cloudflare/DRM
      expect(evaluation.policyNotice, contains('without scraping hidden video streams'));
      expect(evaluation.policyNotice, contains('Cloudflare/DRM'));
    });

    test('evaluates non-megavid URL safely', () {
      final evaluation = MegavidPlaybackEvaluation.evaluate('https://example.com/anime');
      expect(evaluation.canOpenInAppBrowser, isFalse);
      expect(evaluation.isDirectMedia3Supported, isFalse);
    });
  });

  group('MegavidSourceProvider AnimeSourceProvider Contract Tests', () {
    final provider = MegavidSourceProvider();

    test('exposes provider metadata and non-direct stream capability', () {
      expect(provider.id, 'megavid');
      expect(provider.name, 'MegaVid');
      expect(provider.availability, SourceAvailabilityStatus.restrictedEmbedding);
      expect(provider.canStreamInApp, isFalse);
    });

    test('searches anime catalogue returning Blue Box for relevant queries', () async {
      final blueBoxResults = await provider.searchAnime('Blue Box');
      expect(blueBoxResults, isNotEmpty);
      expect(blueBoxResults.first.id, 170942);
      expect(blueBoxResults.first.title.english, 'Blue Box');

      final romajiResults = await provider.searchAnime('Ao no Hako');
      expect(romajiResults, isNotEmpty);
      expect(romajiResults.first.id, 170942);

      final otherResults = await provider.searchAnime('Attack on Titan');
      expect(otherResults, isEmpty);
    });

    test('retrieves anime details by identifier', () async {
      final byId = await provider.getAnimeDetails('170942');
      expect(byId, isNotNull);
      expect(byId!.id, 170942);

      final notFound = await provider.getAnimeDetails('999999');
      expect(notFound, isNull);
    });

    test('discovers seasons for Blue Box and rejects other anime', () async {
      final seasons = await provider.getSeasons(blueBoxAnime);
      expect(seasons, isNotEmpty);
      expect(seasons.first.seasonNumber, 1);
      expect(seasons.first.episodesCount, 25);

      final otherSeasons = await provider.getSeasons(otherAnime);
      expect(otherSeasons, isEmpty);
    });

    test('discovers episodes with S01E01 mapped to MegaVid sourceIdentifier', () async {
      final episodes = await provider.getEpisodes(blueBoxAnime);
      expect(episodes.length, 25);

      final ep1 = episodes.first;
      expect(ep1.episodeNumber, 1);
      expect(ep1.sourceIdentifier, 'https://megavid.buzz/ani/170942/1/sub');

      final ep2 = episodes[1];
      expect(ep2.episodeNumber, 2);
      expect(ep2.sourceIdentifier, isNull);

      final otherEpisodes = await provider.getEpisodes(otherAnime);
      expect(otherEpisodes, isEmpty);
    });

    test('resolves playback info: restrictedEmbedding for S01E01, unsupported for other episodes', () async {
      final ep1Playback = await provider.getEpisodePlayback(blueBoxAnime, 1);
      expect(ep1Playback.episodeNumber, 1);
      expect(ep1Playback.availability, SourceAvailabilityStatus.restrictedEmbedding);
      expect(ep1Playback.isDirectPlayable, isFalse);
      expect(ep1Playback.externalWatchUrl, 'https://megavid.buzz/ani/170942/1/sub');
      expect(ep1Playback.notice, contains('MegaVid source link mapped for Blue Box Season 1 Episode 1'));

      final ep2Playback = await provider.getEpisodePlayback(blueBoxAnime, 2);
      expect(ep2Playback.episodeNumber, 2);
      expect(ep2Playback.availability, SourceAvailabilityStatus.unsupported);
      expect(ep2Playback.externalWatchUrl, isNull);
      expect(ep2Playback.notice, contains('only mapped for Blue Box Season 1 Episode 1'));

      final otherPlayback = await provider.getEpisodePlayback(otherAnime, 1);
      expect(otherPlayback.availability, SourceAvailabilityStatus.unsupported);
    });

    test('PlaybackProviderType.megavid enum exposes valid display properties', () {
      expect(PlaybackProviderType.megavid.displayName, 'MegaVid');
      expect(PlaybackProviderType.megavid.description, contains('megavid.buzz'));
    });
  });
}
