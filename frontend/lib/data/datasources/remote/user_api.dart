import 'package:dio/dio.dart';
import '../../../core/utils/device_id_manager.dart';
import '../local/token_storage.dart';

class UserApi {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://k13b205.p.ssafy.io',
      contentType: 'application/json',
    ),
  );

  /// ✅ 내 정보 조회 API
  static Future<Map<String, dynamic>> fetchMe() async {
    final deviceId = await DeviceIdManager.getDeviceId();
    final access = await TokenStorage.getAccessToken();

    final resp = await _dio.get(
      '/api/users/me',
      options: Options(
        headers: {
          'Authorization': 'Bearer $access',
          'X-Device-Id': deviceId,
        },
      ),
    );

    final data = resp.data['data'];
    return data;
  }
}
