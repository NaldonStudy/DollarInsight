package com.ssafy.b205.backend.domain.companyanalysis.dto.response;

import lombok.Getter;

import java.time.Instant;
import java.util.List;

@Getter
public class NewsDetailResponse {

    private final Long id;
    private final String ticker;
    private final String title;
    private final String source;
    private final String summary;
    private final String url;
    private final Instant publishedAt;
    private final List<PersonaCommentResponse> personaComments;

    public NewsDetailResponse(Long id, String ticker, String title, String source,
                              String summary, String url, Instant publishedAt,
                              List<PersonaCommentResponse> personaComments) {
        this.id = id;
        this.ticker = ticker;
        this.title = title;
        this.source = source;
        this.summary = summary;
        this.url = url;
        this.publishedAt = publishedAt;
        this.personaComments = personaComments;
    }
}
