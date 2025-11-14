
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

      // 응답 구조: { "ok": true, "data": { "sessionUuid": "...", "personas": [...], "createdAt": "..." } }
      final data = response['data'] as Map<String, dynamic>;
      return CreateSessionResponse.fromJson(data);
    } catch (e) {
      throw Exception('세션 생성 실패: $e');
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

      // 응답 구조: { "messageId": "672c1fe28f7d3c0b1d2a90a3" }
      return AppendMessageResponse.fromJson(response);
    } catch (e) {
      throw Exception('메시지 등록 실패: $e');
    }
  }

  /// 진행 중인 스트림 중단
  /// POST /api/chat/sessions/{sid}/interrupt
  Future<void> interrupt(String sessionId) async {
    try {
      await _apiClient.post('/api/chat/sessions/$sessionId/interrupt');
    } catch (e) {
      throw Exception('스트림 중단 실패: $e');
    }
  }

  /// 일시 중단된 스트림 재개
  /// POST /api/chat/sessions/{sid}/control/resume
  Future<void> resume(String sessionId) async {
    try {
      await _apiClient.post('/api/chat/sessions/$sessionId/control/resume');
    } catch (e) {
      throw Exception('스트림 재개 실패: $e');
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
    } catch (e) {
      throw Exception('발화 간격 변경 실패: $e');
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
    } catch (e) {
      throw Exception('히스토리 조회 실패: $e');
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
    } catch (e) {
      throw Exception('커서 기반 히스토리 조회 실패: $e');
    }
  }

  /// SSE 스트림 연결을 위한 Dio 인스턴스 생성
  /// GET /api/chat/sessions/{sid}/stream
  ///
  /// 이 메서드는 SSE 연결을 직접 처리하지 않고, SSE 연결에 필요한 설정된 Dio 인스턴스만 반환합니다.
  /// 실제 SSE 스트림 처리는 상위 레이어에서 담당해야 합니다.
  Future<Dio> createSSEDio() async {
    // ApiClient 내부의 Dio 설정을 활용하되, SSE 전용 설정으로 오버라이드
    final dio = Dio();

    // 기본 설정
    dio.options.baseUrl = ApiClient.baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 0); // SSE는 타임아웃 없음

    return dio;
  }

  /// 리소스 정리
  void dispose() {
    _apiClient.dispose();
  }
}