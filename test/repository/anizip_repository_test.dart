// Mocked response unit tests for AniZipClient

import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anilov/features/anime/data/anizip_client.dart';
import '../fixtures/anime_fixtures.dart';

class _MockAniZipAdapter implements HttpClientAdapter {
  final bool shouldFail;
  int callCount = 0;

  _MockAniZipAdapter({this.shouldFail = false});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    callCount++;

    if (shouldFail) {
      return ResponseBody.fromString(
        'Internal Server Error',
        500,
        headers: {
          Headers.contentTypeHeader: [Headers.textPlainContentType],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode(sampleAniZipJson),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('AniZipClient Unit Tests (Master Prompt Mandated)', () {
    test('successfully parses mocked ani.zip response into EpisodeMetadata list', () async {
      final mockAdapter = _MockAniZipAdapter();
      final dio = Dio()..httpClientAdapter = mockAdapter;
      final client = AniZipClient(dio: dio);

      final episodes = await client.getEpisodes(16498);

      expect(episodes.length, 2);
      expect(episodes[0].episodeNumber, 1);
      expect(episodes[0].displayTitle, 'To You, in 2000 Years');
      expect(episodes[0].runtime, 24);
      expect(episodes[1].episodeNumber, 2);
      expect(episodes[1].displayTitle, 'That Day');
      expect(mockAdapter.callCount, 1);
    });

    test('caches responses and avoids duplicate network requests', () async {
      final mockAdapter = _MockAniZipAdapter();
      final dio = Dio()..httpClientAdapter = mockAdapter;
      final client = AniZipClient(dio: dio);

      final firstCall = await client.getEpisodes(16498);
      final secondCall = await client.getEpisodes(16498);

      expect(firstCall.length, secondCall.length);
      expect(mockAdapter.callCount, 1); // Only 1 network request made
    });

    test('gracefully falls back to plain episode numbers on failure without crashing', () async {
      final mockAdapter = _MockAniZipAdapter(shouldFail: true);
      final dio = Dio()..httpClientAdapter = mockAdapter;
      final client = AniZipClient(dio: dio);

      // Total 12 episodes known from AniList
      final episodes = await client.getEpisodes(99999, fallbackCount: 12);

      expect(episodes.length, 12);
      expect(episodes[0].episodeNumber, 1);
      expect(episodes[0].displayTitle, 'Episode 1');
      expect(episodes[11].episodeNumber, 12);
      expect(episodes[11].displayTitle, 'Episode 12');
    });
  });
}
