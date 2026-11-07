import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:anilov/features/anime/data/anilist_client.dart';
import 'package:anilov/features/watchlist/data/watchlist_repository.dart';
import 'package:anilov/features/watchlist/domain/models/watch_status.dart';
import 'package:anilov/features/watchlist/domain/models/watchlist_item.dart';

class SyncResult {
  final int totalSynced;
  final int pulledCount;
  final int pushedCount;

  const SyncResult({
    this.totalSynced = 0,
    this.pulledCount = 0,
    this.pushedCount = 0,
  });
}

abstract class SyncRepository {
  Future<SyncResult> synchronize({
    required String accessToken,
    required int userId,
  });
}

class AniListSyncRepository implements SyncRepository {
  final AniListClient _client;
  final WatchlistRepository _watchlistRepository;

  AniListSyncRepository({
    AniListClient? client,
    required WatchlistRepository watchlistRepository,
  })  : _client = client ?? AniListClient(),
        _watchlistRepository = watchlistRepository;

  static const String collectionQuery = '''
    query UserAnimeList(\$userId: Int) {
      MediaListCollection(userId: \$userId, type: ANIME) {
        lists {
          name
          status
          entries {
            id
            mediaId
            status
            progress
            score(format: POINT_10_DECIMAL)
            updatedAt
            media {
              id
              title {
                romaji
                english
                native
              }
              coverImage {
                large
                medium
              }
              episodes
              format
              status
            }
          }
        }
      }
    }
  ''';

  static const String saveEntryMutation = '''
    mutation SaveEntry(\$mediaId: Int, \$status: MediaListStatus, \$progress: Int, \$score: Float) {
      SaveMediaListEntry(mediaId: \$mediaId, status: \$status, progress: \$progress, score: \$score) {
        id
        mediaId
        status
        progress
        score
        updatedAt
      }
    }
  ''';

  static String toAniListStatus(WatchStatus status) {
    switch (status) {
      case WatchStatus.watching:
        return 'CURRENT';
      case WatchStatus.planning:
        return 'PLANNING';
      case WatchStatus.completed:
        return 'COMPLETED';
      case WatchStatus.onHold:
        return 'PAUSED';
      case WatchStatus.dropped:
        return 'DROPPED';
    }
  }

