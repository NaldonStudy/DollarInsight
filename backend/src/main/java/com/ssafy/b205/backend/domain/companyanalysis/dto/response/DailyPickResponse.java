package com.ssafy.b205.backend.domain.companyanalysis.dto.response;

import com.ssafy.b205.backend.domain.companyanalysis.model.AssetType;
import lombok.Getter;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Getter
public class DailyPickResponse {

    private final String ticker;
    private final AssetType assetType;
    private final String name;
    private final BigDecimal latestCloseUsd;
    private final BigDecimal latestCloseKrw;
    private final LocalDate priceDate;
    private final List<PersonaCommentResponse> personaComments;

    public DailyPickResponse(String ticker, AssetType assetType, String name,
                             BigDecimal latestCloseUsd, BigDecimal latestCloseKrw,
                             LocalDate priceDate, List<PersonaCommentResponse> personaComments) {
        this.ticker = ticker;
        this.assetType = assetType;
        this.name = name;
        this.latestCloseUsd = latestCloseUsd;
        this.latestCloseKrw = latestCloseKrw;
        this.priceDate = priceDate;
        this.personaComments = personaComments;
    }
}
