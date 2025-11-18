// chat_repository.dart
// 채팅 관련 비즈니스 로직을 처리하는 리포지토리

import 'dart:async';
import 'dart:convert';
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
  Future<AppendMessageResponse> sendMessage(String sessionId,
      String content) async {
    if (content
        .trim()
        .isEmpty) {
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
  Future<List<HistoryItem>> getChatHistory(String sessionId,
      {int limit = 50}) async {
    if (limit <= 0 || limit > 100) {
      throw Exception('limit은 1-100 사이의 값이어야 합니다');
    }

    final response = await _chatApi.getHistory(sessionId, limit: limit);
    return response.items;
  }

  /// 채팅 히스토리 조회 (페이지네이션 버전)
  Future<HistoryCursorResponse> getHistoryWithPagination(String sessionId, {
    int limit = 50,
    String? cursor,
  }) async {
    if (limit <= 0 || limit > 100) {
      throw Exception('limit은 1-100 사이의 값이어야 합니다');
    }

    return await _chatApi.getHistoryWithCursor(
        sessionId, limit: limit, cursor: cursor);
  }

  /// 세션 목록 조회
  ///
  /// 사용자의 모든 채팅 세션을 조회합니다.
  Future<SessionListResponse> getSessionList({
    int page = 0,
    int size = 20,
  }) async {
    // 올바른 메서드 이름으로 수정
    return await _chatApi.getSessionList(page: page, size: size);
  }

  /// 모든 세션 목록 조회 (첫 번째 페이지만)
  ///
  /// 기본적으로 첫 번째 페이지(20개)만 조회하는 편의 메소드
  Future<List<SessionItem>> getRecentSessions({int size = 20}) async {
    final response = await getSessionList(page: 0, size: size);
    return response.items; 
  }

  /// SSE 스트림 연결
  Future<Stream<SSEMessage>> connectToSSEStream(String sessionId,
      {String? lastEventId}) async {
    try {
      final dio = await _chatApi.createSSEDio();
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

      final response = await dio.get(
        '/api/chat/sessions/$sessionId/stream',
        queryParameters: {'device_id': deviceId},
        options: Options(headers: headers, responseType: ResponseType.stream),
      );

      final responseStream = response.data as ResponseBody;
      
      // 약간의 인코딩 오류를 허용하는 관대한(lenient) 디코더 사용
      final lineStream = Utf8Decoder(allowMalformed: true)
          .bind(responseStream.stream)
          .transform(const LineSplitter());

      return _parseSSEStream(lineStream);
    } catch (e) {
      throw Exception('SSE 스트림 연결 실패: $e');
    }
  }

  /// SSE 스트림 파서
  Stream<SSEMessage> _parseSSEStream(Stream<String> lineStream) async* {
    String? currentId;
    String? currentEvent;
    String? currentData;

    await for (final line in lineStream) {
      if (line.trim().isEmpty) {
        // 빈 라인은 이벤트의 끝을 의미
        final eventType = currentEvent ?? 'message';

        // 처리하기로 약속된 이벤트 타입들
        const knownEvents = {'message', 'done', 'error', 'ready'};

        // 데이터가 있고, 우리가 아는 이벤트 타입일 경우에만 처리
        if (currentData != null && knownEvents.contains(eventType)) {
          String finalData = currentData;
          String? rawData;
          String? speaker;
          int? turn;
          int? tsMs;
          String? sessionId;

          // 'message' 이벤트의 데이터는 JSON일 수 있으므로 파싱 시도
          if (eventType == 'message') {
            try {
              final jsonData = json.decode(currentData);
              if (jsonData is Map<String, dynamic>) {
                // 백엔드 응답 필드 파싱
                if (jsonData.containsKey('content')) {
                  finalData = jsonData['content'] as String;
                } else if (jsonData.containsKey('text')) {
                  finalData = jsonData['text'] as String;
                }

                // 추가 필드 파싱
                rawData = jsonData['raw'] as String?;
                speaker = jsonData['speaker'] as String?;
                turn = jsonData['turn'] as int?;
                tsMs = jsonData['tsMs'] as int?;
                sessionId = jsonData['sessionId'] as String?;
              }
            } catch (e) {
              // JSON이 아니면 원본 데이터 사용 (단순 문자열 스트림)
              finalData = currentData;
            }
          }
          yield SSEMessage.fromRaw(
            eventType,
            finalData,
            currentId,
            raw: rawData,
            speaker: speaker,
            turn: turn,
            tsMs: tsMs,
            sessionId: sessionId,
          );
        }

        // 상태 초기화. ping 같은 모르는 이벤트는 여기서 조용히 무시됨.
        currentId = null;
        currentEvent = null;
        currentData = null;

      } else if (line.startsWith('id:')) {
        currentId = line.substring(3).trim();
      } else if (line.startsWith('event:')) {
        currentEvent = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        final data = line.substring(5).trim();
        currentData = (currentData == null) ? data : '$currentData\n$data';
      } else {
        // 주석 (:) 또는 알 수 없는 라인은 무시
      }
    }
    
    // 스트림이 예기치 않게 종료되었을 때, 마지막으로 쌓인 데이터가 있다면 처리
    if (currentData != null) {
      final eventType = currentEvent ?? 'message';
      const knownEvents = {'message', 'done', 'error', 'ready'};
       if (knownEvents.contains(eventType)) {
         String finalData = currentData;
         String? rawData;
         String? speaker;
         int? turn;
         int? tsMs;
         String? sessionId;

          // 'message' 이벤트의 데이터는 JSON일 수 있으므로 파싱 시도
          if (eventType == 'message') {
            try {
              final jsonData = json.decode(currentData);
              if (jsonData is Map<String, dynamic>) {
                // 백엔드 응답 필드 파싱
                if (jsonData.containsKey('content')) {
                  finalData = jsonData['content'] as String;
                } else if (jsonData.containsKey('text')) {
                  finalData = jsonData['text'] as String;
                }

                // 추가 필드 파싱
                rawData = jsonData['raw'] as String?;
                speaker = jsonData['speaker'] as String?;
                turn = jsonData['turn'] as int?;
                tsMs = jsonData['tsMs'] as int?;
                sessionId = jsonData['sessionId'] as String?;
              }
            } catch (e) {
              // 불완전한 JSON일 수 있으므로 오류를 무시하고 원본 데이터를 전달
              finalData = currentData;
            }
          }
         yield SSEMessage.fromRaw(
           eventType,
           finalData,
           currentId,
           raw: rawData,
           speaker: speaker,
           turn: turn,
           tsMs: tsMs,
           sessionId: sessionId,
         );
       }
    }
  }

  /// 리소스 정리
  void dispose() {
    _chatApi.dispose();
  }
}
