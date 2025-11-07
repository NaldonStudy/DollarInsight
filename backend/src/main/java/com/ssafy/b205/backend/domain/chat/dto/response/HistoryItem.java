package com.ssafy.b205.backend.domain.chat.dto.response;

import lombok.Getter;

import java.time.Instant;

@Getter
public class HistoryItem {
    private final String role;
    private final String content;
    private final Instant ts;

    public HistoryItem(String role, String content, Instant ts) {
        this.role = role;
        this.content = content;
        this.ts = ts;
    }
}
