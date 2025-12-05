package com.ssafy.b205.backend.domain.companyanalysis.dto.response;

import lombok.Getter;

@Getter
public class PredictionBlockResponse {

    private final PredictionPointResponse oneWeek;
    private final PredictionPointResponse oneMonth;

    public PredictionBlockResponse(PredictionPointResponse oneWeek, PredictionPointResponse oneMonth) {
        this.oneWeek = oneWeek;
        this.oneMonth = oneMonth;
    }
}
