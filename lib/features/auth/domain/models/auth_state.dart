import 'anilist_user.dart';

enum AuthStatus {
  unauthenticated,
  authenticating,
  authenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final AniListUser? user;
  final String? accessToken;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.user,
    this.accessToken,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated && accessToken != null && accessToken!.isNotEmpty;
  bool get isLoading => status == AuthStatus.authenticating;

  AuthState copyWith({
    AuthStatus? status,
    AniListUser? Function()? user,
    String? Function()? accessToken,
    String? Function()? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user != null ? user() : this.user,
      accessToken: accessToken != null ? accessToken() : this.accessToken,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          user == other.user &&
          accessToken == other.accessToken &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      status.hashCode ^ user.hashCode ^ accessToken.hashCode ^ errorMessage.hashCode;
}
