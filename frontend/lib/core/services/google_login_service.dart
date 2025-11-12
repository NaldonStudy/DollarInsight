import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../data/datasources/local/token_storage.dart';
import '../../core/utils/device_id_manager.dart';

class GoogleLoginService {
  static final GoogleSignIn _gsi = GoogleSignIn.instance;

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['BASE_URL'] ?? '',
      contentType: 'application/json',
    ),
  );

  static bool _initialized = false;
  static Future<void> _ensureInit() async {
    if (_initialized) return;
    // serverClientId: Google Cloud 콘솔의 "웹 애플리케이션" 클라이언트 ID (백엔드 교환용)
    await _gsi.initialize(
      // Android/iOS는 clientId 생략 가능. serverClientId는 권장.
      serverClientId: dotenv.env['GOOGLE_SERVER_CLIENT_ID'],
    );
    _initialized = true;
  }

  static Future<bool> loginWithGoogle() async {
    await _ensureInit();

    try {
      if (_gsi.supportsAuthenticate()) {
        final account = await _gsi.authenticate(
          scopeHint: const ['email', 'profile'],
        );

        // ✅ serverAuthCode 바로 문자열로 받기
        final code = await account.authorizationClient.authorizeServer(
          const ['email', 'profile'],
        );

        if (code == null) {
          print('❌ server auth code 없음');
          return false;
        }

        final deviceId = await DeviceIdManager.getDeviceId();

        final resp = await _dio.post(
          '/api/auth/oauth/google',
          data: {'code': code},
          options: Options(headers: {'X-Device-Id': deviceId}),
        );

        final data = resp.data;
        if (data['ok'] == true) {
          await TokenStorage.saveTokens(
            data['data']['accessToken'],
            data['data']['refreshToken'],
          );
          print('✅ 로그인 성공');
          return true;
        } else {
          print('❌ 로그인 실패: ${data['error']}');
          return false;
        }
      } else {
        print('❌ authenticate() 미지원 플랫폼');
        return false;
      }
    } on GoogleSignInException catch (e) {
      print('❌ GoogleSignInException: ${e.code} / ${e.description}');
      return false;
    } catch (e) {
      print('⚠️ 구글 로그인 중 오류: $e');
      return false;
    }
  }


  static Future<void> logout() async {
    await _gsi.signOut();
    await TokenStorage.clearTokens();
  }
}
