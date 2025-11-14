// chat_api.dart
// 채팅 관련 API 호출을 담당하는 클래스

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'api_client.dart';
import '../../models/chat_model.dart';

/// 채팅 API 클라이언트
/// ApiClient를 사용하여 모든 채팅 관련 API 호출을 처리
class ChatApi {
  final ApiClient _apiClient;

  ChatApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// 채팅 세션 생성
  /// POST /api/chat/sessions
  Future<CreateSessionResponse> createSession(CreateSessionRequest request) async {
    try {
      final response = await _apiClient.post(
        '/api/chat/sessions',
        body: request.toJson(),
      );

      // Swagger 스펙에 따르면 직접적인 객체 응답 (data wrapper 없음)
      return CreateSessionResponse.fromJson(response);
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to create chat session');
    } catch (e) {
      throw ChatApiException('Unexpected error while creating session: $e');
    }
  }

  /// 사용자 메시지 등록
  /// POST /api/chat/sessions/{sid}/messages
  Future<AppendMessageResponse> appendMessage(
      String sessionId,
      AppendMessageRequest request,
      ) async {
    try {
      final response = await _apiClient.post(
        '/api/chat/sessions/$sessionId/messages',
        body: request.toJson(),
      );

      return AppendMessageResponse.fromJson(response);
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to send message');
    } catch (e) {
      throw ChatApiException('Unexpected error while sending message: $e');
    }
  }

  /// 진행 중인 스트림 중단
  /// POST /api/chat/sessions/{sid}/interrupt
  Future<void> interrupt(String sessionId) async {
    try {
      await _apiClient.post('/api/chat/sessions/$sessionId/interrupt');
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to interrupt stream');
    } catch (e) {
      throw ChatApiException('Unexpected error while interrupting stream: $e');
    }
  }

  /// 일시 중단된 스트림 재개
  /// POST /api/chat/sessions/{sid}/control/resume
  Future<void> resume(String sessionId) async {
    try {
      await _apiClient.post('/api/chat/sessions/$sessionId/control/resume');
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to resume stream');
    } catch (e) {
      throw ChatApiException('Unexpected error while resuming stream: $e');
    }
  }

  /// 발화 간격 변경
  /// POST /api/chat/sessions/{sid}/control/pace
  Future<void> changePace(String sessionId, ChangePaceRequest request) async {
    try {
      await _apiClient.post(
        '/api/chat/sessions/$sessionId/control/pace',
        body: request.toJson(),
      );
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to change pace');
    } catch (e) {
      throw ChatApiException('Unexpected error while changing pace: $e');
    }
  }

  /// 채팅 히스토리 조회 (v1 - 간단 조회)
  /// GET /api/chat/sessions/{sid}/history
  Future<HistoryResponse> getHistory(String sessionId, {int limit = 50}) async {
    try {
      final response = await _apiClient.get(
        '/api/chat/sessions/$sessionId/history',
        queryParameters: {'limit': limit},
      );

      return HistoryResponse.fromJson(response);
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to get chat history');
    } catch (e) {
      throw ChatApiException('Unexpected error while getting history: $e');
    }
  }

  /// 채팅 히스토리 조회 (v2 - 커서 기반 페이지네이션)
  /// GET /api/chat/sessions/{sid}/history2
  Future<HistoryCursorResponse> getHistoryWithCursor(
      String sessionId, {
        int limit = 50,
        String? cursor,
      }) async {
    try {
      final queryParameters = <String, dynamic>{'limit': limit};
      if (cursor != null) {
        queryParameters['cursor'] = cursor;
      }

      final response = await _apiClient.get(
        '/api/chat/sessions/$sessionId/history2',
        queryParameters: queryParameters,
      );

      return HistoryCursorResponse.fromJson(response);
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to get paginated chat history');
    } catch (e) {
      throw ChatApiException('Unexpected error while getting paginated history: $e');
    }
  }

  /// SSE 스트림 연결을 위한 Dio 인스턴스 생성
  /// GET /api/chat/sessions/{sid}/stream
  ///
  /// SSE 연결에 필요한 설정된 Dio 인스턴스를 반환합니다.
  /// 실제 SSE 스트림 처리는 상위 레이어에서 담당해야 합니다.
  Future<Dio> createSSEDio() async {
    try {
      final dio = Dio();

      // 기본 설정
      dio.options.baseUrl = ApiClient.baseUrl;
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 0); // SSE는 타임아웃 없음
      dio.options.sendTimeout = const Duration(seconds: 30);

      // SSE 전용 헤더 설정
      dio.options.headers.addAll({
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
      });

      // 인터셉터 추가 (필요시)
      dio.interceptors.add(LogInterceptor(
        requestBody: false,
        responseBody: false,
        requestHeader: true,
        responseHeader: false,
        error: true,
      ));

      return dio;
    } catch (e) {
      throw ChatApiException('Failed to create SSE Dio instance: $e');
    }
  }

  /// DioException 처리
  ChatApiException _handleDioException(DioException e, String context) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    // API 에러 응답 파싱 시도
    ApiError? apiError;
    if (data is Map<String, dynamic> && data.containsKey('error')) {
      try {
        apiError = ApiError.fromJson(data['error']);
      } catch (_) {
        // 파싱 실패 시 무시
      }
    }

    String message = context;
    if (apiError != null) {
      message = '${apiError.message} (Code: ${apiError.code})';
    } else if (e.message != null) {
      message = '$context: ${e.message}';
    }

    return ChatApiException(
      message,
      code: apiError?.code ?? e.type.toString(),
      statusCode: statusCode,
      apiError: apiError,
    );
  }

  /// 리소스 정리
  void dispose() {
    _apiClient.dispose();
  }
}