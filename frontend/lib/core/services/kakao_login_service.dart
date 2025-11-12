// 📁 lib/core/services/kakao_login_service.dart
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/local/token_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class KakaoLoginService {
  static final _dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['BASE_URL'] ?? '',
      contentType: 'application/json',
    ),
  );

  static final _redirectUri = dotenv.env['KAKAO_REDIRECT_URI'] ?? '';

  /// ✅ 디바이스 ID 관리 (없으면 새로 생성)
  static Future<String> _getDeviceId() async {
    String? id = await TokenStorage.getAccessToken(); // 잘못된 키면 별도 관리 필요
    if (id == null) {
      id = const Uuid().v4();
      await TokenStorage.saveAccessToken(id); // (만약 deviceId를 따로 저장하는 구조가 있다면 변경)
    }
    return id;
  }

  /// ✅ 카카오 로그인 (인가코드 → 백엔드 토큰 교환)
  static Future<bool> loginWithKakao() async {
    try {
      final code = await AuthCodeClient.instance.authorize(
        redirectUri: _redirectUri,
      );
      final deviceId = await _getDeviceId();

      final response = await _dio.post(
        '/api/auth/oauth/kakao',
        data: {
          'code': code,
          'redirectUri': _redirectUri,
        },
        options: Options(headers: {'X-Device-Id': deviceId}),
      );

      if (response.statusCode == 200 && response.data['ok'] == true) {
        final data = response.data['data'];
        await TokenStorage.saveTokens(data['accessToken'], data['refreshToken']); // ✅ 통합 호출
        print('🎉 백엔드 로그인 성공');
        return true;
      } else {
        print('❌ 서버 응답 오류: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('⚠️ 카카오 로그인 실패: $e');
      return false;
    }
  }
}
