package com.ssafy.b205.backend.domain.companyanalysis.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;

import java.util.List;

@Getter
public class DashboardResponse {

    @Schema(description = "S&P500, 나스닥 등 6개 주요 지수 카드")
    private final List<MajorIndexResponse> majorIndices;

    @Schema(description = "추천 뉴스(Investing.com 최신 기사 3건)")
    private final List<NewsHeadlineResponse> recommendedNews;

    @Schema(description = "페르소나 데일리 픽 카드 리스트")
    private final List<DailyPickResponse> dailyPick;

    public DashboardResponse(List<MajorIndexResponse> majorIndices,
                             List<NewsHeadlineResponse> recommendedNews,
                             List<DailyPickResponse> dailyPick) {
        this.majorIndices = majorIndices;
        this.recommendedNews = recommendedNews;
        this.dailyPick = dailyPick;
    }
}
