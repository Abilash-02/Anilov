// ani.zip episode metadata enrichment client

import 'package:dio/dio.dart';
import '../domain/models/episode_metadata.dart';

class AniZipClient {
  static const String baseUrl = 'https://api.ani.zip/mappings';
  final Dio _dio;
  final Map<int, List<EpisodeMetadata>> _cache = {};

  AniZipClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: {
                  'Accept': 'application/json',
                  'User-Agent': 'Anilov/1.0.0 (https://github.com/Abilash-02/Anilov)',
                },
              ),
            );

  void clearCache() => _cache.clear();

  Future<List<EpisodeMetadata>> getEpisodes(int anilistId, {int? fallbackCount}) async {
    if (_cache.containsKey(anilistId)) {
      return _cache[anilistId]!;
    }

    try {
      final response = await _dio.get(
        '',
        queryParameters: {'anilist_id': anilistId},
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['episodes'] is Map) {
        final episodesMap = data['episodes'] as Map<String, dynamic>;
        final list = <EpisodeMetadata>[];

        for (final entry in episodesMap.entries) {
          final epNum = int.tryParse(entry.key);
          if (epNum != null && entry.value is Map<String, dynamic>) {
            list.add(EpisodeMetadata.fromJson(epNum, entry.value as Map<String, dynamic>));
          }
        }

        // Sort by episode number ascending
        list.sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));

        if (list.isNotEmpty) {
          _cache[anilistId] = list;
          return list;
        }
      }
    } catch (_) {
      // Graceful degradation: network timeout, 404, or service downtime
    }

    // Fallback to plain episode numbers if total episodes is known
    final fallbackList = <EpisodeMetadata>[];
    if (fallbackCount != null && fallbackCount > 0) {
      for (int i = 1; i <= fallbackCount; i++) {
        fallbackList.add(EpisodeMetadata.fallback(i));
      }
      _cache[anilistId] = fallbackList;
    }
    return fallbackList;
  }
}
