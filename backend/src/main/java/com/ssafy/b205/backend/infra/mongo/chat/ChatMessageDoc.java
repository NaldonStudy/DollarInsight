package com.ssafy.b205.backend.infra.mongo.chat;

import lombok.*;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;

import java.time.Instant;
import java.util.UUID;

@Document(collection = "chat_messages")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class ChatMessageDoc {

    @Id
    private String id;

    @Indexed
    @Field("session_uuid")
    private UUID sessionUuid;

    @Field("role")
    private String role;

    @Field("content")
    private String content;

    @Field("seq")
    private long seq;

    @Indexed
    @Field("ts")
    private Instant ts;
}
