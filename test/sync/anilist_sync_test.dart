import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:anilov/features/anime/data/anilist_client.dart';
import 'package:anilov/features/sync/data/anilist_sync_repository.dart';
import 'package:anilov/features/watchlist/data/watchlist_repository.dart';
import 'package:anilov/features/watchlist/domain/models/watch_status.dart';
import 'package:anilov/features/watchlist/domain/models/watchlist_item.dart';

class MockAniListClient extends Mock implements AniListClient {}

class FakeWatchlistRepository implements WatchlistRepository {
  final Map<int, WatchlistItem> items = {};

  @override
  Future<List<WatchlistItem>> getWatchlist({
    WatchStatus? status,
    String? searchQuery,
    String sortBy = 'updated_at',
    bool ascending = false,
  }) async {
    return items.values.toList();
  }

  @override
  Future<WatchlistItem?> getWatchlistItem(int animeId) async => items[animeId];

  @override
  Future<void> saveWatchlistItem(WatchlistItem item) async {
    items[item.animeId] = item;
  }

  @override
  Future<void> updateProgress(int animeId, int progress) async {
    if (items.containsKey(animeId)) {
      items[animeId] = items[animeId]!.copyWith(progress: progress);
    }
  }

  @override
  Future<void> updateStatus(int animeId, WatchStatus status) async {
    if (items.containsKey(animeId)) {
      items[animeId] = items[animeId]!.copyWith(status: status);
    }
  }

  @override
  Future<void> updateScore(int animeId, double? score) async {
    if (items.containsKey(animeId)) {
      items[animeId] = items[animeId]!.copyWith(score: score);
    }
  }

  @override
  Future<void> deleteWatchlistItem(int animeId) async {
    items.remove(animeId);
  }

  @override
  Future<bool> isInWatchlist(int animeId) async => items.containsKey(animeId);

  @override
  Future<List<WatchlistItem>> getContinueWatching({int limit = 10}) async {
    return items.values.where((i) => i.status == WatchStatus.watching).toList();
  }

  @override
  Future<Map<WatchStatus, int>> getWatchlistCounts() async => {};
}

void main() {
  group('AniListSyncRepository Tests', () {
    late MockAniListClient mockClient;
    late FakeWatchlistRepository fakeWatchlistRepo;
    late AniListSyncRepository syncRepository;

    setUp(() {
      mockClient = MockAniListClient();
      fakeWatchlistRepo = FakeWatchlistRepository();
      syncRepository = AniListSyncRepository(
        client: mockClient,
        watchlistRepository: fakeWatchlistRepo,
      );
    });

    test('pulls new remote anime entries into local watchlist', () async {
      final remoteCollection = {
        'MediaListCollection': {
          'lists': [
            {
              'name': 'Watching',
              'status': 'CURRENT',
              'entries': [
                {
                  'id': 1001,
                  'mediaId': 21,
                  'status': 'CURRENT',
                  'progress': 15,
                  'score': 8.5,
                  'updatedAt': 1700000000,
                  'media': {
                    'id': 21,
                    'title': {'english': 'One Piece', 'romaji': 'One Piece'},
                    'coverImage': {'large': 'https://example.com/onepiece.jpg'},
                    'episodes': 1100,
                    'format': 'TV',
                    'status': 'RELEASING',
                  },
                },
              ],
            },
          ],
        },
      };

      when(
        () => mockClient.postQuery(
          any(),
          variables: any(named: 'variables'),
          authToken: any(named: 'authToken'),
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).thenAnswer((_) async => remoteCollection);

      final result = await syncRepository.synchronize(
        accessToken: 'valid_token',
        userId: 42,
      );

      expect(result.pulledCount, equals(1));
      expect(fakeWatchlistRepo.items.containsKey(21), isTrue);

      final saved = fakeWatchlistRepo.items[21]!;
      expect(saved.title, equals('One Piece'));
      expect(saved.progress, equals(15));
      expect(saved.status, equals(WatchStatus.watching));
      expect(saved.score, equals(8.5));
    });

    test('preserves higher local offline progress and pushes to remote', () async {
      // Local has progress 18 (user watched offline)
      fakeWatchlistRepo.items[21] = WatchlistItem(
        animeId: 21,
        title: 'One Piece',
        status: WatchStatus.watching,
        progress: 18,
        score: 8.5,
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // Remote only has progress 15
      final remoteCollection = {
        'MediaListCollection': {
          'lists': [
            {
              'name': 'Watching',
              'status': 'CURRENT',
              'entries': [
                {
                  'id': 1001,
                  'mediaId': 21,
                  'status': 'CURRENT',
                  'progress': 15,
                  'score': 8.5,
                  'updatedAt': 1690000000,
                  'media': {
                    'id': 21,
                    'title': {'english': 'One Piece'},
                    'episodes': 1100,
                  },
                },
              ],
            },
          ],
        },
      };

      when(
        () => mockClient.postQuery(
          any(),
          variables: any(named: 'variables'),
          authToken: any(named: 'authToken'),
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).thenAnswer((_) async => remoteCollection);

      final result = await syncRepository.synchronize(
        accessToken: 'valid_token',
        userId: 42,
      );

      expect(result.pushedCount, equals(1));
      // Local progress should still be 18, not overwritten by 15
      expect(fakeWatchlistRepo.items[21]!.progress, equals(18));

      // Verify that saveEntry mutation was called with progress: 18
      verify(
        () => mockClient.postQuery(
          AniListSyncRepository.saveEntryMutation,
          variables: {
            'mediaId': 21,
            'status': 'CURRENT',
            'progress': 18,
            'score': 8.5,
          },
          authToken: 'valid_token',
          forceRefresh: true,
        ),
      ).called(1);
    });

    test('pushes local-only anime entry to AniList', () async {
      // User added FMA while offline
      fakeWatchlistRepo.items[5114] = WatchlistItem(
        animeId: 5114,
        title: 'Fullmetal Alchemist: Brotherhood',
        status: WatchStatus.completed,
        progress: 64,
        score: 9.8,
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // Remote has empty list
      final remoteCollection = {
        'MediaListCollection': {
          'lists': [],
        },
      };

      when(
        () => mockClient.postQuery(
          any(),
          variables: any(named: 'variables'),
          authToken: any(named: 'authToken'),
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).thenAnswer((_) async => remoteCollection);

      final result = await syncRepository.synchronize(
        accessToken: 'token_123',
        userId: 99,
      );

      expect(result.pushedCount, equals(1));
      verify(
        () => mockClient.postQuery(
          AniListSyncRepository.saveEntryMutation,
          variables: {
            'mediaId': 5114,
            'status': 'COMPLETED',
            'progress': 64,
            'score': 9.8,
          },
          authToken: 'token_123',
          forceRefresh: true,
        ),
      ).called(1);
    });
  });
}
