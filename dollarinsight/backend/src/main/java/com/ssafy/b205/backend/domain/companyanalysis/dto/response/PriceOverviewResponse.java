package com.ssafy.b205.backend.domain.companyanalysis.dto.response;

import lombok.Getter;

import java.math.BigDecimal;
import java.time.LocalDate;

@Getter
public class PriceOverviewResponse {

    private final BigDecimal latestCloseUsd;
    private final BigDecimal latestCloseKrw;
    private final LocalDate priceDate;
    private final BigDecimal changePct;
    private final BigDecimal periodLow;
    private final BigDecimal periodHigh;

    public PriceOverviewResponse(BigDecimal latestCloseUsd, BigDecimal latestCloseKrw,
                                 LocalDate priceDate, BigDecimal changePct,
                                 BigDecimal periodLow, BigDecimal periodHigh) {
        this.latestCloseUsd = latestCloseUsd;
        this.latestCloseKrw = latestCloseKrw;
        this.priceDate = priceDate;
        this.changePct = changePct;
        this.periodLow = periodLow;
        this.periodHigh = periodHigh;
    }
}
