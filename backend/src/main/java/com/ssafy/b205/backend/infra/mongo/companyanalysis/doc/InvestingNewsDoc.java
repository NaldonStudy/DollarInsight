package com.ssafy.b205.backend.infra.mongo.companyanalysis.doc;

import lombok.Getter;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;

import java.time.Instant;
import java.util.List;

@Getter
@Document(collection = "investing_news")
public class InvestingNewsDoc {

    private String id;

    private String title;
    private String content;
    private String summary;
    private String url;

    @Field("ticker")
    private String ticker;

    @Field("date")
    private Instant publishedAt;

    @Field("created_at")
    private Instant createdAt;

    @Field("persona_analysis_id")
    private String personaAnalysisId;

    @Field("related_companies")
    private List<String> relatedCompanies = List.of();
}
