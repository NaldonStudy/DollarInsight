package com.ssafy.b205.backend.domain.companyanalysis.dto.response;

import lombok.Getter;

import java.util.List;

@Getter
public class PriceSeriesResponse {

    private final List<PriceCandleResponse> dailyRange;
    private final List<PriceCandleResponse> weeklyRange;
    private final List<PriceCandleResponse> monthlyRange;

    public PriceSeriesResponse(List<PriceCandleResponse> dailyRange,
                               List<PriceCandleResponse> weeklyRange,
                               List<PriceCandleResponse> monthlyRange) {
        this.dailyRange = dailyRange;
        this.weeklyRange = weeklyRange;
        this.monthlyRange = monthlyRange;
    }
}
