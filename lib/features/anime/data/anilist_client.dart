import 'dart:convert';
import 'package:dio/dio.dart';

class RateLimitException implements Exception {
  final Duration retryAfter;
  final String message;

  const RateLimitException({
    required this.retryAfter,
    this.message = 'AniList rate limit reached. Please wait before retrying.',
  });

  @override
  String toString() => '$message (Retry after: ${retryAfter.inSeconds}s)';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);

  @override
  String toString() => message;
}

class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException([this.message = 'AniList session expired or unauthorized. Please re-login.']);

  @override
  String toString() => message;
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (code: $statusCode)';
}

class _CacheEntry {
  final dynamic data;
  final DateTime timestamp;

  _CacheEntry(this.data) : timestamp = DateTime.now();

  bool isExpired(Duration ttl) =>
      DateTime.now().difference(timestamp) > ttl;
}

/// Robust AniList GraphQL API client with in-memory caching,
/// timeout handling, and rate-limit detection.
class AniListClient {
  static const String endpoint = 'https://graphql.anilist.co';
  static const Duration defaultTtl = Duration(minutes: 5);

  final Dio _dio;
  final Map<String, _CacheEntry> _cache = {};

  AniListClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: endpoint,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  'User-Agent': 'Anilov/1.0.0 (https://github.com/Abilash-02/Anilov)',
                },
              ),
            );

  void clearCache() {
    _cache.clear();
  }

  Future<Map<String, dynamic>> postQuery(
    String query, {
    Map<String, dynamic>? variables,
    String? authToken,
    Duration ttl = defaultTtl,
    bool forceRefresh = false,
  }) async {
    final isCacheable = (authToken == null || authToken.isEmpty) &&
        !query.trim().startsWith('mutation');
    final cacheKey = '$query::${jsonEncode(variables ?? {})}';

    if (!forceRefresh && isCacheable && _cache.containsKey(cacheKey)) {
      final entry = _cache[cacheKey]!;
      if (!entry.isExpired(ttl)) {
        return entry.data as Map<String, dynamic>;
      } else {
        _cache.remove(cacheKey);
      }
    }

    try {
      final response = (authToken != null && authToken.isNotEmpty)
          ? await _dio.post(
              '',
              data: {
                'query': query,
                'variables': variables,
              },
              options: Options(headers: {'Authorization': 'Bearer $authToken'}),
            )
          : await _dio.post(
              '',
              data: {
                'query': query,
                'variables': variables,
              },
            );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('errors') && data['errors'] is List) {
          final errors = data['errors'] as List;
          if (errors.isNotEmpty) {
            final first = errors.first;
            final msg = first is Map ? (first['message'] ?? 'GraphQL error') : 'GraphQL error';
            final status = first is Map ? first['status'] : null;
            if (status == 401 || msg.toString().toLowerCase().contains('unauthorized')) {
              throw const UnauthorizedException();
            }
            throw ApiException(msg.toString());
          }
        }

        final resultData = data['data'] as Map<String, dynamic>? ?? {};
        if (isCacheable) {
          _cache[cacheKey] = _CacheEntry(resultData);
        }
        return resultData;
      }

      throw const ApiException('Invalid response received from AniList.');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const UnauthorizedException();
      }

      if (e.response?.statusCode == 429) {
        final retryHeader = e.response?.headers.value('retry-after');
        int seconds = 60;
        if (retryHeader != null) {
          seconds = int.tryParse(retryHeader) ?? 60;
        }
        throw RateLimitException(retryAfter: Duration(seconds: seconds));
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw const NetworkException('Connection to AniList timed out. Please check your internet connection.');
      }

      final statusCode = e.response?.statusCode;
      throw ApiException(
        e.message ?? 'Network error connecting to AniList.',
        statusCode: statusCode,
      );
    }
  }
}
