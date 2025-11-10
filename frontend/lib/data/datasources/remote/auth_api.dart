import 'package:dio/dio.dart';
import '../../../core/utils/device_id_manager.dart';
import '../../../data/datasources/local/token_storage.dart';

class AuthApi {
  static final Dio _dio =
      Dio(
          BaseOptions(
            baseUrl: "http://k13b205.p.ssafy.io",
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
            contentType: "application/json",
            responseType: ResponseType.json,
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              final accessToken = await TokenStorage.getAccessToken();
              if (accessToken != null) {
                options.headers["Authorization"] = "Bearer $accessToken";
              }
              return handler.next(options);
            },

            onError: (DioException e, handler) async {
              // ✅ AccessToken이 없으면 refresh 시도하지 않음 → 회원가입/로그인 보호
              final hasToken = (await TokenStorage.getAccessToken()) != null;
              if (!hasToken) {
                return handler.next(e);
              }

              // ✅ AccessToken이 있고 401이 발생한 경우에만 refresh 진행
              if (e.response?.statusCode == 401) {
                try {
                  final newToken = await AuthApi.refreshAccessToken();
                  final RequestOptions req = e.requestOptions;

                  req.headers["Authorization"] = "Bearer $newToken";

                  final retryResponse = await _dio.fetch(req);
                  return handler.resolve(retryResponse);

                } catch (err) {
                  return handler.next(e);
                }
              }

              return handler.next(e);
            },
          ),
        );

  /// ✅ 공통: Device-ID 헤더 생성
  static Future<Map<String, String>> _headers() async {
    final deviceId = await DeviceIdManager.getDeviceId();
    return {"X-Device-Id": deviceId};
  }

  /// ✅ 회원가입
  static Future<Map<String, dynamic>> signup({
    required String email,
    required String nickname,
    required String password,
    required bool pushEnabled,
  }) async {
    try {
      final response = await _dio.post(
        "/api/auth/signup",
        data: {
          "email": email,
          "nickname": nickname,
          "password": password,
          "pushEnabled": pushEnabled,
        },
        options: Options(headers: await _headers()),
      );

      return response.data;
    } on DioException catch (e) {
      print("⚠️ Dio Error: ${e.message}");
      print("⚠️ Response: ${e.response}");
      print("⚠️ Data: ${e.response?.data}");
      throw Exception("회원가입 실패");
    }

  }

  /// ✅ 로그인
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        "/api/auth/login",
        data: {"email": email, "password": password},
        options: Options(headers: await _headers()),
      );

      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data.toString() ?? "로그인 실패");
    }
  }

  /// ✅ refreshToken → accessToken 재발급
  static Future<String> refreshAccessToken() async {
    try {
      final deviceId = await DeviceIdManager.getDeviceId();
      final refreshToken = await TokenStorage.getRefreshToken();

      if (refreshToken == null) {
        throw Exception("Refresh Token이 존재하지 않습니다.");
      }

      final response = await _dio.post(
        "/api/auth/refresh",
        options: Options(
          headers: {"X-Device-Id": deviceId, "X-Refresh-Token": refreshToken},
        ),
      );

      final newAccessToken = response.data["accessToken"];

      // ✅ 새 AccessToken 저장
      await TokenStorage.saveAccessToken(newAccessToken);

      return newAccessToken;
    } on DioException catch (e) {
      throw Exception(e.response?.data.toString() ?? "토큰 갱신 실패");
    }
  }
}
