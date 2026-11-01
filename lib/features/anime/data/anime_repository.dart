import '../../schedule/domain/models/airing_schedule.dart';
import '../domain/models/anime_media.dart';
import '../domain/models/episode_metadata.dart';

abstract class AnimeRepository {
  Future<List<AnimeMedia>> getTrendingAnime({int page = 1, int perPage = 10});

  Future<List<AnimeMedia>> getPopularAnime({int page = 1, int perPage = 10});

  Future<List<AnimeMedia>> getTopRatedAnime({int page = 1, int perPage = 10});

  Future<List<AnimeMedia>> getAiringTodayAnime({int page = 1, int perPage = 10});

  Future<List<AnimeMedia>> getCurrentlyAiringAnime({int page = 1, int perPage = 10});

  Future<AnimeMedia> getAnimeDetails(int id);

  Future<PaginatedAnime> searchAnime({
    String? query,
    String? genre,
    String? format,
    String? status,
    int? year,
    String sort = 'TRENDING_DESC',
    int page = 1,
    int perPage = 20,
  });

  Future<List<String>> getGenres();

  Future<List<AiringSchedule>> getAiringSchedules({
    required int startTimestamp,
    required int endTimestamp,
    int page = 1,
    int perPage = 50,
  });

  Future<List<EpisodeMetadata>> getEpisodesMetadata(
    int anilistId, {
    int? fallbackCount,
  });
}
