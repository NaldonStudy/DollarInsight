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

      // 응답 구조 확인하고 data 래퍼 처리
      if (response is Map<String, dynamic>) {
        // data 래퍼가 있는 경우
        if (response.containsKey('data') && response['ok'] == true) {
          return CreateSessionResponse.fromJson(response['data']);
        }
        // data 래퍼가 없는 경우 (직접 응답)
        else if (response.containsKey('sessionUuid')) {
          return CreateSessionResponse.fromJson(response);
        }
      }

      // 예상치 못한 응답 구조
      throw ChatApiException('Unexpected response structure: $response');

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

      // data 래퍼 처리
      if (response is Map<String, dynamic>) {
        if (response.containsKey('data') && response['ok'] == true) {
          return AppendMessageResponse.fromJson(response['data']);
        } else if (response.containsKey('messageId')) {
          return AppendMessageResponse.fromJson(response);
        }
      }

      throw ChatApiException('Unexpected response structure: $response');
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

      // data 래퍼 처리
      if (response is Map<String, dynamic>) {
        if (response.containsKey('data') && response['ok'] == true) {
          return HistoryResponse.fromJson(response['data']);
        } else if (response.containsKey('items')) {
          return HistoryResponse.fromJson(response);
        }
      }

      throw ChatApiException('Unexpected response structure: $response');
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

  /// 채팅 세션 목록 조회
  /// GET /api/chat/sessions
  Future<SessionListResponse> getSessionList({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/chat/sessions',
        queryParameters: {
          'page': page,
          'size': size,
        },
      );

      // 응답 구조 확인하고 data 래퍼 처리
      if (response is Map<String, dynamic>) {
        // data 래퍼가 있는 경우
        if (response.containsKey('data') && response['ok'] == true) {
          return SessionListResponse.fromJson(response['data']);
        }
        // data 래퍼가 없는 경우 (직접 응답)
        else if (response.containsKey('items')) {
          return SessionListResponse.fromJson(response);
        }
      }

      throw ChatApiException('Unexpected response structure: $response');
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to get chat sessions');
    } catch (e) {
      throw ChatApiException('Unexpected error while getting chat sessions: $e');
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
      // 수신 타임아웃을 null로 설정하여 무한정 대기 (스트리밍 연결 유지)
      dio.options.receiveTimeout = null;
      dio.options.sendTimeout = const Duration(seconds: 30);

      // SSE 전용 헤더 설정
      dio.options.headers.addAll({
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
      });

      // SSE 스트림 연결에서는 LogInterceptor를 제거하여 잠재적인 간섭을 방지합니다.
      // dio.interceptors.add(LogInterceptor(
      //   requestBody: false,
      //   responseBody: false,
      //   requestHeader: true,
      //   responseHeader: false,
      //   error: true,
      // ));

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
