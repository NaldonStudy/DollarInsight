import 'package:http/http.dart' as http;
import 'dart:convert';

/// API 클라이언트
/// 모든 HTTP 요청을 처리하는 클라이언트
class ApiClient {
  // TODO: 실제 API URL로 변경
  static const String baseUrl = 'https://api.example.com';

  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// GET 요청
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: queryParameters,
      );

      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('GET 요청 실패: $e');
    }
  }

  /// POST 요청
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
        body: body != null ? json.encode(body) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('POST 요청 실패: $e');
    }
  }

  /// PUT 요청
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      final response = await _client.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
        body: body != null ? json.encode(body) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('PUT 요청 실패: $e');
    }
  }

  /// DELETE 요청
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      final response = await _client.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('DELETE 요청 실패: $e');
    }
  }

  /// HTTP 응답 처리
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return json.decode(utf8.decode(response.bodyBytes));
    } else if (response.statusCode == 404) {
      throw Exception('리소스를 찾을 수 없습니다 (404)');
    } else if (response.statusCode == 401) {
      throw Exception('인증이 필요합니다 (401)');
    } else if (response.statusCode == 403) {
      throw Exception('접근이 거부되었습니다 (403)');
    } else if (response.statusCode >= 500) {
      throw Exception('서버 오류가 발생했습니다 (${response.statusCode})');
    } else {
      throw Exception('요청 실패: ${response.statusCode}');
    }
  }

  /// 클라이언트 종료
  void dispose() {
    _client.close();
  }
}
