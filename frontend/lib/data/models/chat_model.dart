// chat_models.dart
// 채팅 관련 모델 클래스들

import 'package:json_annotation/json_annotation.dart';
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

  HistoryItem({
    required this.role,
    required this.content,
    required this.ts,
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
}

/// SSE 메시지 데이터
class SSEMessage {
  final SSEEventType type;
  final String data;
  final String? id;

  SSEMessage({
    required this.type,
    required this.data,
    this.id,
  });

  factory SSEMessage.fromRaw(String eventType, String data, String? id) {
    final type = switch (eventType) {
      'message' => SSEEventType.message,
      'done' => SSEEventType.done,
      'error' => SSEEventType.error,
      _ => SSEEventType.message,
    };

    return SSEMessage(type: type, data: data, id: id);
  }

  @override
  String toString() {
    return 'SSEMessage{type: $type, data: $data, id: $id}';
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