import '../../schedule/domain/models/airing_schedule.dart';
import '../domain/models/anime_media.dart';
import '../domain/models/episode_metadata.dart';
import 'anilist_client.dart';
import 'anime_repository.dart';
import 'anizip_client.dart';

class AniListRepositoryImpl implements AnimeRepository {
  final AniListClient _client;
  final AniZipClient _aniZipClient;

  AniListRepositoryImpl({
    AniListClient? client,
    AniZipClient? aniZipClient,
  })  : _client = client ?? AniListClient(),
        _aniZipClient = aniZipClient ?? AniZipClient();

  static const String _mediaFieldsFragment = '''
    id
    idMal
    title {
      romaji
      english
      native
      userPreferred
    }
    coverImage {
      extraLarge
      large
      medium
      color
    }
    bannerImage
    description
    format
    status
    seasonYear
    season
    episodes
    duration
    averageScore
    popularity
    genres
    studios(isMain: true) {
      nodes {
        name
      }
    }
    trailer {
      id
      site
    }
    externalLinks {
      id
      site
      url
      type
    }
    nextAiringEpisode {
      airingAt
      timeUntilAiring
      episode
    }
  ''';

  @override
  Future<List<AnimeMedia>> getTrendingAnime({int page = 1, int perPage = 10}) async {
    const query = '''
      query (\$page: Int, \$perPage: Int) {
        Page(page: \$page, perPage: \$perPage) {
          media(type: ANIME, sort: [TRENDING_DESC, POPULARITY_DESC], isAdult: false) {
            $_mediaFieldsFragment
          }
        }
      }
    ''';
    final data = await _client.postQuery(query, variables: {'page': page, 'perPage': perPage});
    return _parseMediaList(data);
  }

  @override
  Future<List<AnimeMedia>> getPopularAnime({int page = 1, int perPage = 10}) async {
    const query = '''
      query (\$page: Int, \$perPage: Int) {
        Page(page: \$page, perPage: \$perPage) {
          media(type: ANIME, sort: [POPULARITY_DESC], isAdult: false) {
            $_mediaFieldsFragment
          }
        }
      }
    ''';
    final data = await _client.postQuery(query, variables: {'page': page, 'perPage': perPage});
    return _parseMediaList(data);
  }

  @override
  Future<List<AnimeMedia>> getTopRatedAnime({int page = 1, int perPage = 10}) async {
    const query = '''
      query (\$page: Int, \$perPage: Int) {
        Page(page: \$page, perPage: \$perPage) {
          media(type: ANIME, sort: [SCORE_DESC], isAdult: false) {
            $_mediaFieldsFragment
          }
        }
      }
    ''';
    final data = await _client.postQuery(query, variables: {'page': page, 'perPage': perPage});
    return _parseMediaList(data);
  }

  @override
  Future<List<AnimeMedia>> getAiringTodayAnime({int page = 1, int perPage = 10}) async {
    const query = '''
      query (\$page: Int, \$perPage: Int) {
        Page(page: \$page, perPage: \$perPage) {
          media(type: ANIME, status: RELEASING, sort: [POPULARITY_DESC], isAdult: false) {
            $_mediaFieldsFragment
          }
        }
      }
    ''';
    final data = await _client.postQuery(query, variables: {'page': page, 'perPage': perPage});
    return _parseMediaList(data);
  }

  @override
  Future<List<AnimeMedia>> getCurrentlyAiringAnime({int page = 1, int perPage = 10}) async {
    const query = '''
      query (\$page: Int, \$perPage: Int) {
        Page(page: \$page, perPage: \$perPage) {
          media(type: ANIME, status: RELEASING, sort: [TRENDING_DESC], isAdult: false) {
            $_mediaFieldsFragment
          }
        }
      }
    ''';
    final data = await _client.postQuery(query, variables: {'page': page, 'perPage': perPage});
    return _parseMediaList(data);
  }

