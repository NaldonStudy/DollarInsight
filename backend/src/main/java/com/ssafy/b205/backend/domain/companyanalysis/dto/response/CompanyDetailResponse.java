package com.ssafy.b205.backend.domain.companyanalysis.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;

import java.util.List;

@Getter
@Schema(description = "기업·ETF 상세 화면 응답. 자산 타입에 따라 일부 블록이 null일 수 있습니다.")
public class CompanyDetailResponse {

    @Schema(description = "기본 정보(티커/거래소/국가/섹터 등)")
    private final AssetBasicInfoResponse basicInfo;

    @Schema(description = "최근 종가·변화율·환산가·기간 고저가")
    private final PriceOverviewResponse priceOverview;

    @Schema(description = "일/주/월 가격 시계열(캔들)")
    private final PriceSeriesResponse priceSeries;

    @Schema(description = "주가 예측(주식만 제공, ETF면 null)")
    private final PredictionBlockResponse predictions;

    @Schema(description = "주식 투자 지표(주식만 채워지고 ETF면 null)")
    private final StockInvestmentIndicatorResponse stockIndicators;

    @Schema(description = "ETF 투자 지표(ETF만 채워지고 주식이면 null)")
    private final EtfInvestmentIndicatorResponse etfIndicators;

    @Schema(description = "주식 점수 카드(주식만 제공)")
    private final StockScoreResponse stockScores;

    @Schema(description = "해당 자산에 대한 페르소나 코멘트")
    private final List<PersonaCommentResponse> personaComments;

    @Schema(description = "관련 최신 뉴스 5건")
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
