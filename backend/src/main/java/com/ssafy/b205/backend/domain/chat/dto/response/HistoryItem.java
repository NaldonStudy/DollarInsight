package com.ssafy.b205.backend.domain.chat.dto.response;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.Instant;

@Getter
@AllArgsConstructor
public class HistoryItem {
    private final String role;
    private final String content;
    private final Instant ts;
    private final String speaker;
    private final Integer turn;
    private final Long tsMs;
    private final String rawPayload;
}
