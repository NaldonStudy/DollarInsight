package com.ssafy.b205.backend.domain.companyanalysis.dto.response;

import lombok.Getter;

import java.util.List;

@Getter
public class CompanyDetailResponse {

    private final AssetBasicInfoResponse basicInfo;
    private final PriceOverviewResponse priceOverview;
    private final PriceSeriesResponse priceSeries;
    private final PredictionBlockResponse predictions;
    private final StockInvestmentIndicatorResponse stockIndicators;
    private final EtfInvestmentIndicatorResponse etfIndicators;
    private final StockScoreResponse stockScores;
    private final List<PersonaCommentResponse> personaComments;
    private final List<NewsHeadlineResponse> latestNews;

    public CompanyDetailResponse(AssetBasicInfoResponse basicInfo,
                                 PriceOverviewResponse priceOverview,
                                 PriceSeriesResponse priceSeries,
                                 PredictionBlockResponse predictions,
                                 StockInvestmentIndicatorResponse stockIndicators,
                                 EtfInvestmentIndicatorResponse etfIndicators,
                                 StockScoreResponse stockScores,
                                 List<PersonaCommentResponse> personaComments,
                                 List<NewsHeadlineResponse> latestNews) {
        this.basicInfo = basicInfo;
        this.priceOverview = priceOverview;
        this.priceSeries = priceSeries;
        this.predictions = predictions;
        this.stockIndicators = stockIndicators;
        this.etfIndicators = etfIndicators;
        this.stockScores = stockScores;
        this.personaComments = personaComments;
        this.latestNews = latestNews;
    }
}
