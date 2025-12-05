package com.ssafy.b205.backend.domain.chat.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Getter
public class CreateSessionResponse {
    @Schema(example = "8c2c2f07-3c3a-4985-8b7d-5f7f7f4e3f21")
    private final UUID sessionUuid;

    @Schema(description = "세션에 연결된 페르소나 코드 목록(영문 코드)",
            example = "[\"Minji\",\"Taeo\",\"Ducksu\"]")
    private final List<String> personas;

    @Schema(type = "string", format = "date-time", example = "2025-11-07T08:20:00Z")
    private final Instant createdAt;

    public CreateSessionResponse(UUID sessionUuid, List<String> personas, Instant createdAt) {
        this.sessionUuid = sessionUuid;
        this.personas = personas;
        this.createdAt = createdAt;
    }
}
