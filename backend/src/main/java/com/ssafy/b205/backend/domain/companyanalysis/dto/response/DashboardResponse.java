package com.ssafy.b205.backend.domain.companyanalysis.dto.response;

import lombok.Getter;

import java.util.List;

@Getter
public class DashboardResponse {

    private final List<MajorIndexResponse> majorIndices;
    private final List<NewsHeadlineResponse> recommendedNews;
    private final DailyPickResponse dailyPick;

    public DashboardResponse(List<MajorIndexResponse> majorIndices,
                             List<NewsHeadlineResponse> recommendedNews,
                             DailyPickResponse dailyPick) {
        this.majorIndices = majorIndices;
        this.recommendedNews = recommendedNews;
        this.dailyPick = dailyPick;
    }
}
