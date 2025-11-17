import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/utils/device_id_manager.dart';
import '../local/token_storage.dart';
import '../remote/api_client.dart';

class UserApi {

  /// 🔥 ApiClient 인스턴스 (PATCH 요청 등에 사용)
  static final ApiClient _client = ApiClient();

  /// ✅ BASE_URL 환경변수에서 읽기
  static String get baseUrl {
    final url = dotenv.env['BASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception('BASE_URL이 .env 파일에 설정되지 않았습니다.');
    }
    return url;
  }

  /// 🔥 기존 Dio는 fetchMe, logout 에서만 사용
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

      if (response.statusCode == 204) {
        await TokenStorage.clearTokens();
      }

      return response.statusCode ?? 500;
    } catch (e) {
      print('❌ logout error: $e');
      return 500;
    }
  }

  /// 🔥 닉네임 변경 API
  /// 🔥 닉네임 변경 API
  static Future<bool> updateNickname(String newNickname) async {
    try {
      final response = await _dio.patch(
        '/api/users/me/nickname',
        data: {'nickname': newNickname},
        options: Options(
          headers: {
            'Authorization': 'Bearer ${await TokenStorage.getAccessToken()}',
            'X-Device-Id': await DeviceIdManager.getDeviceId(),
          },
          validateStatus: (status) => true, // 우리가 직접 처리
        ),
      );

      // 🔥 닉네임 변경 성공 (204)
      if (response.statusCode == 204) {
        return true;
      }

      print("❌ 닉네임 변경 실패 응답: ${response.data}");
      return false;
    } catch (e) {
      print("❌ [updateNickname] $e");
      return false;
    }
  }

}
