import 'package:dio/dio.dart';
import '../../../core/utils/device_id_manager.dart';
import '../local/token_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserApi {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['BASE_URL'] ?? '',
      contentType: 'application/json',
    ),
  );


  /// ✅ 내 정보 조회 API
  static Future<Map<String, dynamic>> fetchMe() async {
    final deviceId = await DeviceIdManager.getDeviceId();
    final access = await TokenStorage.getAccessToken();

    // ✅ 디버깅용 로그 추가
    print('-----------------------------');
    print('🧩 [DEBUG] accessToken: $access');
    print('🧩 [DEBUG] deviceId: $deviceId');
    print('-----------------------------');

    try {
      final resp = await _dio.get(
        '/api/users/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer $access',
            'X-Device-Id': deviceId,
          },
        ),
      );

      print('✅ [fetchMe] response: ${resp.data}');
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

      // ✅ 디버깅용 로그 추가
      print('-----------------------------');
      print('🧩 [DEBUG] accessToken: $access');
      print('🧩 [DEBUG] refreshToken: $refresh');
      print('🧩 [DEBUG] deviceId: $deviceId');
      print('-----------------------------');

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

      // ✅ 응답 코드 출력
      print('✅ [logout] statusCode: ${response.statusCode}');
      print('✅ [logout] response: ${response.data}');

      // ✅ 204 OK (성공 시 토큰 제거)
      if (response.statusCode == 204) {
        await TokenStorage.clearTokens();
      }

      return response.statusCode ?? 500;
    } catch (e) {
      print('❌ logout error: $e');
      return 500;
    }
  }
}
