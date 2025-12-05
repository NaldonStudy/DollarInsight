// message_model.dart
// 채팅 메시지와 관련된 모델 클래스들

import 'package:json_annotation/json_annotation.dart';
import 'chat_model.dart'; // TopicType import

part 'message_model.g.dart';

/// 메시지 역할 (사용자 또는 AI 어시스턴트)
enum MessageRole {
  @JsonValue('user')
  user,
  @JsonValue('assistant')
  assistant,
  @JsonValue('system')
  system,
}

/// 채팅 메시지 모델
@JsonSerializable()
class ChatMessage {
  final String? id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final String? personaCode; // AI 응답의 경우 어떤 페르소나가 작성했는지
  final String? personaName; // 페르소나의 표시 이름
  final bool isStreaming; // 현재 스트리밍 중인지 여부
  final Map<String, dynamic>? metadata; // 추가 메타데이터

  ChatMessage({
    this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.personaCode,
    this.personaName,
    this.isStreaming = false,
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);

  /// 사용자 메시지 생성 헬퍼
  factory ChatMessage.user({
    String? id,
    required String content,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id,
      role: MessageRole.user,
      content: content,
      timestamp: timestamp ?? DateTime.now(),
      metadata: metadata,
    );
  }

  /// AI 어시스턴트 메시지 생성 헬퍼
  factory ChatMessage.assistant({
    String? id,
    required String content,
    DateTime? timestamp,
    String? personaCode,
    String? personaName,
    bool isStreaming = false,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id,
      role: MessageRole.assistant,
      content: content,
      timestamp: timestamp ?? DateTime.now(),
      personaCode: personaCode,
      personaName: personaName,
      isStreaming: isStreaming,
      metadata: metadata,
    );
  }

  /// 메시지 복사 (일부 필드 업데이트)
  ChatMessage copyWith({
    String? id,
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    String? personaCode,
    String? personaName,
    bool? isStreaming,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      personaCode: personaCode ?? this.personaCode,
      personaName: personaName ?? this.personaName,
      isStreaming: isStreaming ?? this.isStreaming,
      metadata: metadata ?? this.metadata,
    );
  }

  /// 스트리밍 중인 메시지에 내용 추가
  ChatMessage appendContent(String additionalContent) {
    return copyWith(
      content: content + additionalContent,
      isStreaming: true,
    );
  }

  /// 스트리밍 완료 처리
  ChatMessage finishStreaming() {
    return copyWith(isStreaming: false);
  }
}

/// 채팅 세션 모델
@JsonSerializable()
class ChatSession {
  final String sessionUuid;
  final String title;
  final TopicType topicType;
  final String? ticker;
  final List<String> personas;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final int messageCount;
  final Map<String, dynamic>? metadata;

  ChatSession({
    required this.sessionUuid,
    required this.title,
    required this.topicType,
    this.ticker,
    required this.personas,
    required this.createdAt,
    this.lastMessageAt,
    this.messageCount = 0,
    this.metadata,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) =>
      _$ChatSessionFromJson(json);

  Map<String, dynamic> toJson() => _$ChatSessionToJson(this);

  /// 세션 복사 (일부 필드 업데이트)
  ChatSession copyWith({
    String? sessionUuid,
    String? title,
    TopicType? topicType,
    String? ticker,
    List<String>? personas,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    int? messageCount,
    Map<String, dynamic>? metadata,
  }) {
    return ChatSession(
      sessionUuid: sessionUuid ?? this.sessionUuid,
      title: title ?? this.title,
      topicType: topicType ?? this.topicType,
      ticker: ticker ?? this.ticker,
      personas: personas ?? this.personas,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      messageCount: messageCount ?? this.messageCount,
      metadata: metadata ?? this.metadata,
    );
  }

  /// 새 메시지 추가 시 세션 정보 업데이트
  ChatSession updateWithNewMessage() {
    return copyWith(
      lastMessageAt: DateTime.now(),
      messageCount: messageCount + 1,
    );
  }
}

/// 페르소나 정보
@JsonSerializable()
class PersonaInfo {
  final String code;
  final String name;
  final String description;
  final String? avatar;
  final Map<String, dynamic>? properties;

  PersonaInfo({
    required this.code,
    required this.name,
    required this.description,
    this.avatar,
    this.properties,
  });

  factory PersonaInfo.fromJson(Map<String, dynamic> json) =>
      _$PersonaInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PersonaInfoToJson(this);
}

/// 채팅 상태
enum ChatState {
  idle,          // 대기 중
  sending,       // 메시지 전송 중
  receiving,     // 응답 수신 중
  streaming,     // 스트리밍 중
  error,         // 오류 상태
  interrupted,   // 중단됨
}

/// 채팅 세션 상태 관리 모델
class ChatSessionState {
  final ChatSession session;
  final List<ChatMessage> messages;
  final ChatState state;
  final String? error;
  final Map<String, PersonaInfo>? personas;

  ChatSessionState({
    required this.session,
    this.messages = const [],
    this.state = ChatState.idle,
    this.error,
    this.personas,
  });

  /// 상태 복사 (일부 필드 업데이트)
  ChatSessionState copyWith({
    ChatSession? session,
    List<ChatMessage>? messages,
    ChatState? state,
    String? error,
    Map<String, PersonaInfo>? personas,
  }) {
    return ChatSessionState(
      session: session ?? this.session,
      messages: messages ?? this.messages,
      state: state ?? this.state,
      error: error ?? this.error,
      personas: personas ?? this.personas,
    );
  }

  /// 메시지 추가
  ChatSessionState addMessage(ChatMessage message) {
    return copyWith(
      messages: [...messages, message],
      session: session.updateWithNewMessage(),
    );
  }

  /// 마지막 메시지 업데이트 (스트리밍 중 내용 추가 등)
  ChatSessionState updateLastMessage(ChatMessage message) {
    if (messages.isEmpty) return addMessage(message);

    final updatedMessages = [...messages];
    updatedMessages[updatedMessages.length - 1] = message;

    return copyWith(messages: updatedMessages);
  }

  /// 오류 상태로 변경
  ChatSessionState setError(String errorMessage) {
    return copyWith(
      state: ChatState.error,
      error: errorMessage,
    );
  }

  /// 오류 상태 클리어
  ChatSessionState clearError() {
    return copyWith(
      state: ChatState.idle,
      error: null,
    );
  }
}

