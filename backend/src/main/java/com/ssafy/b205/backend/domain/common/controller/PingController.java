package com.ssafy.b205.backend.domain.common.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.core.env.Environment;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.*;

import com.ssafy.b205.backend.infra.security.TokenProvider;

import java.util.Arrays;
import java.util.List;
import java.util.Map;

@Tag(name = "Common")
@RestController
@RequestMapping("/api")
public class PingController {

    private final TokenProvider tokenProvider;
    private final Environment env;

    public PingController(TokenProvider tokenProvider, Environment env) {
        this.tokenProvider = tokenProvider;
        this.env = env;
    }

    @Operation(summary = "Public ping (no auth)")
    @GetMapping("/public/ping")
    public ResponseEntity<?> publicPing() {
        return ResponseEntity.ok(Map.of("ok", true, "scope", "public"));
    }

    @Operation(
            summary = "Secured ping (requires X-Device-Id + Bearer)",
            security = {
                    @SecurityRequirement(name = "deviceId"),
                    @SecurityRequirement(name = "bearerAuth")
            }
    )
    @PreAuthorize("hasRole('USER')")
    @GetMapping("/ping")
    public ResponseEntity<?> securedPing() {
        return ResponseEntity.ok(Map.of("ok", true, "scope", "secured"));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ⭐ dev 전용 토큰 발급 (로컬/개발 프로필에서만 동작)
    // Swagger Authorize의 deviceId만 필요. Bearer는 필요 없음.
    // ─────────────────────────────────────────────────────────────────────────
    @Operation(
            summary = "[DEV] Issue access token (local only)",
            description = "로컬/개발 환경에서만 활성화. X-Device-Id 헤더 필요.",
            security = { @SecurityRequirement(name = "deviceId") } // 헤더 자동 주입
    )
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

        // 3) 액세스 토큰 발급
        // TokenFilter가 'sub'(subject), 'did'(deviceId), 'roles'를 읽으므로 동일한 클레임으로 발급해야 함.
        // TokenProvider 시그니처에 맞춰 아래 한 줄을 조정하세요.
        String accessToken = tokenProvider.createAccessToken("dev-user-1", deviceId);

        return ResponseEntity.ok(Map.of("accessToken", accessToken));
    }
}
