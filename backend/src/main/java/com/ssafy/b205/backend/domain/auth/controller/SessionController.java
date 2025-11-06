package com.ssafy.b205.backend.domain.auth.controller;

import com.ssafy.b205.backend.domain.auth.dto.response.AccessTokenResponse;
import com.ssafy.b205.backend.domain.auth.dto.response.SessionResponse;
import com.ssafy.b205.backend.domain.auth.service.SessionService;
import com.ssafy.b205.backend.support.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "Auth Session")
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class SessionController {

    private final SessionService sessionService;

    @Operation(
            summary = "리프레시로 액세스 재발급",
            description = """
            - X-Device-Id: 디바이스 식별자
            - X-Refresh-Token: 로그인/가입 시 받은 refresh
            성공 시 새 accessToken만 반환합니다.
            """,
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(
                            responseCode = "200", description = "OK",
                            content = @Content(mediaType = "application/json",
                                    schema = @Schema(implementation = AccessTokenResponse.class),
                                    examples = @ExampleObject(value = """
                                        { "accessToken": "eyJhbGciOi..." }
                                    """)))
            }
    )
    @PostMapping("/refresh")
    public ApiResponse<AccessTokenResponse> refresh(
            @RequestHeader("X-Device-Id") String deviceId,
            @RequestHeader("X-Refresh-Token") String refreshToken
    ) {
        String access = sessionService.reissueAccessByRefresh(refreshToken, deviceId);
        return ApiResponse.ok(new AccessTokenResponse(access));
    }

    @Operation(
            summary = "로그아웃",
            description = "V1: 클라이언트 토큰 폐기. V2: refresh 해시 저장 후 revoke 처리 예정.",
            security = @SecurityRequirement(name = "bearerAuth"),
            responses = { @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "204", description = "No Content") }
    )
    @PostMapping("/logout")
    public ResponseEntity<Void> logout(
            @AuthenticationPrincipal String userUuid,
            @RequestHeader("X-Device-Id") String deviceId,
            @RequestHeader(value = "X-Refresh-Token", required = false) String refreshToken
    ) {
        sessionService.logoutByDevice(userUuid, deviceId, refreshToken);
        return ResponseEntity.noContent().build();
    }

    @Operation(
            summary = "내 세션 목록",
            description = "현재 계정의 모든 디바이스 세션 목록을 반환합니다.",
            security = @SecurityRequirement(name = "bearerAuth")
    )
    @GetMapping
    public ApiResponse<List<SessionResponse>> list(@AuthenticationPrincipal String userUuid) {
        return ApiResponse.ok(sessionService.listSessions(userUuid));
    }

    @Operation(
            summary = "세션 강제 로그아웃",
            description = "path의 세션 id가 본인 소유가 아니면 403",
            security = @SecurityRequirement(name = "bearerAuth")
    )
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> revoke(@AuthenticationPrincipal String userUuid, @PathVariable Integer id) {
        sessionService.revokeById(userUuid, id);
        return ResponseEntity.noContent().build();
    }
}
