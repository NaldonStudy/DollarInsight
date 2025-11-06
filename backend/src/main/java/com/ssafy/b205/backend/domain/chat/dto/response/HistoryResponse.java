package com.ssafy.b205.backend.domain.chat.dto.response;

import lombok.Getter;

import java.util.List;

@Getter
public class HistoryResponse {
    private final List<HistoryItem> items;

    public HistoryResponse(List<HistoryItem> items) {
        this.items = items;
    }
}
