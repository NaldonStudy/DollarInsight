package com.ssafy.b205.backend.infra.mongo.chat;

import lombok.*;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;
import java.util.UUID;

@Document("chat_messages")
@Getter @Builder
@AllArgsConstructor @NoArgsConstructor
public class ChatMessageDoc {
    @Id private String id;
    private UUID   sessionUuid;
    private String role;       // "user" | "assistant"
    private String content;
    private long   seq;        // 정렬용 증가값
    private Instant ts;        // 타임스탬프
}
