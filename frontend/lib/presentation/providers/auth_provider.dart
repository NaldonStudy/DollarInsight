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
      final res = await AuthApi.signup(
        email: email,
        nickname: nickname,
        password: password,
        pushEnabled: pushEnabled,
      );

      await TokenStorage.saveTokens(
        res['accessToken'],
        res['refreshToken'],
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
      final res = await AuthApi.login(
        email: email,
        password: password,
      );

      await TokenStorage.saveTokens(
        res['accessToken'],
        res['refreshToken'],
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
      final newToken = await AuthApi.refreshAccessToken();
      return newToken;
    } catch (e) {
      rethrow;
    }
  }

}
