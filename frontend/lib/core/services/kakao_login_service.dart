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

  /// 카카오 로그인 (인가코드 → 백엔드 토큰 교환)
  static Future<bool> loginWithKakao() async {
    try {
      // 1. 인가코드 발급
      final code = await AuthCodeClient.instance.authorize(
        redirectUri: _redirectUri,
      );

      // 2. Device ID 가져오기
      final deviceId = await DeviceIdManager.getDeviceId();

      // 3. 백엔드로 로그인 요청
      final response = await _dio.post(
        '/api/auth/oauth/kakao',
        data: {
          'code': code,
          'redirectUri': _redirectUri,
        },
        options: Options(
          headers: {'X-Device-Id': deviceId},
          validateStatus: (status) => true,
        ),
      );

      // 4. 응답 처리
      if (response.statusCode == 200 && response.data['ok'] == true) {
        final data = response.data['data'];

        final accessToken = data['accessToken'];
        final refreshToken = data['refreshToken'];

        // 토큰 저장
        await TokenStorage.saveTokens(accessToken, refreshToken);

        return true;
      } else {
        return false;
      }
    } catch (_) {
      return false;
    }
  }
}
