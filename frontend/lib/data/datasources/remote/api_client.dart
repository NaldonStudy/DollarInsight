import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../local/token_storage.dart';
import '../../../core/utils/device_id_manager.dart';

/// API 클라이언트
/// 모든 HTTP 요청을 처리하는 클라이언트
/// Dio + Interceptor로 자동 인증 및 토큰 갱신 처리
class ApiClient {
  static String get baseUrl {
    final url = dotenv.env['BASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception('BASE_URL이 .env 파일에 설정되지 않았습니다.');
    }
    return url;
  }

  late final Dio _dio;

  ApiClient({Dio? dio}) {
    _dio = dio ?? _createDio();
  }

  /// 인증이 필요없는 엔드포인트들 (화이트리스트)
  static bool _isAuthFree(String path) {
    return path.contains('/api/auth/signup') ||
           path.contains('/api/auth/login') ||
           path.contains('/api/auth/refresh') ||
           path.contains('/api/auth/oauth/') ||
           path.contains('/api/public/');
  }

  /// Dio 인스턴스 생성 (AuthApi와 동일한 패턴)
  static Dio _createDio() {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        // AI 응답 시간이 길 수 있으므로 수신 타임아웃을 60초로 늘림
        receiveTimeout: const Duration(seconds: 60),
        contentType: 'application/json',
        responseType: ResponseType.json,
      ),
    )..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            // 1. Authorization 헤더 추가 (화이트리스트가 아닌 경우만)
            if (!_isAuthFree(options.path)) {
              final accessToken = await TokenStorage.getAccessToken();
              if (accessToken != null) {
                options.headers['Authorization'] = 'Bearer $accessToken';
              }
            }

            // 2. X-Device-Id 헤더 추가 (모든 요청에 추가)
            final deviceId = await DeviceIdManager.getDeviceId();
            options.headers['X-Device-Id'] = deviceId;

            return handler.next(options);
          },
          onError: (DioException e, handler) async {
            // 401 에러 시 토큰 갱신 시도
            if (e.response?.statusCode == 401) {
              try {
                // Refresh Token으로 새 AccessToken 발급
                final refreshToken = await TokenStorage.getRefreshToken();
                if (refreshToken != null) {
                  final deviceId = await DeviceIdManager.getDeviceId();
                  final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));

                  final refreshResp = await refreshDio.post(
                    '/api/auth/refresh',
                    options: Options(headers: {
                      'X-Device-Id': deviceId,
                      'X-Refresh-Token': refreshToken,
                    }),
                  );

                  final root = refreshResp.data as Map<String, dynamic>? ?? {};
                  final data = root['data'] as Map<String, dynamic>?;
                  final newAccessToken = data?['accessToken'] as String?;

                  if (newAccessToken != null) {
                    await TokenStorage.saveAccessToken(newAccessToken);

                    // 원래 요청 재시도
                    final RequestOptions req = e.requestOptions;
                    req.headers['Authorization'] = 'Bearer $newAccessToken';

                    final retryDio = Dio(BaseOptions(baseUrl: baseUrl));
                    final retryResponse = await retryDio.fetch(req);
                    return handler.resolve(retryResponse);
                  }
                }
              } catch (_) {
                // Refresh 실패 시 원래 에러 반환
                return handler.next(e);
              }
            }
            return handler.next(e);
          },
        ),
      );
  }

  /// GET 요청
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('GET 요청 실패: $e');
    }
  }

  /// POST 요청
  Future<dynamic> post(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    try {
      // 디버깅용 로그 추가
      print('🌐 POST 요청: $endpoint');
      print('📝 요청 본문: $body');
      print('📋 요청 헤더: ${headers ?? "기본 헤더만 사용"}');
      
      final response = await _dio.post(
        endpoint,
        data: body,
        options: Options(headers: headers),
      );

      print('✅ 응답 성공: ${response.statusCode}');
      print('📥 응답 데이터: ${response.data}');
      
      return _handleResponse(response);
    } on DioException catch (dioError) {
      print('❌ DioException 발생:');
      print('   상태 코드: ${dioError.response?.statusCode}');
      print('   에러 메시지: ${dioError.message}');
      print('   응답 데이터: ${dioError.response?.data}');
      throw Exception('POST 요청 실패: $dioError');
    } catch (e) {
      print('❌ 일반 예외 발생: $e');
      throw Exception('POST 요청 실패: $e');
    }
  }

  /// PUT 요청
  Future<dynamic> put(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: body,
        options: Options(headers: headers),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('PUT 요청 실패: $e');
    }
  }

  Future<dynamic> patch(
      String endpoint, {
        Map<String, String>? headers,
        Map<String, dynamic>? body,
      }) async {
    try {
      final response = await _dio.patch(
        endpoint,
        data: body,
        options: Options(headers: headers),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('PATCH 요청 실패: $e');
    }
  }

  /// DELETE 요청
  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.delete(
        endpoint,
        options: Options(headers: headers),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('DELETE 요청 실패: $e');
    }
  }

  /// HTTP 응답 처리 - List 응답도 지원하도록 수정
  dynamic _handleResponse(Response response) {
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      // Dio는 자동으로 JSON을 파싱해줌
      return response.data; // 직접 반환 (List든 Map이든 상관없이)
    } else if (response.statusCode == 404) {
      throw Exception('리소스를 찾을 수 없습니다 (404)');
    } else if (response.statusCode == 401) {
      throw Exception('인증이 필요합니다 (401)');
    } else if (response.statusCode == 403) {
      throw Exception('접근이 거부되었습니다 (403)');
    } else if (response.statusCode != null && response.statusCode! >= 500) {
      throw Exception('서버 오류가 발생했습니다 (${response.statusCode})');
    } else {
      throw Exception('요청 실패: ${response.statusCode}');
    }
  }

  /// 클라이언트 종료
  void dispose() {
    _dio.close();
  }
}
