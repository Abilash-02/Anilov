import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:anilov/features/auth/domain/models/anilist_user.dart';

abstract class AuthStorage {
  Future<String?> getAccessToken();
  Future<void> saveAccessToken(String token);
  Future<void> deleteAccessToken();

  Future<AniListUser?> getUser();
  Future<void> saveUser(AniListUser user);
  Future<void> deleteUser();

  Future<String?> getClientId();
  Future<void> saveClientId(String clientId);

  Future<void> clearAll();
}

class SecureAuthStorage implements AuthStorage {
  static const String _keyAccessToken = 'anilov_oauth_access_token';
  static const String _keyUser = 'anilov_oauth_user';
  static const String _keyClientId = 'anilov_oauth_client_id';

  final FlutterSecureStorage _storage;

  SecureAuthStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  @override
  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _keyAccessToken);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
  }

  @override
  Future<void> deleteAccessToken() async {
    await _storage.delete(key: _keyAccessToken);
  }

  @override
  Future<AniListUser?> getUser() async {
    try {
      final jsonStr = await _storage.read(key: _keyUser);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return AniListUser.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveUser(AniListUser user) async {
    final jsonStr = jsonEncode(user.toJson());
    await _storage.write(key: _keyUser, value: jsonStr);
  }

  @override
  Future<void> deleteUser() async {
    await _storage.delete(key: _keyUser);
  }

  @override
  Future<String?> getClientId() async {
    try {
      return await _storage.read(key: _keyClientId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveClientId(String clientId) async {
    await _storage.write(key: _keyClientId, value: clientId);
  }

  @override
  Future<void> clearAll() async {
    try {
      await _storage.delete(key: _keyAccessToken);
      await _storage.delete(key: _keyUser);
    } catch (_) {}
  }
}

class InMemoryAuthStorage implements AuthStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> getAccessToken() async => _data['access_token'];

  @override
  Future<void> saveAccessToken(String token) async {
    _data['access_token'] = token;
  }

  @override
  Future<void> deleteAccessToken() async {
    _data.remove('access_token');
  }

  @override
  Future<AniListUser?> getUser() async {
    final raw = _data['user'];
    if (raw == null) return null;
    return AniListUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> saveUser(AniListUser user) async {
    _data['user'] = jsonEncode(user.toJson());
  }

  @override
  Future<void> deleteUser() async {
    _data.remove('user');
  }

  @override
  Future<String?> getClientId() async => _data['client_id'];

  @override
  Future<void> saveClientId(String clientId) async {
    _data['client_id'] = clientId;
  }

  @override
  Future<void> clearAll() async {
    _data.remove('access_token');
    _data.remove('user');
  }
}
