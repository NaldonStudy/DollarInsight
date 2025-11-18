package com.ssafy.b205.backend.domain.chat.dto.response;

import com.ssafy.b205.backend.domain.chat.entity.ChatSession;
import com.ssafy.b205.backend.domain.chat.entity.ChatTopicType;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;

import java.time.Instant;
import java.util.UUID;

@Getter
public class ChatSessionSummaryResponse {

    @Schema(description = "세션 UUID", example = "4b1c0a5c-2c4c-49d9-8c8f-19b6e0a6a1d2")
    private final UUID sessionUuid;

    @Schema(description = "세션 주제 유형", example = "CUSTOM")
    private final ChatTopicType topicType;

    @Schema(description = "세션 제목", example = "엔비디아 전망 토크")
    private final String title;

    @Schema(description = "연관 종목 티커", example = "NVDA")
    private final String ticker;

    @Schema(description = "연관 뉴스 ID", example = "123")
    private final Long companyNewsId;

    @Schema(type = "string", format = "date-time", description = "생성 시각", example = "2025-11-07T04:50:00Z")
    private final Instant createdAt;

    @Schema(type = "string", format = "date-time", description = "최종 수정 시각", example = "2025-11-07T05:00:00Z")
    private final Instant updatedAt;

    private ChatSessionSummaryResponse(UUID sessionUuid,
                                       ChatTopicType topicType,
                                       String title,
                                       String ticker,
                                       Long companyNewsId,
                                       Instant createdAt,
                                       Instant updatedAt) {
        this.sessionUuid = sessionUuid;
        this.topicType = topicType;
        this.title = title;
        this.ticker = ticker;
        this.companyNewsId = companyNewsId;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public static ChatSessionSummaryResponse from(ChatSession session) {
        return new ChatSessionSummaryResponse(
                session.getUuid(),
                session.getTopicType(),
                session.getTitle(),
                session.getTicker(),
                session.getCompanyNewsId(),
                session.getCreatedAt() == null ? null : session.getCreatedAt().toInstant(),
                session.getUpdatedAt() == null ? null : session.getUpdatedAt().toInstant()
        );
    }
}
