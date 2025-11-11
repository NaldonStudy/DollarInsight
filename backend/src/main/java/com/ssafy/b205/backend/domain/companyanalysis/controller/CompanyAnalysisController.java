package com.ssafy.b205.backend.domain.companyanalysis.controller;

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
            description = "주요 지수와 추천 뉴스, 페르소나 데일리 픽을 반환합니다.",
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
            description = "자산명/심볼을 대상으로 주식·ETF를 검색합니다.",
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
            summary = "기업/ETF 상세",
            description = "기본정보와 가격 히스토리, 예측, 투자지표, 뉴스 묶음을 내려줍니다.",
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
            description = "티커 필터가 없으면 전체 뉴스를, 있으면 해당 종목 뉴스만 페이지네이션으로 제공합니다.",
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
            description = "기사 제목/본문 요약/URL과 페르소나 코멘트를 내려줍니다.",
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
    public ApiResponse<NewsDetailResponse> getNewsDetail(@PathVariable long newsId) {
        return ApiResponse.ok(service.getNewsDetail(newsId));
    }
}
