import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/utils/device_id_manager.dart';
import '../local/token_storage.dart';

class UserApi {
  /// ✅ BASE_URL 환경변수에서 읽기
  static String get baseUrl {
    final url = dotenv.env['BASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception('BASE_URL이 .env 파일에 설정되지 않았습니다.');
    }
    return url;
  }

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      contentType: 'application/json',
    ),
  );

  /// ✅ 내 정보 조회 API
  static Future<Map<String, dynamic>> fetchMe() async {
    final deviceId = await DeviceIdManager.getDeviceId();
    final access = await TokenStorage.getAccessToken();

    try {
      final resp = await _dio.get(
        '/api/users/me',
        options: Options(
          headers: {'Authorization': 'Bearer $access', 'X-Device-Id': deviceId},
        ),
      );

      return resp.data['data'];
    } catch (e) {
      print("❌ [fetchMe] error: $e");
      rethrow;
    }
  }

  /// ✅ 로그아웃 API
  static Future<int> logout() async {
    try {
      final deviceId = await DeviceIdManager.getDeviceId();
      final access = await TokenStorage.getAccessToken();
      final refresh = await TokenStorage.getRefreshToken();

      final response = await _dio.post(
        '/api/auth/logout',
        options: Options(
          headers: {
            if (access != null) 'Authorization': 'Bearer $access',
            'X-Device-Id': deviceId,
            if (refresh != null) 'X-Refresh-Token': refresh,
          },
          validateStatus: (status) => true,
        ),
      );

      // ✅ 204 OK (성공)
      if (response.statusCode == 204) {
        await TokenStorage.clearTokens(); // 저장된 토큰 제거
      }

      return response.statusCode ?? 500;
    } catch (e) {
      print('❌ logout error: $e');
      return 500;
    }
  }
}
