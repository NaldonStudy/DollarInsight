package com.ssafy.b205.backend.infra.mongo.companyanalysis.doc;

import com.ssafy.b205.backend.domain.companyanalysis.model.PersonaCommentSource;
import lombok.Getter;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;

import java.time.Instant;
import java.time.LocalDate;

@Getter
@Document(collection = "company_analysis")
public class CompanyAnalysisDoc implements PersonaCommentSource {

    private String id;

    @Field("ticker")
    private String ticker;

    @Field("company_name")
    private String companyName;

    @Field("company_info")
    private String companyInfo;

    @Field("analyzed_date")
    private LocalDate analyzedDate;

    @Field("analyzed_at")
    private Instant analyzedAt;

    @Field("created_at")
    private Instant createdAt;

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
