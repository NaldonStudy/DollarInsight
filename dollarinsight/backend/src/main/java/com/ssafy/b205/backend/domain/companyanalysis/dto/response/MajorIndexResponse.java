package com.ssafy.b205.backend.domain.companyanalysis.dto.response;

import lombok.Getter;

import java.math.BigDecimal;
import java.time.LocalDate;

@Getter
public class MajorIndexResponse {

    private final String ticker;
    private final String name;
    private final BigDecimal close;
    private final BigDecimal changePct;
    private final LocalDate priceDate;

    public MajorIndexResponse(String ticker, String name, BigDecimal close,
                              BigDecimal changePct, LocalDate priceDate) {
        this.ticker = ticker;
        this.name = name;
        this.close = close;
        this.changePct = changePct;
        this.priceDate = priceDate;
    }
}
