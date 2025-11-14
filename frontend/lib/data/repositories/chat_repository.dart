// chat_repository.dart
// 채팅 관련 비즈니스 로직을 처리하는 리포지토리

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../datasources/remote/chat_api.dart';
import '../models/chat_model.dart';
import '../../core/utils/device_id_manager.dart';
import '../datasources/local/token_storage.dart';

/// 채팅 리포지토리
/// 채팅 관련 데이터 처리와 비즈니스 로직을 담당
class ChatRepository {
  final ChatApi _chatApi;

  ChatRepository({ChatApi? chatApi}) : _chatApi = chatApi ?? ChatApi();

  /// 새로운 채팅 세션 생성
  Future<CreateSessionResponse> createSession({
    required TopicType topicType,
    String? title,
    String? ticker,
    int? companyNewsId,
    bool? companyValid,
  }) async {
    final request = CreateSessionRequest(
      topicType: topicType,
      title: title,
      ticker: ticker,
      companyNewsId: companyNewsId,
      companyValid: companyValid,
    );

    return await _chatApi.createSession(request);
  }

  /// 메시지 전송
  Future<AppendMessageResponse> sendMessage(String sessionId, String content) async {
    if (content.trim().isEmpty) {
      throw Exception('메시지 내용이 비어있습니다');
    }

    final request = AppendMessageRequest(content: content.trim());
    return await _chatApi.appendMessage(sessionId, request);
  }

  /// 스트림 중단
  Future<void> stopStream(String sessionId) async {
    await _chatApi.interrupt(sessionId);
  }

  /// 스트림 재개
  Future<void> resumeStream(String sessionId) async {
    await _chatApi.resume(sessionId);
  }

  /// 발화 속도 조절 (밀리초 단위)
  Future<void> changeSpeakingPace(String sessionId, int paceMs) async {
    if (paceMs < 0) {
      throw Exception('발화 간격은 0 이상이어야 합니다');
    }

    final request = ChangePaceRequest(paceMs: paceMs);
    await _chatApi.changePace(sessionId, request);
  }

  /// 채팅 히스토리 조회 (간단 버전)
  Future<List<HistoryItem>> getChatHistory(String sessionId, {int limit = 50}) async {
    if (limit <= 0 || limit > 100) {
      throw Exception('limit은 1-100 사이의 값이어야 합니다');
    }

    final response = await _chatApi.getHistory(sessionId, limit: limit);
    return response.items;
  }

  /// 채팅 히스토리 조회 (페이지네이션 버전)
  Future<HistoryCursorResponse> getChatHistoryWithPagination(
    String sessionId, {
    int limit = 50,
    String? cursor,
  }) async {
    if (limit <= 0 || limit > 100) {
      throw Exception('limit은 1-100 사이의 값이어야 합니다');
    }

    return await _chatApi.getHistoryWithCursor(sessionId, limit: limit, cursor: cursor);
  }

  /// SSE 스트림 연결
  /// 
  /// 실제 SSE 이벤트 스트림을 반환합니다.
  /// 사용법:
  /// ```dart
  /// final stream = await repository.connectToSSEStream(sessionId);
  /// stream.listen((message) => {
  ///   // SSE 메시지 처리
  /// });
  /// ```
  Future<Stream<SSEMessage>> connectToSSEStream(String sessionId, {String? lastEventId}) async {
    try {
      // SSE 연결용 Dio 인스턴스 생성
      final dio = await _chatApi.createSSEDio();

      // 필요한 헤더들 준비
      final deviceId = await DeviceIdManager.getDeviceId();
      final accessToken = await TokenStorage.getAccessToken();

      final headers = <String, dynamic>{
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'X-Device-Id': deviceId,
      };

      if (accessToken != null) {
        headers['Authorization'] = 'Bearer $accessToken';
      }

      if (lastEventId != null) {
        headers['Last-Event-ID'] = lastEventId;
      }

      // SSE 스트림 요청
      final response = await dio.get(
        '/api/chat/sessions/$sessionId/stream',
        queryParameters: {'device_id': deviceId},
        options: Options(
          headers: headers,
          responseType: ResponseType.stream,
        ),
      );

      final responseStream = response.data as ResponseBody;
      
      // 타입 안전한 스트림 변환
      return responseStream.stream
          .cast<Uint8List>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .where((line) => line.isNotEmpty)
          .map(_parseSSELine)
          .where((message) => message != null)
          .cast<SSEMessage>();

    } catch (e) {
      throw Exception('SSE 스트림 연결 실패: $e');
    }
  }

  /// SSE 라인 파싱
  SSEMessage? _parseSSELine(String line) {
    if (line.startsWith('id:')) {
      // ID 라인은 다음 data 라인과 함께 처리되므로 여기서는 무시
      return null;
    } else if (line.startsWith('event:')) {
      // 이벤트 타입 라인도 마찬가지로 다음 data와 함께 처리
      return null;
    } else if (line.startsWith('data:')) {
      // 실제 데이터 라인
      final data = line.substring(5).trim(); // 'data:' 제거
      
      // 기본적으로 message 타입으로 처리
      // 실제 구현에서는 이전 라인들을 파싱해서 정확한 이벤트 타입을 결정해야 함
      return SSEMessage(
        type: SSEEventType.message,
        data: data,
      );
    }
    
    return null;
  }

  /// 더 정교한 SSE 파싱을 위한 스트림 변환기
  /// 
  /// SSE 형식에 맞춰 이벤트를 정확히 파싱합니다:
  /// ```
  /// id: 1
  /// event: message
  /// data: {"content": "hello"}
  /// 
  /// ```
  Stream<SSEMessage> _parseSSEStream(Stream<String> lineStream) async* {
    String? currentId;
    String? currentEvent;
    String? currentData;

    await for (final line in lineStream) {
      if (line.trim().isEmpty) {
        // 빈 라인은 이벤트의 끝을 의미
        if (currentData != null) {
          yield SSEMessage.fromRaw(
            currentEvent ?? 'message',
            currentData,
            currentId,
          );
        }
        // 현재 이벤트 초기화
        currentId = null;
        currentEvent = null;
        currentData = null;
      } else if (line.startsWith('id:')) {
        currentId = line.substring(3).trim();
      } else if (line.startsWith('event:')) {
        currentEvent = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        final data = line.substring(5).trim();
        currentData = currentData == null ? data : '$currentData\n$data';
      }
    }

    // 마지막 이벤트 처리 (스트림이 끝날 때)
    if (currentData != null) {
      yield SSEMessage.fromRaw(
        currentEvent ?? 'message',
        currentData,
        currentId,
      );
    }
  }

  /// 리소스 정리
  void dispose() {
    _chatApi.dispose();
  }
}