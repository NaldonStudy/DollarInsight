package com.ssafy.b205.backend.infra.mongo.chat;

import lombok.Builder;
import lombok.Getter;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.index.CompoundIndexes;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;
import java.util.UUID;

@Getter
@Document(collection = "chat_messages")
@CompoundIndexes({
        // 기존: ts 정렬 히스토리 최적화
        @CompoundIndex(name = "session_ts_desc_idx", def = "{'sessionUuid': 1, 'ts': -1}"),
        // 추가: _id 커서 히스토리2 최적화
        @CompoundIndex(name = "session__id_desc_idx", def = "{'sessionUuid': 1, '_id': -1}")
})
public final class ChatMessageDoc {

    @Id
    private final String id;          // Mongo ObjectId 문자열

    @Indexed
    private final UUID sessionUuid;   // 세션 식별자(외부 공개 UUID)

    private final String role;        // "user" | "assistant" | "system"
    private final String content;
    private final String speaker;     // AI 발화자 (assistant 전용)
    private final Integer turn;       // AI 발화 순번
    private final Long aiTsMs;        // AI 서비스가 내려준 timestamp(ms)
    private final String rawPayload;  // AI 원본 JSON (assistant 전용)

    @Indexed
    private final Instant ts;         // 타임라인 정렬/페이징 기준

    private final Long seq;           // SSE 내 순서 표기(옵션) — 조회 정렬엔 사용 안 함

    @Builder
    public ChatMessageDoc(
            String id,
            UUID sessionUuid,
            String role,
            String content,
            String speaker,
            Integer turn,
            Long aiTsMs,
            String rawPayload,
            Instant ts,
            Long seq
    ) {
        this.id = id;
        this.sessionUuid = sessionUuid;
        this.role = role;
        this.content = content;
        this.speaker = speaker;
        this.turn = turn;
        this.aiTsMs = aiTsMs;
        this.rawPayload = rawPayload;
        this.ts = ts;
        this.seq = seq;
    }
}
