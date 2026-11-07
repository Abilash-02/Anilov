import 'package:flutter_test/flutter_test.dart';
import 'package:anilov/features/auth/data/anilist_oauth_service.dart';

void main() {
  group('AniListOAuthService Tests', () {
    test('buildAuthorizationUrl generates valid AniList OAuth URL', () {
      final url = AniListOAuthService.buildAuthorizationUrl('12345');
      final uri = Uri.parse(url);

      expect(uri.scheme, equals('https'));
      expect(uri.host, equals('anilist.co'));
      expect(uri.path, equals('/api/v2/oauth/authorize'));
      expect(uri.queryParameters['client_id'], equals('12345'));
      expect(uri.queryParameters['response_type'], equals('token'));
    });

    test('extractAccessToken parses access token from URI fragment', () {
      final uri = Uri.parse(
        'anilov://auth#access_token=sample_oauth_token_xyz&token_type=Bearer&expires_in=31536000',
      );

      final token = AniListOAuthService.extractAccessToken(uri);
      expect(token, equals('sample_oauth_token_xyz'));
    });

    test('extractAccessToken parses access token from query parameters', () {
      final uri = Uri.parse(
        'anilov://auth?access_token=query_token_abc&token_type=Bearer',
      );

      final token = AniListOAuthService.extractAccessToken(uri);
      expect(token, equals('query_token_abc'));
    });

    test('extractAccessToken throws OAuthException on access_denied in fragment', () {
      final uri = Uri.parse(
        'anilov://auth#error=access_denied&error_description=The+user+denied+request',
      );

      expect(
        () => AniListOAuthService.extractAccessToken(uri),
        throwsA(isA<OAuthException>().having(
          (e) => e.message,
          'message',
          contains('user denied request'),
        )),
      );
    });

    test('extractAccessToken throws OAuthException on error in query parameters', () {
      final uri = Uri.parse(
        'anilov://auth?error=unauthorized_client&error_description=Invalid+client',
      );

      expect(
        () => AniListOAuthService.extractAccessToken(uri),
        throwsA(isA<OAuthException>().having(
          (e) => e.message,
          'message',
          contains('Invalid client'),
        )),
      );
    });

    test('extractAccessToken returns null when no token or error is present', () {
      final uri = Uri.parse('anilov://auth');
      expect(AniListOAuthService.extractAccessToken(uri), isNull);
    });
  });
}