  @override
  Future<AnimeMedia> getAnimeDetails(int id) async {
    const query = '''
      query (\$id: Int) {
        Media(id: \$id, type: ANIME, isAdult: false) {
          $_mediaFieldsFragment
          relations {
            edges {
              relationType
              node {
                id
                title {
                  userPreferred
                  english
                  romaji
                }
                coverImage {
                  medium
                  large
                }
                format
                status
              }
            }
          }
        }
      }
    ''';
    final data = await _client.postQuery(query, variables: {'id': id});
    final mediaMap = data['Media'] as Map<String, dynamic>? ?? {};
    return AnimeMedia.fromJson(mediaMap);
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
    const gql = '''
      query (
        \$page: Int,
        \$perPage: Int,
        \$search: String,
        \$genre: String,
        \$format: MediaFormat,
        \$status: MediaStatus,
        \$seasonYear: Int,
        \$sort: [MediaSort]
      ) {
        Page(page: \$page, perPage: \$perPage) {
          pageInfo {
            total
            currentPage
            lastPage
            hasNextPage
            perPage
          }
          media(
            type: ANIME,
            search: \$search,
            genre: \$genre,
            format: \$format,
            status: \$status,
            seasonYear: \$seasonYear,
            sort: \$sort,
            isAdult: false
          ) {
            $_mediaFieldsFragment
          }
        }
      }
    ''';

    final variables = <String, dynamic>{
      'page': page,
      'perPage': perPage,
      'sort': [sort],
    };
    if (query != null && query.trim().isNotEmpty) {
      variables['search'] = query.trim();
    }
    if (genre != null && genre.trim().isNotEmpty && genre != 'All Genres') {
      variables['genre'] = genre.trim();
    }
    if (format != null && format.trim().isNotEmpty && format != 'ALL') {
      variables['format'] = format.trim();
    }
    if (status != null && status.trim().isNotEmpty && status != 'ALL') {
      variables['status'] = status.trim();
    }
    if (year != null && year > 0) {
      variables['seasonYear'] = year;
    }

    final data = await _client.postQuery(gql, variables: variables);
    return PaginatedAnime.fromJson(data);
  }

  @override
  Future<List<String>> getGenres() async {
    return const [
      'Action',
      'Adventure',
      'Comedy',
      'Drama',
      'Fantasy',
      'Horror',
      'Mecha',
      'Mystery',
      'Psychological',
      'Romance',
      'Sci-Fi',
      'Slice of Life',
      'Sports',
      'Supernatural',
      'Thriller',
    ];
  }

  List<AnimeMedia> _parseMediaList(Map<String, dynamic> data) {
    final page = data['Page'] as Map<String, dynamic>?;
    if (page == null) return [];
    final media = page['media'] as List?;
    if (media == null) return [];

    return media
        .whereType<Map<String, dynamic>>()
        .map((m) => AnimeMedia.fromJson(m))
        .toList();
  }

  static const String _airingScheduleQuery = '''
    query (\$airingAt_greater: Int, \$airingAt_lesser: Int, \$page: Int, \$perPage: Int) {
      Page(page: \$page, perPage: \$perPage) {
        pageInfo {
          hasNextPage
          total
        }
        airingSchedules(
          airingAt_greater: \$airingAt_greater
          airingAt_lesser: \$airingAt_lesser
          sort: TIME
        ) {
          id
          airingAt
          timeUntilAiring
          episode
          mediaId
          media {
            $_mediaFieldsFragment
          }
        }
      }
    }
  ''';

  @override
  Future<List<AiringSchedule>> getAiringSchedules({
    required int startTimestamp,
    required int endTimestamp,
    int page = 1,
    int perPage = 50,
  }) async {
    final data = await _client.postQuery(
      _airingScheduleQuery,
      variables: {
        'airingAt_greater': startTimestamp,
        'airingAt_lesser': endTimestamp,
        'page': page,
        'perPage': perPage,
      },
    );

    final pageMap = data['Page'] as Map<String, dynamic>?;
    if (pageMap == null) return [];
    final schedules = pageMap['airingSchedules'] as List?;
    if (schedules == null) return [];

    return schedules
        .whereType<Map<String, dynamic>>()
        .map((s) => AiringSchedule.fromJson(s))
        .toList();
  }

  @override
  Future<List<EpisodeMetadata>> getEpisodesMetadata(
    int anilistId, {
    int? fallbackCount,
  }) async {
    return _aniZipClient.getEpisodes(anilistId, fallbackCount: fallbackCount);
  }
}