  static WatchStatus fromAniListStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'CURRENT':
      case 'REPEATING':
        return WatchStatus.watching;
      case 'PLANNING':
        return WatchStatus.planning;
      case 'COMPLETED':
        return WatchStatus.completed;
      case 'PAUSED':
        return WatchStatus.onHold;
      case 'DROPPED':
        return WatchStatus.dropped;
      default:
        return WatchStatus.planning;
    }
  }

  @override
  Future<SyncResult> synchronize({
    required String accessToken,
    required int userId,
  }) async {
    // 1. Fetch remote collection from AniList
    final response = await _client.postQuery(
      collectionQuery,
      variables: {'userId': userId},
      authToken: accessToken,
      forceRefresh: true,
    );

    final collection = response['MediaListCollection'] as Map<String, dynamic>?;
    final lists = collection?['lists'] as List<dynamic>? ?? [];

    final remoteEntries = <int, Map<String, dynamic>>{};
    for (final list in lists) {
      if (list is Map<String, dynamic>) {
        final entries = list['entries'] as List<dynamic>? ?? [];
        for (final entry in entries) {
          if (entry is Map<String, dynamic>) {
            final mediaId = entry['mediaId'] as int?;
            if (mediaId != null) {
              remoteEntries[mediaId] = entry;
            }
          }
        }
      }
    }

    // 2. Fetch local items from SQLite
    final localList = await _watchlistRepository.getWatchlist();
    final localEntries = <int, WatchlistItem>{
      for (final item in localList) item.animeId: item,
    };

    int pulled = 0;
    int pushed = 0;

    // 3. Process remote entries: pull new or resolve conflicts
    for (final entry in remoteEntries.entries) {
      final mediaId = entry.key;
      final remoteData = entry.value;

      final remoteStatusStr = remoteData['status'] as String?;
      final remoteStatus = fromAniListStatus(remoteStatusStr);
      final remoteProgress = remoteData['progress'] as int? ?? 0;
      final remoteScore = (remoteData['score'] as num?)?.toDouble();
      final remoteUpdatedSec = remoteData['updatedAt'] as int? ?? 0;
      final remoteUpdatedAt = DateTime.fromMillisecondsSinceEpoch(
        remoteUpdatedSec > 0 ? remoteUpdatedSec * 1000 : DateTime.now().millisecondsSinceEpoch,
      );

      final media = remoteData['media'] as Map<String, dynamic>? ?? {};
      final titleMap = media['title'] as Map<String, dynamic>? ?? {};
      final title = titleMap['english'] as String? ??
          titleMap['romaji'] as String? ??
          titleMap['native'] as String? ??
          'Unknown Anime';

      final coverMap = media['coverImage'] as Map<String, dynamic>? ?? {};
      final coverUrl = coverMap['large'] as String? ?? coverMap['medium'] as String?;
      final totalEpisodes = media['episodes'] as int?;
      final format = media['format'] as String?;

      final localItem = localEntries[mediaId];

      if (localItem == null) {
        // New item from remote: pull to local
        final newItem = WatchlistItem(
          animeId: mediaId,
          title: title,
          coverUrl: coverUrl,
          format: format,
          totalEpisodes: totalEpisodes,
          status: remoteStatus,
          progress: remoteProgress,
          score: remoteScore,
          updatedAt: remoteUpdatedAt,
          createdAt: remoteUpdatedAt,
        );
        await _watchlistRepository.saveWatchlistItem(newItem);
        pulled++;
      } else {
        // Both exist: resolve conflict safely
        if (localItem.progress > remoteProgress) {
          // Local has more watched progress (offline progress): push to AniList
          await _pushEntryToRemote(
            accessToken: accessToken,
            mediaId: mediaId,
            status: localItem.status,
            progress: localItem.progress,
            score: localItem.score,
          );
          pushed++;
        } else if (remoteProgress > localItem.progress) {
          // Remote has more progress: pull to local SQLite
          final updatedItem = localItem.copyWith(
            status: remoteStatus,
            progress: remoteProgress,
            score: remoteScore,
            updatedAt: remoteUpdatedAt,
          );
          await _watchlistRepository.saveWatchlistItem(updatedItem);
          pulled++;
        } else {
          // Equal progress: check status or score discrepancy
          final statusDiffers = localItem.status != remoteStatus;
          final scoreDiffers = (localItem.score ?? 0) != (remoteScore ?? 0);

          if (statusDiffers || scoreDiffers) {
            if (localItem.updatedAt.isAfter(remoteUpdatedAt)) {
              // Local update is newer: push to remote
              await _pushEntryToRemote(
                accessToken: accessToken,
                mediaId: mediaId,
                status: localItem.status,
                progress: localItem.progress,
                score: localItem.score,
              );
              pushed++;
            } else {
              // Remote update is newer: pull to local
              final updatedItem = localItem.copyWith(
                status: remoteStatus,
                score: remoteScore,
                updatedAt: remoteUpdatedAt,
              );
              await _watchlistRepository.saveWatchlistItem(updatedItem);
              pulled++;
            }
          }
        }
      }
    }

    // 4. Process local-only items: push to AniList so user doesn't lose local watchlist
    for (final localItem in localList) {
      if (!remoteEntries.containsKey(localItem.animeId)) {
        await _pushEntryToRemote(
          accessToken: accessToken,
          mediaId: localItem.animeId,
          status: localItem.status,
          progress: localItem.progress,
          score: localItem.score,
        );
        pushed++;
      }
    }

    return SyncResult(
      totalSynced: pulled + pushed,
      pulledCount: pulled,
      pushedCount: pushed,
    );
  }

  Future<void> _pushEntryToRemote({
    required String accessToken,
    required int mediaId,
    required WatchStatus status,
    required int progress,
    required double? score,
  }) async {
    try {
      await _client.postQuery(
        saveEntryMutation,
        variables: {
          'mediaId': mediaId,
          'status': toAniListStatus(status),
          'progress': progress,
          'score': score ?? 0.0,
        },
        authToken: accessToken,
        forceRefresh: true,
      );
    } catch (e) {
      debugPrint('Failed to push media $mediaId to AniList: $e');
      // Non-fatal per item; keep going
    }
  }
}
