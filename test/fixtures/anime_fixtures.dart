// Test JSON fixtures simulating AniList GraphQL responses.

import 'package:anilov/features/anime/data/anime_repository.dart';
import 'package:anilov/features/anime/domain/models/anime_media.dart';

const Map<String, dynamic> sampleAnimeJson = {
  'id': 16498,
  'idMal': 16498,
  'title': {
    'romaji': 'Shingeki no Kyojin',
    'english': 'Attack on Titan',
    'native': '進撃の巨人',
    'userPreferred': 'Attack on Titan',
  },
  'coverImage': {
    'extraLarge': 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx16498.jpg',
    'large': 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/medium/bx16498.jpg',
    'medium': 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/small/bx16498.jpg',
    'color': '#e4a05a',
  },
  'bannerImage': 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/16498.jpg',
  'description': 'Centuries ago, mankind was almost slaughtered...<br><br><b>Enter Eren!</b>',
  'format': 'TV',
  'status': 'FINISHED',
  'seasonYear': 2013,
  'season': 'SPRING',
  'episodes': 25,
  'duration': 24,
  'averageScore': 85,
  'popularity': 540000,
  'genres': ['Action', 'Drama', 'Fantasy', 'Mystery'],
  'studios': {
    'nodes': [
      {'name': 'WIT Studio'}
    ]
  },
  'trailer': {
    'id': 'MGRm4IzK1SQ',
    'site': 'youtube',
  },
  'externalLinks': [
    {
      'id': 101,
      'site': 'Crunchyroll',
      'url': 'https://www.crunchyroll.com/attack-on-titan',
      'type': 'STREAMING',
    },
    {
      'id': 102,
      'site': 'Netflix',
      'url': 'https://www.netflix.com/title/70299043',
      'type': 'STREAMING',
    }
  ],
  'nextAiringEpisode': null,
  'relations': {
    'edges': [
      {
        'relationType': 'SEQUEL',
        'node': {
          'id': 20958,
          'title': {
            'userPreferred': 'Attack on Titan Season 2',
            'english': 'Attack on Titan Season 2',
            'romaji': 'Shingeki no Kyojin Season 2',
          },
          'coverImage': {
            'medium': 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/medium/20958.jpg',
            'large': 'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/20958.jpg',
          },
          'format': 'TV',
          'status': 'FINISHED',
        }
      }
    ]
  }
};

const Map<String, dynamic> sampleAnimeWithNullsJson = {
  'id': 99999,
  'idMal': null,
  'title': null,
  'coverImage': null,
  'bannerImage': null,
  'description': null,
  'format': null,
  'status': null,
  'seasonYear': null,
  'season': null,
  'episodes': null,
  'duration': null,
  'averageScore': null,
  'popularity': null,
  'genres': null,
  'studios': null,
  'trailer': null,
  'externalLinks': null,
  'nextAiringEpisode': null,
  'relations': null,
};

const Map<String, dynamic> samplePageJson = {
  'Page': {
    'pageInfo': {
      'total': 120,
      'currentPage': 1,
      'lastPage': 6,
      'hasNextPage': true,
      'perPage': 20,
    },
    'media': [
      sampleAnimeJson,
    ]
  }
};

class FakeAnimeRepository implements AnimeRepository {
  final List<AnimeMedia> items;
  final bool shouldFail;

  FakeAnimeRepository(this.items, {this.shouldFail = false});

  @override
  Future<List<AnimeMedia>> getTrendingAnime({int page = 1, int perPage = 10}) async {
    if (shouldFail) throw Exception('Network timeout error');
    return items;
  }

  @override
  Future<List<AnimeMedia>> getPopularAnime({int page = 1, int perPage = 10}) async {
    if (shouldFail) throw Exception('Network timeout error');
    return items;
  }

  @override
  Future<List<AnimeMedia>> getTopRatedAnime({int page = 1, int perPage = 10}) async {
    if (shouldFail) throw Exception('Network timeout error');
    return items;
  }

  @override
  Future<List<AnimeMedia>> getAiringTodayAnime({int page = 1, int perPage = 10}) async {
    if (shouldFail) throw Exception('Network timeout error');
    return items;
  }

  @override
  Future<List<AnimeMedia>> getCurrentlyAiringAnime({int page = 1, int perPage = 10}) async {
    if (shouldFail) throw Exception('Network timeout error');
    return items;
  }

  @override
  Future<AnimeMedia> getAnimeDetails(int id) async {
    if (shouldFail) throw Exception('Failed to load anime details');
    return items.first;
  }

  @override
  Future<PaginatedAnime> searchAnime({
    String? query,
    String? genre,
    String? format,
    String? status,
    int? year,
    String sort = 'TRENDING_DESC',
    int page = 1,
    int perPage = 20,
  }) async {
    if (shouldFail) throw Exception('Search error');
    if (query == 'empty') {
      return const PaginatedAnime(pageInfo: PageInfo(), items: []);
    }
    return PaginatedAnime(pageInfo: const PageInfo(total: 1), items: items);
  }

  @override
  Future<List<String>> getGenres() async => ['Action', 'Adventure', 'Comedy', 'Drama'];
}

