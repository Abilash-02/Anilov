import 'dart:async';
import 'package:app_links/app_links.dart';

class OAuthException implements Exception {
  final String message;
  const OAuthException(this.message);

  @override
  String toString() => 'OAuthException: $message';
}

class AniListOAuthService {
  static const String defaultRedirectScheme = 'anilov';
  static const String defaultRedirectHost = 'auth';
  static const String defaultRedirectUri = '$defaultRedirectScheme://$defaultRedirectHost';

  // Injected at compile time via: --dart-define=ANILIST_CLIENT_ID=12345
  static const String environmentClientId =
      String.fromEnvironment('ANILIST_CLIENT_ID', defaultValue: '');

  final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  AniListOAuthService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  static String buildAuthorizationUrl(String clientId, {String redirectUri = defaultRedirectUri}) {
    final queryParams = {
      'client_id': clientId.trim(),
      'response_type': 'token',
    };
    return Uri.https('anilist.co', '/api/v2/oauth/authorize', queryParams).toString();
  }

  /// Parses the deep-link URI and extracts the OAuth access token.
  /// Handles both URI fragment (#access_token=...) and query params (?access_token=...).
  static String? extractAccessToken(Uri uri) {
    if (uri.fragment.isNotEmpty) {
      final fragmentParams = Uri.splitQueryString(uri.fragment);
      if (fragmentParams.containsKey('error')) {
        throw OAuthException(
          fragmentParams['error_description'] ??
              fragmentParams['error'] ??
              'Authorization denied by user.',
        );
      }
      if (fragmentParams.containsKey('access_token')) {
        return fragmentParams['access_token'];
      }
    }

    if (uri.queryParameters.containsKey('error')) {
      throw OAuthException(
        uri.queryParameters['error_description'] ??
            uri.queryParameters['error'] ??
            'Authorization denied by user.',
      );
    }

    if (uri.queryParameters.containsKey('access_token')) {
      return uri.queryParameters['access_token'];
    }

    return null;
  }

  /// Listens for OAuth redirect callbacks (e.g. anilov://auth#access_token=...).
  void listenForRedirects({
    required void Function(String token) onTokenReceived,
    required void Function(String error) onError,
  }) {
    _linkSubscription?.cancel();
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        if (uri.scheme == defaultRedirectScheme && uri.host == defaultRedirectHost) {
          try {
            final token = extractAccessToken(uri);
            if (token != null && token.isNotEmpty) {
              onTokenReceived(token);
            }
          } on OAuthException catch (e) {
            onError(e.message);
          } catch (e) {
            onError('Unexpected OAuth redirect error: $e');
          }
        }
      },
      onError: (err) {
        onError('Deep link error: $err');
      },
    );
  }

  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }
}
