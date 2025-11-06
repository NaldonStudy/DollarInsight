package com.ssafy.b205.backend.domain.chat.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Getter
public class CreateSessionResponse {
    @Schema(example = "8c2c2f07-3c3a-4985-8b7d-5f7f7f4e3f21")
    private final UUID sessionId;

    @Schema(description = "세션에 연결된 페르소나 코드 목록(영문 코드)",
            example = "[\"Minji\",\"Taeo\",\"Ducksu\"]")
    private final List<String> personas;

    private final LocalDateTime createdAt;

    public CreateSessionResponse(UUID sessionId, List<String> personas, LocalDateTime createdAt) {
        this.sessionId = sessionId;
        this.personas = personas;
        this.createdAt = createdAt;
    }
}
