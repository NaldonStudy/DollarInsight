import 'dart:convert'; // 디버깅용(필수는 아님)
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

    await _gsi.initialize(
      // 안드로이드용 클라이언트 ID
      clientId: dotenv.env['GOOGLE_ANDROID_CLIENT_ID'],
      // 백엔드가 만든 “웹 애플리케이션” 클라이언트 ID
      serverClientId: dotenv.env['GOOGLE_SERVER_CLIENT_ID'],
    );

    _initialized = true;
  }

  static Future<bool> loginWithGoogle() async {
    await _ensureInit();

    try {
      if (!_gsi.supportsAuthenticate()) {
        print('❌ authenticate() 미지원 플랫폼');
        return false;
      }

      final account = await _gsi.authenticate(
        scopeHint: const ['email', 'profile'],
      );

      if (account == null) {
        print('❌ account == null (사용자 취소 가능)');
        return false;
      }

      // ✅ 서버용 auth code 받기
      final codeResult =
      await account.authorizationClient.authorizeServer(const [
        'email',
        'profile',
      ]);

      print('⚡ authorizeServer type: ${codeResult.runtimeType}');
      print('⚡ authorizeServer: $codeResult');

      if (codeResult == null) {
        print('❌ authorizeServer 결과 없음');
        return false;
      }

      // ❗ 여기서 serverAuthCode 필드를 써야 함
      final String? code = codeResult.serverAuthCode;

      if (code == null || code.isEmpty) {
        print('❌ server auth code 없음');
        return false;
      }

      print('✅ server auth code: $code');

      final deviceId = await DeviceIdManager.getDeviceId();

      // ❗ [수정됨] Swagger에서 요구한 redirectUri 값
      // (이 값은 .env 파일로 옮겨 관리하는 것을 권장합니다.)
      const String redirectUri = 'com.dollarinsight.app:/oauth2redirect/google';

      final resp = await _dio.post(
        '/api/auth/oauth/google',
        // ❗ [수정됨] 'redirectUri' 필드 추가
        data: {
          'code': code,
          'redirectUri': redirectUri,
        },
        options: Options(headers: {'X-Device-Id': deviceId}),
      );

      final data = resp.data;
      if (data['ok'] == true) {
        await TokenStorage.saveTokens(
          data['data']['accessToken'],
          data['data']['refreshToken'],
        );
        print('✅ 백엔드 로그인 성공');
        return true;
      } else {
        print('❌ 로그인 실패: ${data['error']}');
        return false;
      }
    } on GoogleSignInException catch (e) {
      print('❌ GoogleSignInException: ${e.code} / ${e.description}');
      return false;
    } catch (e, st) {
      print('⚠️ 구글 로그인 중 오류: $e');
      print(st);
      return false;
    }
  }

  static Future<void> logout() async {
    await _gsi.signOut();
    await TokenStorage.clearTokens();
  }
}