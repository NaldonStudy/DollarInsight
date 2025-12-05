package com.ssafy.b205.backend.domain.chat.dto.response;

import com.ssafy.b205.backend.infra.mongo.chat.ChatMessageDoc;

import java.time.Instant;
import java.util.List;
import java.util.stream.Collectors;

public final class HistoryCursorResponse {

    private final List<Item> items;   // 과거→최신
    private final String nextCursor;  // 마지막 항목의 Mongo _id
    private final boolean hasMore;

    public HistoryCursorResponse(List<Item> items, String nextCursor, boolean hasMore) {
        this.items = items;
        this.nextCursor = nextCursor;
        this.hasMore = hasMore;
    }

    public List<Item> getItems() { return items; }
    public String getNextCursor() { return nextCursor; }
    public boolean isHasMore() { return hasMore; }

    public static HistoryCursorResponse of(List<ChatMessageDoc> orderedAsc, String nextCursor, boolean hasMore) {
        return new HistoryCursorResponse(
                orderedAsc.stream().map(Item::from).collect(Collectors.toList()),
                nextCursor,
                hasMore
        );
    }

    public static final class Item {
        private final String id;
        private final String role;
        private final String content;
        private final Instant ts;
        private final String speaker;
        private final Integer turn;
        private final Long tsMs;
        private final String rawPayload;

        private Item(String id, String role, String content, Instant ts,
                     String speaker, Integer turn, Long tsMs, String rawPayload) {
            this.id = id;
            this.role = role;
            this.content = content;
            this.ts = ts;
            this.speaker = speaker;
            this.turn = turn;
            this.tsMs = tsMs;
            this.rawPayload = rawPayload;
        }

        public String getId() { return id; }
        public String getRole() { return role; }
        public String getContent() { return content; }
        public Instant getTs() { return ts; }
        public String getSpeaker() { return speaker; }
        public Integer getTurn() { return turn; }
        public Long getTsMs() { return tsMs; }
        public String getRawPayload() { return rawPayload; }

        public static Item from(ChatMessageDoc d) {
            return new Item(
                    d.getId(),
                    d.getRole(),
                    d.getContent(),
                    d.getTs(),
                    d.getSpeaker(),
                    d.getTurn(),
                    d.getAiTsMs(),
                    d.getRawPayload()
            );
        }
    }
}
