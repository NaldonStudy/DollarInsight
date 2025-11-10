import 'package:flutter/material.dart';
import '../../data/datasources/remote/auth_api.dart';
import '../../data/datasources/local/token_storage.dart';

class AuthProvider with ChangeNotifier {
  bool isLoading = false;

  /// ✅ 회원가입
  Future<void> signup({
    required String email,
    required String nickname,
    required String password,
    required bool pushEnabled,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      // ✅ AuthApi는 {accessToken, refreshToken} 형태로 반환함
      final tokens = await AuthApi.signup(
        email: email,
        nickname: nickname,
        password: password,
        pushEnabled: pushEnabled,
      );

      // ✅ 토큰 저장
      await TokenStorage.saveTokens(
        tokens['accessToken'],
        tokens['refreshToken'],
      );
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ 로그인
  Future<void> login({
    required String email,
    required String password,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      // ✅ 동일 구조
      final tokens = await AuthApi.login(
        email: email,
        password: password,
      );

      await TokenStorage.saveTokens(
        tokens['accessToken'],
        tokens['refreshToken'],
      );
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ AccessToken 재발급
  Future<String> refresh() async {
    try {
      return await AuthApi.refreshAccessToken();
    } catch (e) {
      rethrow;
    }
  }
}
