// chat_models.dart
// 채팅 관련 모델 클래스들

import 'package:json_annotation/json_annotation.dart';
import '../../core/utils/ticker_logo_mapper.dart';
part 'chat_model.g.dart';

/// 토픽 타입 열거형
enum TopicType {
  @JsonValue('COMPANY')
  company,
  @JsonValue('NEWS')
  news,
  @JsonValue('CUSTOM')
  custom,
}

/// 세션 생성 요청
@JsonSerializable()
class CreateSessionRequest {
  final TopicType topicType;
  final String? title;
  final String? ticker;
  final int? companyNewsId;
  final bool? companyValid;

  CreateSessionRequest({
    required this.topicType,
    this.title,
    this.ticker,
    this.companyNewsId,
    this.companyValid,
  });

  factory CreateSessionRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateSessionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateSessionRequestToJson(this);
}

/// 세션 생성 응답
@JsonSerializable()
class CreateSessionResponse {
  final String sessionUuid;
  final List<String> personas;
  final DateTime createdAt;

  CreateSessionResponse({
    required this.sessionUuid,
    required this.personas,
    required this.createdAt,
  });

  factory CreateSessionResponse.fromJson(Map<String, dynamic> json) =>
      _$CreateSessionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CreateSessionResponseToJson(this);
}

/// 메시지 추가 요청
@JsonSerializable()
class AppendMessageRequest {
  final String content;

  AppendMessageRequest({required this.content});

  factory AppendMessageRequest.fromJson(Map<String, dynamic> json) =>
      _$AppendMessageRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AppendMessageRequestToJson(this);
}

/// 메시지 추가 응답
@JsonSerializable()
class AppendMessageResponse {
  final String messageId;

  AppendMessageResponse({required this.messageId});

  factory AppendMessageResponse.fromJson(Map<String, dynamic> json) =>
      _$AppendMessageResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AppendMessageResponseToJson(this);
}

/// 발화 간격 변경 요청
@JsonSerializable()
class ChangePaceRequest {
  final int paceMs;

  ChangePaceRequest({required this.paceMs});

  factory ChangePaceRequest.fromJson(Map<String, dynamic> json) =>
      _$ChangePaceRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ChangePaceRequestToJson(this);
}

/// 히스토리 아이템
@JsonSerializable()
class HistoryItem {
  final String role;
  final String content;
  final DateTime ts;
  final String? speaker;
  final int? turn;
  final int? tsMs;
  final String? rawPayload;

  HistoryItem({
    required this.role,
    required this.content,
    required this.ts,
    this.speaker,
    this.turn,
    this.tsMs,
    this.rawPayload,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) =>
      _$HistoryItemFromJson(json);

  Map<String, dynamic> toJson() => _$HistoryItemToJson(this);
}

/// 히스토리 응답 (v1)
@JsonSerializable()
class HistoryResponse {
  final List<HistoryItem> items;

  HistoryResponse({required this.items});

  factory HistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$HistoryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$HistoryResponseToJson(this);
}

/// 커서 기반 히스토리 아이템 (v2) - Swagger 스키마 'Item'과 일치
@JsonSerializable()
class Item {
  final String id;
  final String role;
  final String content;
  final DateTime ts;

  Item({
    required this.id,
    required this.role,
    required this.content,
    required this.ts,
  });

  factory Item.fromJson(Map<String, dynamic> json) =>
      _$ItemFromJson(json);

  Map<String, dynamic> toJson() => _$ItemToJson(this);
}

/// 커서 기반 히스토리 응답 (v2)
@JsonSerializable()
class HistoryCursorResponse {
  final List<Item> items;
  final String? nextCursor;
  final bool hasMore;

  HistoryCursorResponse({
    required this.items,
    this.nextCursor,
    required this.hasMore,
  });

  factory HistoryCursorResponse.fromJson(Map<String, dynamic> json) =>
      _$HistoryCursorResponseFromJson(json);

  Map<String, dynamic> toJson() => _$HistoryCursorResponseToJson(this);
}

/// SSE 이벤트 타입
enum SSEEventType {
  message,
  done,
  error,
  ready,
}

/// SSE 메시지 데이터
class SSEMessage {
  final SSEEventType type;
  final String data;
  final String? id;
  final String? raw;
  final String? speaker;
  final int? turn;
  final int? tsMs;
  final String? sessionId;

