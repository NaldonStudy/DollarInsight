package com.ssafy.b205.backend.domain.chat.entity;

import lombok.*;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;
import java.util.UUID;

@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Document(collection = "chat_messages")
@CompoundIndex(name = "session_ts_idx", def = "{'sessionUuid': 1, 'ts': 1}")
public class ChatMessageDoc {
    @Id
    private String id;
    private UUID sessionUuid;
    private String role;     // "user" | "assistant"
    private String content;
    private long seq;        // 스트림/메시지 순서
    private Instant ts;
}
