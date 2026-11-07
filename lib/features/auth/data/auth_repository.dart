import 'package:anilov/features/anime/data/anilist_client.dart';
import 'package:anilov/features/auth/domain/models/anilist_user.dart';

abstract class AuthRepository {
  Future<AniListUser> fetchViewer(String accessToken);
}

class AniListAuthRepository implements AuthRepository {
  final AniListClient _client;

  AniListAuthRepository({AniListClient? client})
      : _client = client ?? AniListClient();

  static const String viewerQuery = '''
    query ViewerQuery {
      Viewer {
        id
        name
        avatar {
          large
          medium
        }
      }
    }
  ''';

  @override
  Future<AniListUser> fetchViewer(String accessToken) async {
    final data = await _client.postQuery(
      viewerQuery,
      authToken: accessToken,
      forceRefresh: true,
    );

    final viewer = data['Viewer'] as Map<String, dynamic>?;
    if (viewer == null) {
      throw const ApiException('Failed to retrieve AniList user profile.');
    }

    return AniListUser.fromJson(viewer);
  }
}