  SSEMessage({
    required this.type,
    required this.data,
    this.id,
    this.raw,
    this.speaker,
    this.turn,
    this.tsMs,
    this.sessionId,
  });

  factory SSEMessage.fromRaw(
    String eventType,
    String data,
    String? id, {
    String? raw,
    String? speaker,
    int? turn,
    int? tsMs,
    String? sessionId,
  }) {
    final type = switch (eventType) {
      'message' => SSEEventType.message,
      'done' => SSEEventType.done,
      'error' => SSEEventType.error,
      'ready' => SSEEventType.ready,
      _ => SSEEventType.message,
    };

    return SSEMessage(
      type: type,
      data: data,
      id: id,
      raw: raw,
      speaker: speaker,
      turn: turn,
      tsMs: tsMs,
      sessionId: sessionId,
    );
  }

  @override
  String toString() {
    return 'SSEMessage{type: $type, data: $data, id: $id, speaker: $speaker, turn: $turn, raw: ${raw?.substring(0, raw!.length > 50 ? 50 : raw!.length)}...}';
  }
}

/// API 에러 모델
@JsonSerializable()
class ApiError {
  final String code;
  final String message;
  final String path;
  final DateTime timestamp;

  ApiError({
    required this.code,
    required this.message,
    required this.path,
    required this.timestamp,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorFromJson(json);

  Map<String, dynamic> toJson() => _$ApiErrorToJson(this);
}

/// 세션 목록 아이템
@JsonSerializable()
class SessionItem {
  final String sessionUuid;
  final TopicType topicType;
  final String title;
  final String? ticker;
  final int? companyNewsId;
  final DateTime createdAt;
  final DateTime updatedAt;

  SessionItem({
    required this.sessionUuid,
    required this.topicType,
    required this.title,
    this.ticker,
    this.companyNewsId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SessionItem.fromJson(Map<String, dynamic> json) =>
      _$SessionItemFromJson(json);

  Map<String, dynamic> toJson() => _$SessionItemToJson(this);

  /// 🔥 최종 확정 버전
  /// 뉴스/커스텀 아이콘 제거 → ticker 기반 로고만 사용
  String get resolvedLogoAsset {
    if (ticker != null && TickerLogoMapper.hasLogo(ticker!)) {
      return TickerLogoMapper.getLogoPath(ticker!);
    }
    return ""; // 기본 아이콘 제거 → 빈 문자열 반환
  }
}


/// 세션 목록 응답
@JsonSerializable()
class SessionListResponse {
  final List<SessionItem> items;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool hasNext;

  SessionListResponse({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.hasNext,
  });

  factory SessionListResponse.fromJson(Map<String, dynamic> json) =>
      _$SessionListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SessionListResponseToJson(this);
}

/// 세션 응답 (Auth Session API 기반)
@JsonSerializable()
class SessionResponse {
  final String sessionUuid;
  final String deviceUuid;
  final String deviceLabel;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final DateTime? revokedAt;
  final bool pushEnabled;

  SessionResponse({
    required this.sessionUuid,
    required this.deviceUuid,
    required this.deviceLabel,
    required this.issuedAt,
    required this.expiresAt,
    this.revokedAt,
    required this.pushEnabled,
  });

  factory SessionResponse.fromJson(Map<String, dynamic> json) =>
      _$SessionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SessionResponseToJson(this);

  /// SessionItem으로 변환 (세션 아이디가 있을 경우)
  SessionItem? toSessionItem({
    TopicType? topicType,
    String? title,
    String? ticker,
    int? companyNewsId,
  }) {
    // 세션이 활성 상태이고 만료되지 않았을 때만 변환
    if (revokedAt == null && DateTime.now().isBefore(expiresAt)) {
      return SessionItem(
        sessionUuid: sessionUuid,
        topicType: topicType ?? TopicType.custom,
        title: title ?? '채팅',
        ticker: ticker,
        companyNewsId: companyNewsId,
        createdAt: issuedAt,
        updatedAt: issuedAt,
      );
    }
    return null;
  }
}

/// Chat API 관련 예외 클래스
class ChatApiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;
  final ApiError? apiError;

  ChatApiException(
      this.message, {
        this.code,
        this.statusCode,
        this.apiError,
      });

  @override
  String toString() {
    return 'ChatApiException: $message${code != null ? ' (Code: $code)' : ''}${statusCode != null ? ' (Status: $statusCode)' : ''}';
  }
}