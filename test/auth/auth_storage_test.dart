import 'package:flutter_test/flutter_test.dart';
import 'package:anilov/features/auth/data/auth_storage.dart';
import 'package:anilov/features/auth/domain/models/anilist_user.dart';

void main() {
  group('AuthStorage Tests', () {
    late InMemoryAuthStorage storage;

    setUp(() {
      storage = InMemoryAuthStorage();
    });

    test('stores, retrieves, and deletes access token', () async {
      expect(await storage.getAccessToken(), isNull);

      await storage.saveAccessToken('test_token_123');
      expect(await storage.getAccessToken(), equals('test_token_123'));

      await storage.deleteAccessToken();
      expect(await storage.getAccessToken(), isNull);
    });

    test('stores, retrieves, and deletes user profile', () async {
      expect(await storage.getUser(), isNull);

      const user = AniListUser(
        id: 9999,
        name: 'OtakuMaster',
        avatarUrl: 'https://example.com/avatar.png',
      );

      await storage.saveUser(user);
      final retrieved = await storage.getUser();
      expect(retrieved, isNotNull);
      expect(retrieved?.id, equals(9999));
      expect(retrieved?.name, equals('OtakuMaster'));
      expect(retrieved?.avatarUrl, equals('https://example.com/avatar.png'));

      await storage.deleteUser();
      expect(await storage.getUser(), isNull);
    });

    test('stores and retrieves custom client ID', () async {
      expect(await storage.getClientId(), isNull);

      await storage.saveClientId('client_4242');
      expect(await storage.getClientId(), equals('client_4242'));
    });

    test('clearAll removes token and user profile', () async {
      await storage.saveAccessToken('token_abc');
      await storage.saveUser(const AniListUser(id: 1, name: 'User1'));

      await storage.clearAll();

      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getUser(), isNull);
    });
  });
}
