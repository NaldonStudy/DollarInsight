// 📁 lib/presentation/providers/password_change_provider.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/utils/device_id_manager.dart';
import '../../data/datasources/local/token_storage.dart';

class PasswordChangeProvider extends ChangeNotifier {
  final passwordController = TextEditingController();
  final passwordConfirmController = TextEditingController();

  // ✅ Dio 초기화 시 .env 사용
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['BASE_URL'] ?? '',
      contentType: 'application/json',
    ),
  );

  bool isLoading = false;
  String? passwordError;
  String? passwordConfirmError;

  /// ✅ 비밀번호 유효성 검사
  void validatePassword(String value) {
    if (value.isEmpty) {
      passwordError = "비밀번호를 입력해주세요.";
    } else if (value.length < 8) {
      passwordError = "비밀번호는 8자 이상이어야 합니다.";
    } else if (!RegExp(r'[A-Za-z]').hasMatch(value) ||
        !RegExp(r'\d').hasMatch(value) ||
        !RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) {
      passwordError = "영문, 숫자, 특수문자를 모두 포함해야 합니다.";
    } else {
      passwordError = null;
    }

    // 비밀번호 확인도 다시 검증
    if (passwordConfirmController.text.isNotEmpty) {
      validatePasswordConfirm(passwordConfirmController.text);
    }
    notifyListeners();
  }

  /// ✅ 비밀번호 확인 유효성 검사
  void validatePasswordConfirm(String value) {
    if (value.isEmpty) {
      passwordConfirmError = "비밀번호 확인을 입력해주세요.";
    } else if (value != passwordController.text) {
      passwordConfirmError = "비밀번호가 일치하지 않습니다.";
    } else {
      passwordConfirmError = null;
    }
    notifyListeners();
  }

  /// ✅ 전체 유효성 검사
  bool validateAll() {
    validatePassword(passwordController.text);
    validatePasswordConfirm(passwordConfirmController.text);
    return passwordError == null && passwordConfirmError == null;
  }

  /// ✅ 비밀번호 변경 API 요청 (PATCH /api/users/me/password)
  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      isLoading = true;
      notifyListeners();

      final token = await TokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('Access token이 존재하지 않습니다. 다시 로그인해주세요.');
      }

      final bearerToken = token.startsWith('Bearer ') ? token : 'Bearer $token';
      final deviceId = await DeviceIdManager.getDeviceId();

      debugPrint('🔑 access token: $bearerToken');
      debugPrint('📱 deviceId: $deviceId');

      final response = await _dio.patch(
        '/api/users/me/password',
        options: Options(
          headers: {
            'Authorization': bearerToken,
            'X-Device-Id': deviceId,
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
      );

      if (response.statusCode == 204) {
        debugPrint('✅ 비밀번호 변경 성공');
      } else {
        throw Exception('비밀번호 변경 실패 (${response.statusCode})');
      }
    } on DioException catch (e) {
      debugPrint('❌ 비밀번호 변경 오류: ${e.response?.data}');
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
