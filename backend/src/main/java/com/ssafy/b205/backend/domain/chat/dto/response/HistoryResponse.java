package com.ssafy.b205.backend.domain.chat.dto.response;

import com.ssafy.b205.backend.infra.mongo.chat.ChatMessageDoc;
import lombok.Getter;

import java.util.List;

@Getter
public class HistoryResponse {
    private final List<HistoryItem> items;

    public HistoryResponse(List<HistoryItem> items) {
        this.items = items;
    }

    // ✅ 서비스에서 쓰는 정적 팩토리
    public static HistoryResponse from(List<ChatMessageDoc> docs) {
        var items = docs.stream()
                .map(d -> new HistoryItem(
                        d.getRole(),
                        d.getContent(),
                        d.getTs(),
                        d.getSpeaker(),
                        d.getTurn(),
                        d.getAiTsMs(),
                        d.getRawPayload()
                ))
                .toList();
        return new HistoryResponse(items);
    }
}
