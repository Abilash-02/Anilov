import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:anilov/features/anime/data/anilist_client.dart';
import 'package:anilov/features/anime/data/anilist_repository_impl.dart';
import '../fixtures/anime_fixtures.dart';

class MockDio extends Mock implements Dio {}
class MockAniListClient extends Mock implements AniListClient {}

void main() {
  group('AniListRepositoryImpl Tests', () {
    late MockAniListClient mockClient;
    late AniListRepositoryImpl repository;

    setUp(() {
      mockClient = MockAniListClient();
      repository = AniListRepositoryImpl(client: mockClient);
    });

    test('getTrendingAnime parses returned Media array', () async {
      when(() => mockClient.postQuery(any(), variables: any(named: 'variables')))
          .thenAnswer((_) async => samplePageJson);

      final list = await repository.getTrendingAnime(page: 1, perPage: 10);

      expect(list.length, 1);
      expect(list.first.id, 16498);
      expect(list.first.title.displayTitle, 'Attack on Titan');
    });

    test('getAnimeDetails parses single Media query response', () async {
      when(() => mockClient.postQuery(any(), variables: any(named: 'variables')))
          .thenAnswer((_) async => {'Media': sampleAnimeJson});

      final details = await repository.getAnimeDetails(16498);

      expect(details.id, 16498);
      expect(details.episodes, 25);
      expect(details.studio, 'WIT Studio');
      expect(details.relations.length, 1);
    });

    test('searchAnime returns paginated list of AnimeMedia', () async {
      when(() => mockClient.postQuery(any(), variables: any(named: 'variables')))
          .thenAnswer((_) async => samplePageJson);

      final result = await repository.searchAnime(query: 'Attack', genre: 'Action');

      expect(result.items.length, 1);
      expect(result.pageInfo.total, 120);
      expect(result.pageInfo.hasNextPage, isTrue);
    });

    test('getGenres returns non-empty static list', () async {
      final genres = await repository.getGenres();
      expect(genres, contains('Action'));
      expect(genres, contains('Romance'));
      expect(genres, contains('Sci-Fi'));
    });
  });

  group('AniListClient Caching & Rate-Limit Tests', () {
    late MockDio mockDio;
    late AniListClient client;

    setUp(() {
      mockDio = MockDio();
      client = AniListClient(dio: mockDio);
    });

    test('caches responses and avoids duplicate network requests', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: {'data': samplePageJson},
        ),
      );

      // First call
      final res1 = await client.postQuery('query { test }', variables: {'id': 1});
      expect(res1, isNotEmpty);

      // Second identical call
      final res2 = await client.postQuery('query { test }', variables: {'id': 1});
      expect(res2, isNotEmpty);

      // Dio post should only have been called once due to client-side caching!
      verify(() => mockDio.post(any(), data: any(named: 'data'))).called(1);
    });

    test('detects HTTP 429 and throws RateLimitException with retry duration', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 429,
            headers: Headers.fromMap({
              'retry-after': ['45'],
            }),
          ),
        ),
      );

      expect(
        () => client.postQuery('query { test }'),
        throwsA(isA<RateLimitException>().having(
          (e) => e.retryAfter.inSeconds,
          'retryAfter seconds',
          45,
        )),
      );
    });
  });
}
