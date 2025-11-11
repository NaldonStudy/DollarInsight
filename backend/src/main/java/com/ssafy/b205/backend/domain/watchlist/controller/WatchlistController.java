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
            description = "현재 로그인한 사용자의 관심종목을 최신순으로 반환합니다.",
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
            description = "티커를 전달하면 관심종목에 추가합니다.",
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
            description = "관심종목에서 티커를 제거합니다.",
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
            description = "특정 티커가 내 관심종목에 포함되어 있는지 여부를 반환합니다.",
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
