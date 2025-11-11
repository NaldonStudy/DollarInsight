package com.ssafy.b205.backend.domain.common.controller;

import com.ssafy.b205.backend.infra.docs.DocRefs;
import com.ssafy.b205.backend.infra.security.TokenProvider;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.enums.ParameterIn;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.core.env.Environment;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.*;

import java.util.Arrays;
import java.util.Map;

@Tag(name = "Common", description = "핑/헬스체크 및 개발 편의 API")
@RestController
@RequestMapping("/api")
public class PingController {

    private final TokenProvider tokenProvider;
    private final Environment env;

    public PingController(TokenProvider tokenProvider, Environment env) {
        this.tokenProvider = tokenProvider;
        this.env = env;
    }

    @Operation(
            summary = "Public ping (no auth)",
            description = "인증 없이 호출 가능한 단순 상태 확인"
    )
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "200", description = "OK",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = Object.class),
                            examples = @ExampleObject(value = """
                            { "ok": true, "scope": "public" }
                            """)
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
    })
    @GetMapping("/public/ping")
    public ResponseEntity<?> publicPing() {
        return ResponseEntity.ok(Map.of("ok", true, "scope", "public"));
    }

    @Operation(
            summary = "Secured ping (requires X-Device-Id + Bearer)",
            description = "Authorization(Bearer) 필수, 헤더로 `X-Device-Id`도 전송해야 합니다.",
            security = @SecurityRequirement(name = "bearerAuth")
    )
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "200", description = "OK",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = Object.class),
                            examples = @ExampleObject(value = """
                            { "ok": true, "scope": "secured" }
                            """)
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", ref = DocRefs.UNAUTHORIZED),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", ref = DocRefs.FORBIDDEN),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
    })
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true,
            description = "디바이스 식별자", example = "11111111-1111-1111-1111-111111111111")
    @PreAuthorize("hasRole('USER')")
    @GetMapping("/ping")
    public ResponseEntity<?> securedPing() {
        return ResponseEntity.ok(Map.of("ok", true, "scope", "secured"));
    }

    // ─────────────────────────────────────────────────────────────────────
    // ⭐ dev 전용 토큰 발급 (로컬/개발 프로필에서만 동작)
    // ─────────────────────────────────────────────────────────────────────
    @Operation(
            summary = "[DEV] Issue access token (local only)",
            description = "로컬/개발 환경에서만 활성화. `X-Device-Id` 헤더 필요."
    )
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "200", description = "발급 성공",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = Object.class),
                            examples = @ExampleObject(value = """
                        { "accessToken": "eyJhbGciOi..." }
                        """)
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", ref = DocRefs.BAD_REQUEST),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", ref = DocRefs.NOT_FOUND),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
    })
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true,
            description = "디바이스 식별자", example = "11111111-1111-1111-1111-111111111111")
    @PostMapping("/public/dev/token")
    public ResponseEntity<?> issueDevToken(@RequestHeader(value = "X-Device-Id", required = false) String deviceId) {
        // 1) 프로필 가드: local 또는 dev에서만 허용
        boolean allowedProfile = Arrays.stream(env.getActiveProfiles())
                .anyMatch(p -> p.equalsIgnoreCase("local") || p.equalsIgnoreCase("dev"));
        if (!allowedProfile) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build(); // 운영에서 노출 방지
        }

        // 2) deviceId 필수
        if (!StringUtils.hasText(deviceId)) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", "[DevToken] X-Device-Id header required.",
                    "data", null
            ));
        }

        // 3) 액세스 토큰 발급 (TokenFilter가 읽는 클레임 구조에 맞춰 발급)
        String accessToken = tokenProvider.createAccessToken("dev-user-1", deviceId);
        return ResponseEntity.ok(Map.of("accessToken", accessToken));
    }
}
