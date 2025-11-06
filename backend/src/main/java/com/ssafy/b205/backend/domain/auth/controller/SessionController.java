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
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
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
            - 헤더 `X-Device-Id`: 앱 고정 UUID (필수)
            - 헤더 `X-Refresh-Token`: 로그인/가입 시 받은 refresh (필수)
            성공 시 새 accessToken만 반환합니다.
            """,
            parameters = {
                    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true, description = "디바이스 고정 UUID v4"),
                    @Parameter(name = "X-Refresh-Token", in = ParameterIn.HEADER, required = true, description = "리프레시 토큰")
            },
            responses = {
                    @ApiResponse(responseCode = "200", description = "OK",
                            content = @Content(
                                    mediaType = "application/json",
                                    schema = @Schema(implementation = AccessTokenResponse.class),
                                    examples = @ExampleObject(
                                            name = "성공",
                                            value = """
                                            {
                                              "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0eXAiOiJhY2Nlc3MiLCJzdWIiOiI3ZTI2YjZkZi1iY2I4LTQ4ZmYtODVhZi1iN2I1YWU5YzQ2Y2QiLCJkaWQiOiI5NGYxZWY1Yy0yYzM3LTRjNjMtOTU0Yy1mN2E2Yzk2ZGU4N2EiLCJleHAiOjE3OTE2NDAwMDB9.sig"
                                            }
                                            """
                                    )
                            )),
                    @ApiResponse(responseCode = "400", description = "잘못된 토큰/디바이스 불일치",
                            content = @Content(
                                    mediaType = "application/json",
                                    examples = @ExampleObject(
                                            name = "디바이스 불일치",
                                            value = """
                                            {
                                              "type": "about:blank",
                                              "title": "Bad Request",
                                              "status": 400,
                                              "detail": "Device mismatch",
                                              "instance": "/api/auth/refresh"
                                            }
                                            """
                                    )
                            )),
                    @ApiResponse(responseCode = "401", description = "미인증",
                            content = @Content(
                                    mediaType = "application/json",
                                    examples = @ExampleObject(
                                            name = "미인증",
                                            value = """
                                            {
                                              "type": "about:blank",
                                              "title": "Unauthorized",
                                              "status": 401,
                                              "detail": "인증이 필요합니다.",
                                              "instance": "/api/auth/refresh"
                                            }
                                            """
                                    )
                            )),
                    @ApiResponse(responseCode = "403", description = "디바이스 바인딩 위반",
                            content = @Content(
                                    mediaType = "application/json",
                                    examples = @ExampleObject(
                                            name = "바인딩 위반",
                                            value = """
                                            {
                                              "type": "about:blank",
                                              "title": "Forbidden",
                                              "status": 403,
                                              "detail": "디바이스 바인딩 위반",
                                              "instance": "/api/auth/refresh"
                                            }
                                            """
                                    )
                            )),
                    @ApiResponse(responseCode = "500", description = "서버 오류",
                            content = @Content(
                                    mediaType = "application/json",
                                    examples = @ExampleObject(
                                            name = "서버 오류",
                                            value = """
                                            {
                                              "type": "about:blank",
                                              "title": "Internal Server Error",
                                              "status": 500,
                                              "detail": "서버 오류가 발생했습니다.",
                                              "instance": "/api/auth/refresh"
                                            }
                                            """
                                    )
                            ))
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
            V1: 서버 세션 저장이 없어 no-op 동작(클라이언트 토큰 삭제).
            V2에서 refresh 해시 저장 및 revoke 처리를 추가할 예정입니다.
            """,
            parameters = {
                    @Parameter(name = "Authorization", in = ParameterIn.HEADER, required = true, description = "Bearer {accessToken}"),
                    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true, description = "디바이스 고정 UUID v4"),
                    @Parameter(name = "X-Refresh-Token", in = ParameterIn.HEADER, required = false, description = "리프레시 토큰(있으면 함께 전달)")
            },
            responses = {
                    @ApiResponse(responseCode = "204", description = "No Content")
            }
    )
    @PostMapping("/logout")
    public ResponseEntity<Void> logout(
            @RequestHeader("X-Device-Id") String deviceId,
            @RequestHeader(value = "X-Refresh-Token", required = false) String refreshToken
    ) {
        sessionService.logoutByDevice(null, deviceId, refreshToken);
        return ResponseEntity.noContent().build();
    }
}
