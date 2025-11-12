package com.ssafy.b205.backend.domain.companyanalysis.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;

import java.time.Instant;

@Getter
public class NewsHeadlineResponse {

    @Schema(description = "MongoDB 뉴스 문서 ID")
    private final String id;

    @Schema(description = "연결된 티커 (있을 경우)")
    private final String ticker;

    @Schema(description = "기사 제목")
    private final String title;

    @Schema(description = "한줄 요약 또는 서머리")
    private final String summary;

    @Schema(description = "원문 URL")
    private final String url;

    @Schema(description = "기사 발행시각(UTC)")
    private final Instant publishedAt;

    public NewsHeadlineResponse(String id, String ticker, String title, String summary,
                                String url, Instant publishedAt) {
        this.id = id;
        this.ticker = ticker;
        this.title = title;
        this.summary = summary;
        this.url = url;
        this.publishedAt = publishedAt;
    }
}
