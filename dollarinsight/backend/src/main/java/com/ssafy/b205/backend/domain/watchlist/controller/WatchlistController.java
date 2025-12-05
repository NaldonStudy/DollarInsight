package com.ssafy.b205.backend.domain.watchlist.controller;

import com.ssafy.b205.backend.domain.watchlist.dto.request.WatchlistAddRequest;
import com.ssafy.b205.backend.domain.watchlist.dto.response.WatchlistItemResponse;
import com.ssafy.b205.backend.domain.watchlist.dto.response.WatchlistStatusResponse;
import com.ssafy.b205.backend.domain.watchlist.service.WatchlistService;
import com.ssafy.b205.backend.infra.docs.DocRefs;
import com.ssafy.b205.backend.support.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.enums.ParameterIn;
import io.swagger.v3.oas.annotations.media.ArraySchema;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Locale;

@RestController
@RequestMapping("/api/watchlist")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Watchlist", description = "관심종목 관리 API")
@Validated
public class WatchlistController {

    private final WatchlistService watchlistService;

    public WatchlistController(WatchlistService watchlistService) {
        this.watchlistService = watchlistService;
    }

    @Operation(
            summary = "내 관심종목 목록",
            description = """
                    로그인한 사용자의 관심종목을 최신 등록순으로 반환합니다.
                    
                    * 서버가 ticker를 대문자로 정규화하고, 존재하지 않는 자산은 거르므로 안전하게 가격/거래소 정보를 함께 내려줍니다.
                    * 각 항목에는 `priceDate`, `close`, `changePct`가 포함돼 있어 관심 리스트 화면을 바로 렌더링할 수 있습니다.
                    """,
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "OK",
                            content = @Content(array = @ArraySchema(schema = @Schema(implementation = WatchlistItemResponse.class)))),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", ref = DocRefs.UNAUTHORIZED),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
            }
    )
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true, description = "디바이스 식별자")
    @GetMapping
    public ApiResponse<List<WatchlistItemResponse>> list(@AuthenticationPrincipal String userUuid) {
        return ApiResponse.ok(watchlistService.getMyWatchlist(userUuid));
    }

    @Operation(
            summary = "관심종목 등록",
            description = """
                    ticker를 관심종목에 추가합니다.
                    
                    * 서버가 공백 제거 + 대문자 변환 후 존재 여부와 자산 타입을 검증합니다.
                    * 이미 등록된 티커는 `409 CONFLICT`로 응답합니다.
                    * 성공 시 본문 없이 201 Created, 이후 목록 조회 시 최신 순으로 나타납니다.
                    """,
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "201", description = "Created"),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", ref = DocRefs.BAD_REQUEST),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", ref = DocRefs.UNAUTHORIZED),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", ref = DocRefs.NOT_FOUND),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "409", ref = DocRefs.CONFLICT),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
            }
    )
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true, description = "디바이스 식별자")
    @PostMapping
    public ResponseEntity<Void> add(
            @AuthenticationPrincipal String userUuid,
            @Valid @RequestBody WatchlistAddRequest request
    ) {
        watchlistService.add(userUuid, request.normalizedTicker());
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @Operation(
            summary = "관심종목 삭제",
            description = """
                    관심종목에서 특정 ticker를 제거합니다.
                    
                    * Path 변수는 대소문자 구분 없이 처리되며 서버가 존재 여부를 확인합니다.
                    * 목록에 없는 ticker를 삭제하려 하면 404가 반환됩니다.
                    """,
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "204", description = "No Content"),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", ref = DocRefs.BAD_REQUEST),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", ref = DocRefs.UNAUTHORIZED),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", ref = DocRefs.NOT_FOUND),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
            }
    )
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true, description = "디바이스 식별자")
    @DeleteMapping("/{ticker}")
    public ResponseEntity<Void> remove(
            @AuthenticationPrincipal String userUuid,
            @PathVariable String ticker
    ) {
        watchlistService.remove(userUuid, ticker);
        return ResponseEntity.noContent().build();
    }

    @Operation(
            summary = "관심종목 여부 확인",
            description = """
                    단일 ticker가 내 관심종목에 포함되어 있는지 Boolean으로 알려줍니다.
                    
                    * Path ticker는 서버가 대문자로 정규화합니다.
                    * 존재하지 않는 자산이면 404, 있으면 `{ \"ticker\": \"NVDA\", \"watching\": true|false }`.
                    """,
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "OK",
                            content = @Content(schema = @Schema(implementation = WatchlistStatusResponse.class))),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", ref = DocRefs.BAD_REQUEST),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", ref = DocRefs.UNAUTHORIZED),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", ref = DocRefs.NOT_FOUND),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
            }
    )
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true, description = "디바이스 식별자")
    @GetMapping("/{ticker}/status")
    public ApiResponse<WatchlistStatusResponse> status(
            @AuthenticationPrincipal String userUuid,
            @PathVariable String ticker
    ) {
        String normalized = ticker == null ? null : ticker.trim().toUpperCase(Locale.ROOT);
        boolean watching = watchlistService.isWatching(userUuid, normalized);
        return ApiResponse.ok(new WatchlistStatusResponse(normalized, watching));
    }
}
