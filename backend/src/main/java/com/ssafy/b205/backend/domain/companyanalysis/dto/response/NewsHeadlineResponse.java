package com.ssafy.b205.backend.domain.companyanalysis.dto.response;

import lombok.Getter;

import java.time.Instant;

@Getter
public class NewsHeadlineResponse {

    private final Long id;
    private final String ticker;
    private final String title;
    private final String source;
    private final Instant publishedAt;

    public NewsHeadlineResponse(Long id, String ticker, String title, String source, Instant publishedAt) {
        this.id = id;
        this.ticker = ticker;
        this.title = title;
        this.source = source;
        this.publishedAt = publishedAt;
    }
}
