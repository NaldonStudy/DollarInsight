import 'package:dio/dio.dart';
import '../../../core/utils/device_id_manager.dart';
import '../../../data/datasources/local/token_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthApi {
  /// ✅ BASE_URL 환경변수에서 읽기
  static String get baseUrl {
    final url = dotenv.env['BASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception('BASE_URL이 .env 파일에 설정되지 않았습니다.');
    }
    return url;
  }

  /// ✅ 인증 없이 호출 가능한 엔드포인트
  static bool _isAuthFree(String path) {
    return path.contains('/api/auth/signup') ||
        path.contains('/api/auth/login') ||
        path.contains('/api/auth/refresh');
  }

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      contentType: 'application/json',
      responseType: ResponseType.json,
    ),
  )..interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // ✅ 회원가입/로그인/리프레시는 Authorization 금지
        if (!_isAuthFree(options.path)) {
          final accessToken = await TokenStorage.getAccessToken();
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
        }
        return handler.next(options);
      },

            onError: (DioException e, handler) async {
              // ✅ auth-free 요청은 refresh 시도 금지
              if (_isAuthFree(e.requestOptions.path)) {
                return handler.next(e);
              }

              // ✅ 401 발생 시 refresh 진행
              if (e.response?.statusCode == 401) {
                try {
                  final newToken = await AuthApi.refreshAccessToken();

                  final RequestOptions req = e.requestOptions;
                  req.headers['Authorization'] = 'Bearer $newToken';

                  final retryResponse = await _dio.fetch(req);
                  return handler.resolve(retryResponse);
                } catch (_) {
                  return handler.next(e);
                }
              }

              return handler.next(e);
            },
          ),
        );

  /// ✅ X-Device-Id 헤더 생성
  static Future<Map<String, String>> _headers() async {
    final deviceId = await DeviceIdManager.getDeviceId();
    return {'X-Device-Id': deviceId};
  }

  // ---------------------------------------------------------------------------
  // ✅ 회원가입
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> signup({
    required String email,
    required String nickname,
    required String password,
    required bool pushEnabled,
  }) async {
    try {
      final resp = await _dio.post(
        '/api/auth/signup',
        data: {
          'email': email,
          'nickname': nickname,
          'password': password,
          'pushEnabled': pushEnabled,
        },
        options: Options(headers: await _headers()),
      );

      // ✅ 서버 구조: {ok, data:{accessToken, refreshToken}}
      final root = resp.data as Map<String, dynamic>? ?? {};
      final data = root['data'] as Map<String, dynamic>?;

      if (data == null) throw Exception('서버 응답에 data 필드가 없습니다.');

      final access = data['accessToken'];
      final refresh = data['refreshToken'];

      if (access is! String || refresh is! String) {
        throw Exception('토큰 응답 형식이 올바르지 않습니다.');
      }

      return {'accessToken': access, 'refreshToken': refresh};
    } on DioException catch (e) {
      final msg = e.response?.data?.toString() ?? '회원가입 실패';
      throw Exception(msg);
    }
  }

  // ---------------------------------------------------------------------------
  // ✅ 로그인
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final resp = await _dio.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
        options: Options(headers: await _headers()),
      );

      // ✅ 서버 구조 동일
      final root = resp.data as Map<String, dynamic>? ?? {};
      final data = root['data'] as Map<String, dynamic>?;

      if (data == null) throw Exception('서버 응답에 data 필드가 없습니다.');

      final access = data['accessToken'];
      final refresh = data['refreshToken'];

      if (access is! String || refresh is! String) {
        throw Exception('토큰 응답 형식이 올바르지 않습니다.');
      }

      return {'accessToken': access, 'refreshToken': refresh};
    } on DioException catch (e) {
      final msg = e.response?.data?.toString() ?? '로그인 실패';
      throw Exception(msg);
    }
  }

  // ---------------------------------------------------------------------------
  // ✅ Refresh Token → AccessToken 재발급
  // ---------------------------------------------------------------------------
  static Future<String> refreshAccessToken() async {
    try {
      final deviceId = await DeviceIdManager.getDeviceId();
      final refreshToken = await TokenStorage.getRefreshToken();

      if (refreshToken == null) {
        throw Exception('Refresh Token이 존재하지 않습니다.');
      }

      final resp = await _dio.post(
        '/api/auth/refresh',
        options: Options(
          headers: {'X-Device-Id': deviceId, 'X-Refresh-Token': refreshToken},
        ),
      );

      final root = resp.data as Map<String, dynamic>? ?? {};
      final data = root['data'] as Map<String, dynamic>?;

      if (data == null) throw Exception('refresh 응답에 data 필드가 없습니다.');

      final newAccessToken = data['accessToken'] as String?;

      if (newAccessToken == null) {
        throw Exception('리프레시 응답에 accessToken이 없습니다.');
      }

      await TokenStorage.saveAccessToken(newAccessToken);
      return newAccessToken;
    } on DioException catch (e) {
      final msg = e.response?.data?.toString() ?? '토큰 갱신 실패';
      throw Exception(msg);
    }
  }

  // ---------------------------------------------------------------------------
  // ✅ 회원 탈퇴 (DELETE /api/users/me)
  // ---------------------------------------------------------------------------
  static Future<bool> deleteMe() async {
    try {
      final deviceId = await DeviceIdManager.getDeviceId();

      final resp = await _dio.delete(
        '/api/users/me',
        options: Options(
          headers: {
            'X-Device-Id': deviceId,
            // Authorization은 interceptor가 자동 삽입
          },
        ),
      );

      return resp.statusCode == 204;
    } catch (e) {
      print("❌ 회원탈퇴 실패: $e");
      return false;
    }
  }
}
