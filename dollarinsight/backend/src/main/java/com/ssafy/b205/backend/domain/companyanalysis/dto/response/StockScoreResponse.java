package com.ssafy.b205.backend.domain.companyanalysis.dto.response;

import lombok.Getter;

import java.math.BigDecimal;
import java.time.LocalDate;

@Getter
public class StockScoreResponse {

    private final LocalDate scoreDate;
    private final BigDecimal totalScore;
    private final BigDecimal momentum;
    private final BigDecimal valuation;
    private final BigDecimal growth;
    private final BigDecimal flow;
    private final BigDecimal risk;

    public StockScoreResponse(LocalDate scoreDate, BigDecimal totalScore, BigDecimal momentum,
                              BigDecimal valuation, BigDecimal growth, BigDecimal flow,
                              BigDecimal risk) {
        this.scoreDate = scoreDate;
        this.totalScore = totalScore;
        this.momentum = momentum;
        this.valuation = valuation;
        this.growth = growth;
        this.flow = flow;
        this.risk = risk;
    }
}
