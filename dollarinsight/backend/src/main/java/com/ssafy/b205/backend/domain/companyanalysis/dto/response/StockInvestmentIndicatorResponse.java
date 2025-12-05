package com.ssafy.b205.backend.domain.companyanalysis.dto.response;

import lombok.Getter;

import java.math.BigDecimal;

@Getter
public class StockInvestmentIndicatorResponse {

    private final BigDecimal marketCap;
    private final BigDecimal dividendYield;
    private final BigDecimal pbr;
    private final BigDecimal per;
    private final BigDecimal roe;
    private final BigDecimal psr;

    public StockInvestmentIndicatorResponse(BigDecimal marketCap, BigDecimal dividendYield,
                                            BigDecimal pbr, BigDecimal per,
                                            BigDecimal roe, BigDecimal psr) {
        this.marketCap = marketCap;
        this.dividendYield = dividendYield;
        this.pbr = pbr;
        this.per = per;
        this.roe = roe;
        this.psr = psr;
    }
}
