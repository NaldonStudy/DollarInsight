package com.ssafy.b205.backend.domain.companyanalysis.controller;

import com.ssafy.b205.backend.domain.companyanalysis.dto.response.AssetMasterResponse;
import com.ssafy.b205.backend.domain.companyanalysis.dto.response.AssetSearchResponse;
import com.ssafy.b205.backend.domain.companyanalysis.dto.response.CompanyDetailResponse;
import com.ssafy.b205.backend.domain.companyanalysis.dto.response.DashboardResponse;
import com.ssafy.b205.backend.domain.companyanalysis.dto.response.NewsDetailResponse;
import com.ssafy.b205.backend.domain.companyanalysis.dto.response.PagedNewsResponse;
import com.ssafy.b205.backend.domain.companyanalysis.service.CompanyAnalysisService;
import com.ssafy.b205.backend.infra.docs.DocRefs;
import com.ssafy.b205.backend.support.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.enums.ParameterIn;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/company-analysis")
@Tag(name = "Company Analysis", description = "기업/ETF 분석 화면 및 뉴스 API")
@SecurityRequirement(name = "bearerAuth")
@Validated
public class CompanyAnalysisController {

    private final CompanyAnalysisService service;

    public CompanyAnalysisController(CompanyAnalysisService service) {
        this.service = service;
    }

    @Operation(
            summary = "기업분석 대시보드",
            description = """
                    주요 지수·추천 뉴스·페르소나 데일리 픽을 한 번에 내려줍니다.
                    
                    * `majorIndices`: S&P 500, 나스닥 등 6개 지수의 최신 종가/등락률
                    * `recommendedNews`: MongoDB `investing_news`에서 샘플링한 3건
                    * `dailyPick`: MongoDB `company_analysis`에서 뽑은 5개 종목 + 페르소나 코멘트 (ticker 포함 → 상세 화면 이동에 사용)
                    """,
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "OK",
                            content = @Content(schema = @Schema(implementation = DashboardResponse.class))),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", ref = DocRefs.UNAUTHORIZED),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", ref = DocRefs.FORBIDDEN),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
            }
    )
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true, description = "디바이스 식별자")
    @GetMapping("/dashboard")
    public ApiResponse<DashboardResponse> getDashboard() {
        return ApiResponse.ok(service.getDashboard());
    }

    @Operation(
            summary = "티커 검색",
            description = """
                    주식/ETF 통합 자동완성용 검색입니다.
                    
                    * `keyword`는 티커, 국문명, 영문명(주식), ETF 이름에 대해 부분 일치(ILIKE)로 매칭됩니다.
                    * 응답에는 `ticker`, `assetType`, `name`, `nameEng`, `exchange`가 포함되어 상세 API 호출에 바로 사용 가능합니다.
                    """,
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "OK",
                            content = @Content(schema = @Schema(implementation = AssetSearchResponse.class))),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", ref = DocRefs.UNAUTHORIZED),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", ref = DocRefs.FORBIDDEN),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
            }
    )
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true, description = "디바이스 식별자")
    @GetMapping("/search")
    public ApiResponse<List<AssetSearchResponse>> searchAssets(
            @RequestParam("keyword") @NotBlank @Size(min = 1, max = 50) String keyword,
            @RequestParam(value = "size", defaultValue = "10") @Min(1) @Max(30) int size
    ) {
        return ApiResponse.ok(service.searchAssets(keyword, size));
    }

    @Operation(
            summary = "자산 마스터 전체 목록",
            description = """
                    `assets_master` 테이블에서 STOCK/ETF 티커 전체를 내려줍니다.
                    
                    * `type` 쿼리 파라미터를 여러 번 넘기면 해당 타입만 필터링합니다. (예: `?type=stock&type=etf`)
                    * 생략하면 기본으로 STOCK, ETF 두 가지 타입을 모두 내려줍니다.
                    """,
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "OK",
                            content = @Content(schema = @Schema(implementation = AssetMasterResponse.class))),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", ref = DocRefs.UNAUTHORIZED),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", ref = DocRefs.FORBIDDEN),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
            }
    )
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true, description = "디바이스 식별자")
    @GetMapping("/assets")
    public ApiResponse<List<AssetMasterResponse>> listAssets(
            @RequestParam(value = "type", required = false) List<String> typeFilters
    ) {
        return ApiResponse.ok(service.listAssets(typeFilters));
    }

    @Operation(
            summary = "기업/ETF 상세",
            description = """
                    기본정보·가격 히스토리·예측·투자지표·뉴스를 한 번에 내려줍니다.
                    
                    * 주식(STOCK)은 `predictions`, `stockIndicators`, `stockScores`가 채워지고 `etfIndicators`는 null입니다.
                    * ETF는 `etfIndicators`만 채워지고 `predictions`, `stockIndicators`, `stockScores`는 null입니다.
                    프런트는 자산 타입 또는 null 여부를 보고 필요한 카드만 렌더링하면 됩니다.
                    """,
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "OK",
                            content = @Content(schema = @Schema(implementation = CompanyDetailResponse.class))),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", ref = DocRefs.UNAUTHORIZED),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", ref = DocRefs.FORBIDDEN),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", ref = DocRefs.NOT_FOUND),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
            }
    )
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true, description = "디바이스 식별자")
    @GetMapping("/{ticker}")
    public ApiResponse<CompanyDetailResponse> getCompanyDetail(@PathVariable String ticker) {
        return ApiResponse.ok(service.getCompanyDetail(ticker));
    }

    @Operation(
            summary = "뉴스 목록",
            description = """
                    Investing.com 기반 뉴스 피드입니다.
                    
                    * `ticker`를 넘기면 해당 티커(또는 연관 기업) 기사만, 생략하면 전체 기사
                    * `page`/`size`로 Mongo 컬렉션을 페이징하며, 응답의 `items[].id`를 상세 조회에 사용합니다.
                    """,
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "OK",
                            content = @Content(schema = @Schema(implementation = PagedNewsResponse.class))),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", ref = DocRefs.UNAUTHORIZED),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", ref = DocRefs.FORBIDDEN),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
            }
    )
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true, description = "디바이스 식별자")
    @GetMapping("/news")
    public ApiResponse<PagedNewsResponse> getNews(
            @RequestParam(required = false) String ticker,
            @RequestParam(defaultValue = "0") @Min(0) int page,
            @RequestParam(defaultValue = "20") @Min(1) @Max(100) int size
    ) {
        return ApiResponse.ok(service.getNewsFeed(ticker, page, size));
    }

    @Operation(
            summary = "뉴스 상세",
            description = """
                    Investing.com 원문 + 페르소나 코멘트를 내려줍니다.
                    
                    * `id`는 목록 응답의 Mongo `_id` 문자열입니다.
                    * `personaComments`는 `news_persona_analysis`에서 생성된 다섯 페르소나의 의견입니다.
                    """,
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "OK",
                            content = @Content(schema = @Schema(implementation = NewsDetailResponse.class))),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", ref = DocRefs.UNAUTHORIZED),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", ref = DocRefs.FORBIDDEN),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", ref = DocRefs.NOT_FOUND),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
            }
    )
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true, description = "디바이스 식별자")
    @GetMapping("/news/{newsId}")
    public ApiResponse<NewsDetailResponse> getNewsDetail(@PathVariable String newsId) {
        return ApiResponse.ok(service.getNewsDetail(newsId));
    }
}
