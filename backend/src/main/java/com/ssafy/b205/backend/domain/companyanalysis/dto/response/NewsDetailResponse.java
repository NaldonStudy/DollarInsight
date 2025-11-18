package com.ssafy.b205.backend.domain.companyanalysis.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;

import java.time.Instant;
import java.util.List;

@Getter
public class NewsDetailResponse {

    @Schema(description = "MongoDB 뉴스 문서 ID")
    private final String id;

    @Schema(description = "연결된 티커 (있을 경우)")
    private final String ticker;

    @Schema(description = "기사 제목")
    private final String title;

    @Schema(description = "요약/리드 문구")
    private final String summary;

    @Schema(description = "본문 전문")
    private final String content;

    @Schema(description = "원문 링크")
    private final String url;

    @Schema(description = "기사 발행시각(UTC)")
    private final Instant publishedAt;

    @Schema(description = "뉴스별 페르소나 코멘트 목록")
    private final List<PersonaCommentResponse> personaComments;

    public NewsDetailResponse(String id, String ticker, String title,
                              String summary, String content,
                              String url, Instant publishedAt,
                              List<PersonaCommentResponse> personaComments) {
        this.id = id;
        this.ticker = ticker;
        this.title = title;
        this.summary = summary;
        this.content = content;
        this.url = url;
        this.publishedAt = publishedAt;
        this.personaComments = personaComments;
    }
}
