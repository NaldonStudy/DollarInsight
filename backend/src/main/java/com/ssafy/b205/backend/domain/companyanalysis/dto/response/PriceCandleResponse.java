package com.ssafy.b205.backend.domain.companyanalysis.dto.response;

import lombok.Getter;

import java.math.BigDecimal;
import java.time.LocalDate;

@Getter
public class PriceCandleResponse {

    private final LocalDate priceDate;
    private final BigDecimal open;
    private final BigDecimal high;
    private final BigDecimal low;
    private final BigDecimal close;

    public PriceCandleResponse(LocalDate priceDate, BigDecimal open, BigDecimal high,
                               BigDecimal low, BigDecimal close) {
        this.priceDate = priceDate;
        this.open = open;
        this.high = high;
        this.low = low;
        this.close = close;
    }
}
