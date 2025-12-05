package com.ssafy.b205.backend.infra.mongo.companyanalysis.doc;

import com.ssafy.b205.backend.domain.companyanalysis.model.PersonaCommentSource;
import lombok.Getter;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;

import java.time.Instant;

@Getter
@Document(collection = "news_persona_analysis")
public class NewsPersonaAnalysisDoc implements PersonaCommentSource {

    private String id;

    @Field("news_id")
    private String newsId;

    @Field("news_url")
    private String newsUrl;

    @Field("analyzed_at")
    private Instant analyzedAt;

    @Field("persona_deoksu")
    private String personaDeoksu;

    @Field("persona_heuyeol")
    private String personaHeuyeol;

    @Field("persona_jiyul")
    private String personaJiyul;

    @Field("persona_minji")
    private String personaMinji;

    @Field("persona_teo")
    private String personaTeo;
}

