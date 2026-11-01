import 'package:flutter_test/flutter_test.dart';
import 'package:anilov/features/anime/domain/models/anime_media.dart';
import '../fixtures/anime_fixtures.dart';

void main() {
  group('AnimeMedia JSON Model Tests', () {
    test('parses full AnimeMedia correctly', () {
      final anime = AnimeMedia.fromJson(sampleAnimeJson);

      expect(anime.id, 16498);
      expect(anime.idMal, 16498);
      expect(anime.title.english, 'Attack on Titan');
      expect(anime.title.displayTitle, 'Attack on Titan');
      expect(anime.format, 'TV');
      expect(anime.displayFormat, 'TV Series');
      expect(anime.status, 'FINISHED');
      expect(anime.seasonYear, 2013);
      expect(anime.episodes, 25);
      expect(anime.averageScore, 85);
      expect(anime.displayScore, '85%');
      expect(anime.studio, 'WIT Studio');
      expect(anime.genres, contains('Action'));
      expect(anime.trailer, isNotNull);
      expect(anime.trailer!.isYouTube, isTrue);
      expect(anime.trailer!.youtubeUrl, 'https://www.youtube.com/watch?v=MGRm4IzK1SQ');
      expect(anime.trailer!.thumbnailUrl, 'https://img.youtube.com/vi/MGRm4IzK1SQ/hqdefault.jpg');
      expect(anime.externalLinks.length, 2);
      expect(anime.externalLinks.first.site, 'Crunchyroll');
      expect(anime.relations.length, 1);
      expect(anime.relations.first.relationType, 'SEQUEL');
      expect(anime.relations.first.title, 'Attack on Titan Season 2');
    });

    test('strips HTML tags and clean description properly', () {
      final anime = AnimeMedia.fromJson(sampleAnimeJson);
      expect(anime.cleanDescription, contains('Centuries ago, mankind was almost slaughtered...'));
      expect(anime.cleanDescription, contains('Enter Eren!'));
      expect(anime.cleanDescription, isNot(contains('<br>')));
      expect(anime.cleanDescription, isNot(contains('<b>')));
    });

    test('parses AnimeMedia with null and missing fields safely without throwing', () {
      final anime = AnimeMedia.fromJson(sampleAnimeWithNullsJson);

      expect(anime.id, 99999);
      expect(anime.title.displayTitle, 'Untitled');
      expect(anime.coverImage.displayUrl, isNull);
      expect(anime.cleanDescription, 'No synopsis available.');
      expect(anime.displayFormat, 'Anime');
      expect(anime.displayScore, isNull);
      expect(anime.studio, isNull);
      expect(anime.genres, isEmpty);
      expect(anime.trailer, isNull);
      expect(anime.externalLinks, isEmpty);
      expect(anime.relations, isEmpty);
    });

    test('displayTitle falls back gracefully across languages', () {
      const romajiOnly = AnimeTitle(romaji: 'Kimetsu no Yaiba');
      expect(romajiOnly.displayTitle, 'Kimetsu no Yaiba');

      const nativeOnly = AnimeTitle(native: '鬼滅の刃');
      expect(nativeOnly.displayTitle, '鬼滅の刃');

      const empty = AnimeTitle();
      expect(empty.displayTitle, 'Untitled');
    });

    test('PaginatedAnime parses Page and pageInfo correctly', () {
      final paginated = PaginatedAnime.fromJson(samplePageJson);

      expect(paginated.pageInfo.total, 120);
      expect(paginated.pageInfo.currentPage, 1);
      expect(paginated.pageInfo.hasNextPage, isTrue);
      expect(paginated.items.length, 1);
      expect(paginated.items.first.id, 16498);
    });
  });
}
