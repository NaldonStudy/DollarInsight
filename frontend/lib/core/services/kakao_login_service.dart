// 📁 lib/core/services/kakao_login_service.dart
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../data/datasources/local/token_storage.dart';
import '../../core/utils/device_id_manager.dart';

class KakaoLoginService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['BASE_URL'] ?? '',
      contentType: 'application/json',
    ),
  );

  static final String _redirectUri = dotenv.env['KAKAO_REDIRECT_URI'] ?? '';

  /// ✅ 카카오 로그인 (인가코드 → 백엔드 토큰 교환)
  static Future<bool> loginWithKakao() async {
    try {
      // ✅ 1. 인가코드 발급
      final code = await AuthCodeClient.instance.authorize(
        redirectUri: _redirectUri,
      );
      print('🔑 [DEBUG] Kakao authorize code: $code');

      // ✅ 2. Device ID 가져오기 (SharedPreferences)
      final deviceId = await DeviceIdManager.getDeviceId();
      print('🪪 [DEBUG] X-Device-Id (to send): $deviceId');
      print('🪪 [DEBUG] redirectUri: $_redirectUri');

      // ✅ 3. 백엔드로 로그인 요청
      final response = await _dio.post(
        '/api/auth/oauth/kakao',
        data: {
          'code': code,
          'redirectUri': _redirectUri,
        },
        options: Options(
          headers: {
            'X-Device-Id': deviceId,
          },
          validateStatus: (status) => true, // 오류 상태코드도 예외로 던지지 않게
        ),
      );

      // ✅ 4. 실제 요청 헤더 & 응답 전체 로그 출력
      print('-----------------------------');
      print('📡 [DEBUG] Request Headers: ${response.requestOptions.headers}');
      print('📡 [DEBUG] Request URL: ${response.requestOptions.uri}');
      print('📦 [DEBUG] Response status: ${response.statusCode}');
      print('📦 [DEBUG] Response data: ${response.data}');
      print('-----------------------------');

      // ✅ 5. 응답 처리
      if (response.statusCode == 200 && response.data['ok'] == true) {
        final data = response.data['data'];

        final accessToken = data['accessToken'];
        final refreshToken = data['refreshToken'];

        // ✅ 토큰 저장
        await TokenStorage.saveTokens(accessToken, refreshToken);

        // ✅ 저장 확인
        final savedAccess = await TokenStorage.getAccessToken();
        final savedRefresh = await TokenStorage.getRefreshToken();

        print('🎉 [SUCCESS] 백엔드 로그인 성공');
        print('🧩 [DEBUG] saved accessToken: $savedAccess');
        print('🧩 [DEBUG] saved refreshToken: $savedRefresh');
        print('-----------------------------');
        return true;
      } else {
        print('❌ [ERROR] 서버 응답 오류');
        print('📦 Response status: ${response.statusCode}');
        print('📦 Response data: ${response.data}');
        print('-----------------------------');
        return false;
      }
    } catch (e) {
      print('⚠️ [EXCEPTION] 카카오 로그인 실패: $e');
      print('-----------------------------');
      return false;
    }
  }
}
