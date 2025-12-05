package com.ssafy.b205.backend.domain.companyanalysis.dto.response;

import lombok.Getter;

import java.math.BigDecimal;
import java.time.LocalDate;

@Getter
public class PredictionPointResponse {

    private final int horizonDays;
    private final LocalDate predictionDate;
    private final BigDecimal pointEstimate;
    private final BigDecimal lowerBound;
    private final BigDecimal upperBound;
    private final BigDecimal probabilityUp;

    public PredictionPointResponse(int horizonDays, LocalDate predictionDate,
                                   BigDecimal pointEstimate, BigDecimal lowerBound,
                                   BigDecimal upperBound, BigDecimal probabilityUp) {
        this.horizonDays = horizonDays;
        this.predictionDate = predictionDate;
        this.pointEstimate = pointEstimate;
        this.lowerBound = lowerBound;
        this.upperBound = upperBound;
        this.probabilityUp = probabilityUp;
    }
}
