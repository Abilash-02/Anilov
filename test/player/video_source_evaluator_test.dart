import 'package:flutter_test/flutter_test.dart';
import 'package:anilov/features/player/domain/video_source_evaluator.dart';

void main() {
  group('VideoSourceEvaluator Tests', () {
    test('returns invalidUrl for empty or blank URL', () async {
      final resEmpty = await VideoSourceEvaluator.evaluate('');
      expect(resEmpty.type, equals(VideoUrlType.invalidUrl));
      expect(resEmpty.isInvalid, isTrue);

      final resBlank = await VideoSourceEvaluator.evaluate('   ');
      expect(resBlank.type, equals(VideoUrlType.invalidUrl));
    });

    test('returns invalidUrl for non-http/https URL', () async {
      final resFtp = await VideoSourceEvaluator.evaluate('ftp://example.com/video.mp4');
      expect(resFtp.type, equals(VideoUrlType.invalidUrl));

      final resInvalid = await VideoSourceEvaluator.evaluate('not-a-valid-url');
      expect(resInvalid.type, equals(VideoUrlType.invalidUrl));
    });

    test('identifies user-provided Google Share link as webpageOrExternal without scraping', () async {
      final res = await VideoSourceEvaluator.evaluate(
        VideoSourceEvaluator.defaultGoogleShareUrl,
      );
      expect(res.type, equals(VideoUrlType.webpageOrExternal));
      expect(res.isWebpage, isTrue);
      expect(res.canLaunchExternally, isTrue);
      expect(res.message, contains('Google Share webpage'));
      expect(res.message, contains('external web browser'));
    });

    test('identifies Google Drive and YouTube links as webpageOrExternal', () async {
      final resDrive = await VideoSourceEvaluator.evaluate(
        'https://drive.google.com/file/d/12345/view',
      );
      expect(resDrive.type, equals(VideoUrlType.webpageOrExternal));
      expect(resDrive.canLaunchExternally, isTrue);

      final resYt = await VideoSourceEvaluator.evaluate(
        'https://youtube.com/watch?v=dQw4w9WgXcQ',
      );
      expect(resYt.type, equals(VideoUrlType.webpageOrExternal));
      expect(resYt.canLaunchExternally, isTrue);
    });

    test('identifies direct video formats (MP4, MKV, WebM, HLS) as directStream', () async {
      final resMp4 = await VideoSourceEvaluator.evaluate('https://cdn.example.org/episodes/ep1.mp4');
      expect(resMp4.type, equals(VideoUrlType.directStream));
      expect(resMp4.isDirectStream, isTrue);

      final resMkv = await VideoSourceEvaluator.evaluate('https://cdn.example.org/files/movie.mkv');
      expect(resMkv.type, equals(VideoUrlType.directStream));

      final resM3u8 = await VideoSourceEvaluator.evaluate('https://cdn.example.org/live/stream.m3u8');
      expect(resM3u8.type, equals(VideoUrlType.directStream));

      final resWebm = await VideoSourceEvaluator.evaluate('https://cdn.example.org/video.webm');
      expect(resWebm.type, equals(VideoUrlType.directStream));
    });

    test('probes content type when extension is missing and classifies HTML as webpage', () async {
      final res = await VideoSourceEvaluator.evaluate(
        'https://example.org/stream-gateway?id=99',
        probeContentType: (uri) async => 'text/html; charset=utf-8',
      );

      expect(res.type, equals(VideoUrlType.webpageOrExternal));
      expect(res.canLaunchExternally, isTrue);
      expect(res.message, contains('HTML webpage'));
    });

    test('probes content type when extension is missing and classifies video MIME as directStream', () async {
      final res = await VideoSourceEvaluator.evaluate(
        'https://example.org/stream-gateway?id=99',
        probeContentType: (uri) async => 'video/mp4',
      );

      expect(res.type, equals(VideoUrlType.directStream));
      expect(res.isDirectStream, isTrue);
    });
  });
}
