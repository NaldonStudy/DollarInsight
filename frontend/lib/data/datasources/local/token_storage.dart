import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();

  /// ✅ 토큰 저장
  static Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'accessToken', value: accessToken);
    await _storage.write(key: 'refreshToken', value: refreshToken);
  }

  /// ✅ Access Token 조회
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: 'accessToken');
  }

  /// ✅ Refresh Token 조회
  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refreshToken');
  }

  static Future<void> saveAccessToken(String accessToken) async {
    await _storage.write(key: 'accessToken', value: accessToken);
  }

  /// ✅ 모든 토큰 삭제
  static Future<void> clearTokens() async {
    await _storage.deleteAll();
  }
}
