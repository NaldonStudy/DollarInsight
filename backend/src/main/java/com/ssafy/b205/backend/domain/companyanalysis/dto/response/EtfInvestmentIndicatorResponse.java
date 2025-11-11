package com.ssafy.b205.backend.domain.companyanalysis.dto.response;

import lombok.Getter;

import java.math.BigDecimal;
import java.time.LocalDate;

@Getter
public class EtfInvestmentIndicatorResponse {

    private final LocalDate asOfDate;
    private final BigDecimal marketCap;
    private final BigDecimal dividendYield;
    private final BigDecimal totalAssets;
    private final BigDecimal nav;
    private final BigDecimal premiumDiscount;
    private final BigDecimal expenseRatio;

    public EtfInvestmentIndicatorResponse(LocalDate asOfDate, BigDecimal marketCap,
                                          BigDecimal dividendYield, BigDecimal totalAssets,
                                          BigDecimal nav, BigDecimal premiumDiscount,
                                          BigDecimal expenseRatio) {
        this.asOfDate = asOfDate;
        this.marketCap = marketCap;
        this.dividendYield = dividendYield;
        this.totalAssets = totalAssets;
        this.nav = nav;
        this.premiumDiscount = premiumDiscount;
        this.expenseRatio = expenseRatio;
    }
}
