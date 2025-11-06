package com.ssafy.b205.backend.domain.auth.controller;

import com.ssafy.b205.backend.domain.auth.dto.response.AccessTokenResponse;
import com.ssafy.b205.backend.domain.auth.service.SessionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.enums.ParameterIn;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@Tag(name = "Auth Session")
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class SessionController {

    private final SessionService sessionService;

    @Operation(
            summary = "리프레시로 액세스 재발급",
            description = """
        모바일: 헤더로 refresh 전달.
        - X-Device-Id: 디바이스 식별자(임의 문자열, 서버가 trim+소문자+최대128자로 정규화)
        - X-Refresh-Token: 로그인/가입 시 받은 refresh
        성공 시 새 accessToken만 반환합니다.
        """,
            // X-Device-Id는 전역 Authorize로 주입
            security = { @SecurityRequirement(name = "deviceId") },
            // refreshToken은 이 API에서만 필요 → 파라미터로 남김
            parameters = {
                    @Parameter(
                            name = "X-Refresh-Token",
                            in = ParameterIn.HEADER,
                            required = true,
                            description = "리프레시 토큰"
                    )
            },
            responses = {
                    @ApiResponse(responseCode = "200", description = "OK",
                            content = @Content(
                                    mediaType = "application/json",
                                    schema = @Schema(implementation = AccessTokenResponse.class),
                                    examples = @ExampleObject(
                                            name = "성공",
                                            value = """
                        { "accessToken": "eyJhbGciOi..." }
                        """
                                    )
                            )
                    )
            }
    )
    @PostMapping("/refresh")
    public ResponseEntity<AccessTokenResponse> refresh(
            @RequestHeader("X-Device-Id") String deviceId,
            @RequestHeader("X-Refresh-Token") String refreshToken
    ) {
        String access = sessionService.reissueAccessByRefresh(refreshToken, deviceId);
        return ResponseEntity.ok(new AccessTokenResponse(access));
    }

    @Operation(
            summary = "로그아웃",
            description = """
        V1: 서버 세션 저장이 없어도 클라이언트 토큰을 폐기합니다.
        V2에서는 refresh 해시 저장 및 revoke 처리를 수행합니다.
        """,
            // 보호 API → 전역 Authorize로 Bearer + DeviceId 자동 주입
            security = {
                    @SecurityRequirement(name = "bearerAuth"),
                    @SecurityRequirement(name = "deviceId")
            },
            parameters = {
                    @Parameter(
                            name = "X-Refresh-Token",
                            in = ParameterIn.HEADER,
                            required = false,
                            description = "리프레시 토큰(있으면 해당 세션만 revoke, 없으면 디바이스 전체 세션 revoke)"
                    )
            },
            responses = { @ApiResponse(responseCode = "204", description = "No Content") }
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
}
