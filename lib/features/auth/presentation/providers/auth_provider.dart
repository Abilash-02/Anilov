import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anilov/features/anime/data/anilist_client.dart';
import 'package:anilov/features/auth/data/anilist_oauth_service.dart';
import 'package:anilov/features/auth/data/auth_repository.dart';
import 'package:anilov/features/auth/data/auth_storage.dart';
import 'package:anilov/features/auth/domain/models/anilist_user.dart';
import 'package:anilov/features/auth/domain/models/auth_state.dart';

final authStorageProvider = Provider<AuthStorage>((ref) {
  return SecureAuthStorage();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AniListAuthRepository();
});

final oauthServiceProvider = Provider<AniListOAuthService>((ref) {
  final service = AniListOAuthService();
  ref.onDispose(() => service.dispose());
  return service;
});

class AuthNotifier extends Notifier<AuthState> {
  late final AuthStorage _storage;
  late final AuthRepository _repository;
  late final AniListOAuthService _oauthService;

  @override
  AuthState build() {
    _storage = ref.watch(authStorageProvider);
    _repository = ref.watch(authRepositoryProvider);
    _oauthService = ref.watch(oauthServiceProvider);

    // Initial silent check
    _initAuth();

    return const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> _initAuth() async {
    final token = await _storage.getAccessToken();
    final cachedUser = await _storage.getUser();

    if (token != null && token.isNotEmpty) {
      if (cachedUser != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: cachedUser,
          accessToken: token,
        );
      }

      // Verify and refresh profile in background
      try {
        final liveUser = await _repository.fetchViewer(token);
        await _storage.saveUser(liveUser);
        state = AuthState(
          status: AuthStatus.authenticated,
          user: liveUser,
          accessToken: token,
        );
      } on UnauthorizedException {
        // Token expired or invalid
        await logout();
      } catch (_) {
        // Offline: retain cached authentication state
      }
    }
  }

  Future<String?> getClientId() async {
    final stored = await _storage.getClientId();
    if (stored != null && stored.trim().isNotEmpty) {
      return stored.trim();
    }
    if (AniListOAuthService.environmentClientId.isNotEmpty) {
      return AniListOAuthService.environmentClientId;
    }
    return null;
  }

  Future<void> setClientId(String clientId) async {
    await _storage.saveClientId(clientId.trim());
  }

  Future<bool> loginWithToken(String token) async {
    state = state.copyWith(status: AuthStatus.authenticating);
    try {
      final user = await _repository.fetchViewer(token);
      await _storage.saveAccessToken(token);
      await _storage.saveUser(user);

      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        accessToken: token,
      );
      return true;
    } on UnauthorizedException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: () => e.message,
      );
      return false;
    } on NetworkException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: () => e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: () => 'Failed to log in with AniList: $e',
      );
      return false;
    }
  }

  Future<String?> startOAuthFlow({
    String? explicitClientId,
    required Future<bool> Function(String authUrl) launchUrlCallback,
  }) async {
    final clientId = explicitClientId ?? await getClientId();
    if (clientId == null || clientId.isEmpty) {
      const err = 'AniList Client ID is required. Please configure it in Settings -> AniList Sync or pass --dart-define=ANILIST_CLIENT_ID=...';
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: () => err,
      );
      return err;
    }

    state = state.copyWith(status: AuthStatus.authenticating);

    _oauthService.listenForRedirects(
      onTokenReceived: (token) {
        loginWithToken(token);
      },
      onError: (errMsg) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: () => errMsg,
        );
      },
    );

    final url = AniListOAuthService.buildAuthorizationUrl(clientId);
    final launched = await launchUrlCallback(url);
    if (!launched) {
      const err = 'Could not open AniList authorization page.';
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: () => err,
      );
      return err;
    }
    return null;
  }

  void handleRedirectUri(Uri uri) {
    try {
      final token = AniListOAuthService.extractAccessToken(uri);
      if (token != null && token.isNotEmpty) {
        loginWithToken(token);
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: () => 'No access token received from AniList callback.',
        );
      }
    } on OAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: () => e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: () => 'OAuth error: $e',
      );
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
