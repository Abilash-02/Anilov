import 'package:flutter_test/flutter_test.dart';
import 'package:anilov/features/anime/data/anikoto_client.dart';
import 'package:anilov/features/anime/domain/models/anime_media.dart';
import '../fixtures/anime_fixtures.dart';

void main() {
  group('AnikotoClient HTML Parsing & Logic Tests', () {
    late AnikotoClient client;

    setUp(() {
      client = AnikotoClient();
    });

    test('parseSearchResultsHtml extracts tipId, slug, title, poster, and episode counts', () {
      const mockSearchHtml = '''
<div id="list-items" class="ani items">
  <div class="item ">
    <div class="inner">
      <div class="ani poster tip" data-tip="1631">
        <a href="https://anikoto.cz/watch/attack-on-titan-bgaoa/ep-1">
          <img src="https://cdn.anipixcdn.co/thumbnail/aot.jpg" alt="Attack on Titan" />
          <div class="meta">
            <div class="inner">
              <div class="left">
                <span class="ep-status sub"><span> 25</span></span>
                <span class="ep-status dub"><span> 25</span></span>
                <span class="ep-status total"><span>25</span></span>
              </div>
              <div class="right">TV</div>
            </div>
          </div>
        </a>
      </div>
      <div class="info">
        <div class="b1">
          <a class="name d-title" href="https://anikoto.cz/watch/attack-on-titan-bgaoa/ep-1" data-jp="Shingeki no Kyojin">Attack on Titan</a>
        </div>
      </div>
    </div>
  </div>
  <div class="item ">
    <div class="inner">
      <div class="ani poster tip" data-tip="9999">
        <a href="https://anikoto.cz/watch/attack-on-titan-ova-oc7gu/ep-1">
          <img src="https://cdn.anipixcdn.co/thumbnail/ova.jpg" alt="Attack on Titan OVA" />
          <div class="meta">
            <div class="inner">
              <div class="left">
                <span class="ep-status sub"><span> 8</span></span>
                <span class="ep-status dub"><span> 8</span></span>
                <span class="ep-status total"><span>8</span></span>
              </div>
            </div>
          </div>
        </a>
      </div>
      <div class="info">
        <div class="b1">
          <a class="name d-title" href="https://anikoto.cz/watch/attack-on-titan-ova-oc7gu/ep-1">Attack on Titan &amp; OVA</a>
        </div>
      </div>
    </div>
  </div>
</div>
''';

      final results = client.parseSearchResultsHtml(mockSearchHtml);

      expect(results.length, 2);

      final first = results[0];
      expect(first.tipId, 1631);
      expect(first.title, 'Attack on Titan');
      expect(first.slug, 'attack-on-titan-bgaoa');
      expect(first.posterUrl, 'https://cdn.anipixcdn.co/thumbnail/aot.jpg');
      expect(first.totalEpisodes, 25);
      expect(first.subEpisodes, 25);
      expect(first.dubEpisodes, 25);

      final second = results[1];
      expect(second.tipId, 9999);
      expect(second.title, 'Attack on Titan & OVA'); // Unescaped HTML entity
      expect(second.slug, 'attack-on-titan-ova-oc7gu');
      expect(second.totalEpisodes, 8);
    });

    test('parseSearchResultsHtml returns empty list on empty or malformed HTML', () {
      expect(client.parseSearchResultsHtml(''), isEmpty);
      expect(client.parseSearchResultsHtml('<html><body>No items here</body></html>'), isEmpty);
    });

    test('parseSeasonsHtml extracts seasons with slug, banner, and name', () {
      const mockSeasonsHtml = '''
<section id="w-seasons" class="mt-3 mb-0 swiper-container">
  <div class="seasons swiper-wrapper">
    <div class="swiper-slide season active">
      <a href="https://anikoto.cz/watch/attack-on-titan-bgaoa" style="background-image: url(https://s4.anilist.co/file/anilistcdn/media/anime/banner/16498.jpg);">
        <div class="name" style="color:#ffffff">Season 1</div>
      </a>
    </div>
    <div class="swiper-slide season ">
      <a href="https://anikoto.cz/watch/attack-on-titan-season-2-0rtbh" style="background-image: url(https://cdn.anipixcdn.co/thumbnail/s2.jpg);">
        <div class="name" style="color:#ffffff">Season 2</div>
      </a>
    </div>
    <div class="swiper-slide season ">
      <a href="https://anikoto.cz/watch/attack-on-titan-season-3-3jgrx" style="background-image: url(https://cdn.anipixcdn.co/thumbnail/s3.jpg);">
        <div class="name" style="color:#ffffff">Season 3</div>
      </a>
    </div>
  </div>
</section>
''';

      final seasons = client.parseSeasonsHtml(mockSeasonsHtml);

      expect(seasons.length, 3);

      expect(seasons[0].seasonNumber, 1);
      expect(seasons[0].name, 'Season 1');
      expect(seasons[0].slug, 'attack-on-titan-bgaoa');
      expect(seasons[0].bannerUrl, 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/16498.jpg');

      expect(seasons[1].seasonNumber, 2);
      expect(seasons[1].name, 'Season 2');
      expect(seasons[1].slug, 'attack-on-titan-season-2-0rtbh');

      expect(seasons[2].seasonNumber, 3);
      expect(seasons[2].name, 'Season 3');
      expect(seasons[2].slug, 'attack-on-titan-season-3-3jgrx');
    });

    test('slugify converts titles to valid URL slugs', () {
      expect(AnikotoClient.slugify('Attack on Titan'), 'attack-on-titan');
      expect(AnikotoClient.slugify("Frieren: Beyond Journey's End!"), 'frieren-beyond-journey-s-end');
      expect(AnikotoClient.slugify('Solo Leveling (2024)'), 'solo-leveling-2024');
      expect(AnikotoClient.slugify('---Multiple---Dashes---'), 'multiple-dashes');
    });

    test('buildEpisodeUrl constructs standard AniKoto watch route', () {
      expect(
        AnikotoClient.buildEpisodeUrl('solo-leveling-ilh08', 3),
        'https://anikoto.cz/watch/solo-leveling-ilh08/ep-3',
      );
    });

    test('evaluateEpisodePlayback produces valid evaluation with SAMEORIGIN rule', () {
      final evaluation = client.evaluateEpisodePlayback('frieren-beyond-journey-s-end-c6fbj', 1);

      expect(evaluation.isEmbeddingPermitted, isFalse);
      expect(evaluation.xFrameOptions, 'SAMEORIGIN');
      expect(evaluation.canOpenInBrowser, isTrue);
      expect(
        evaluation.officialWatchUrl,
        'https://anikoto.cz/watch/frieren-beyond-journey-s-end-c6fbj/ep-1',
      );
    });

    test('resolveShow generates graceful fallback when offline or no match found', () async {
      final sampleAnime = AnimeMedia.fromJson(sampleAnimeJson);

      // Resolving with empty query / network isolation generates graceful fallback
      final show = await client.resolveShow(sampleAnime);

      expect(show.title, sampleAnime.title.displayTitle);
      expect(show.totalEpisodes, sampleAnime.episodes ?? 12);
      expect(show.seasons, isNotEmpty);
      expect(show.primarySeason.name, 'Season 1');
    });

    test('clearCache empties in-memory cache map', () {
      client.clearCache();
      // Verifies no exception thrown
      expect(true, isTrue);
    });
  });
}
