package com.ssafy.b205.backend.domain.auth.controller;

import com.ssafy.b205.backend.domain.auth.dto.response.AccessTokenResponse;
import com.ssafy.b205.backend.domain.auth.dto.response.SessionResponse;
import com.ssafy.b205.backend.domain.auth.service.SessionService;
import com.ssafy.b205.backend.infra.docs.DocRefs;
import com.ssafy.b205.backend.support.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.enums.ParameterIn;
import io.swagger.v3.oas.annotations.media.ArraySchema;
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
import java.util.UUID;

@Tag(
        name = "Auth Session",
        description = "세션/토큰 관리 API. 대부분의 엔드포인트는 `X-Device-Id` 헤더가 필요하며, "
                + "/refresh 는 Authorization 없이 `X-Refresh-Token`으로 재발급합니다."
)
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class SessionController {

    private final SessionService sessionService;

    @Operation(
            summary = "리프레시로 액세스 재발급",
            description = """
            - 필수 헤더:
              • X-Device-Id — 디바이스 식별자
              • X-Refresh-Token — 로그인/가입 시 받은 리프레시 토큰
            - 성공 시: 새 accessToken만 반환합니다.
            """,
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(
                            responseCode = "200", description = "OK",
                            content = @Content(
                                    mediaType = "application/json",
                                    schema = @Schema(implementation = AccessTokenResponse.class),
                                    examples = @ExampleObject(name = "success", value = """
                                    { "accessToken": "eyJhbGciOi..." }
                                    """)
                            )
                    ),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", ref = DocRefs.BAD_REQUEST),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", ref = DocRefs.UNAUTHORIZED),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", ref = DocRefs.FORBIDDEN),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", ref = DocRefs.NOT_FOUND),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
            }
    )
    @PostMapping("/refresh")
    public ApiResponse<AccessTokenResponse> refresh(
            @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true,
                    description = "디바이스 식별자", example = "11111111-1111-1111-1111-111111111111")
            @RequestHeader("X-Device-Id") String deviceId,
            @Parameter(name = "X-Refresh-Token", in = ParameterIn.HEADER, required = true,
                    description = "리프레시 토큰", example = "eyJhbGciOi...")
            @RequestHeader("X-Refresh-Token") String refreshToken
    ) {
        String access = sessionService.reissueAccessByRefresh(refreshToken, deviceId);
        return ApiResponse.ok(new AccessTokenResponse(access));
    }

    @Operation(
            summary = "로그아웃",
            description = """
            - 필수: Authorization(Bearer), X-Device-Id
            - 선택: X-Refresh-Token (있다면 함께 폐기)
            - 현재 **해당 DID의 세션**을 무력화합니다.
            """,
            security = @SecurityRequirement(name = "bearerAuth"),
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "204", description = "No Content"),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", ref = DocRefs.UNAUTHORIZED),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", ref = DocRefs.FORBIDDEN),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", ref = DocRefs.NOT_FOUND),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
            }
    )
    @PostMapping("/logout")
    public ResponseEntity<Void> logout(
            @AuthenticationPrincipal String userUuid,
            @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true,
                    description = "현재 기기의 DID", example = "11111111-1111-1111-1111-111111111111")
            @RequestHeader("X-Device-Id") String deviceId,
            @Parameter(name = "X-Refresh-Token", in = ParameterIn.HEADER, required = false,
                    description = "보유 시 함께 폐기", example = "eyJhbGciOi...")
            @RequestHeader(value = "X-Refresh-Token", required = false) String refreshToken
    ) {
        sessionService.logoutByDevice(userUuid, deviceId, refreshToken);
        return ResponseEntity.noContent().build();
    }

    @Operation(
            summary = "내 세션 목록",
            description = "- 현재 계정에 활성화된 모든 디바이스 세션을 반환합니다.",
            security = @SecurityRequirement(name = "bearerAuth"),
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(
                            responseCode = "200", description = "OK",
                            content = @Content(
                                    mediaType = "application/json",
                                    array = @ArraySchema(schema = @Schema(implementation = SessionResponse.class)),
                                    examples = @ExampleObject(name = "success", value = """
                                    [
                                      {
                                        "uuid": "0f1e2d3c-4b5a-6978-9012-abcdefabcdef",
                                        "deviceId": "my-phone-01",
                                        "createdAt": "2025-11-09T12:00:00Z",
                                        "lastUsedAt": "2025-11-10T02:00:00Z",
                                        "client": "android 1.3.2"
                                      }
                                    ]
                                    """)
                            )
                    ),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", ref = DocRefs.UNAUTHORIZED),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
            }
    )
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true,
            description = "디바이스 식별자", example = "11111111-1111-1111-1111-111111111111")
    @GetMapping
    public ApiResponse<List<SessionResponse>> list(@AuthenticationPrincipal String userUuid) {
        return ApiResponse.ok(sessionService.listSessions(userUuid));
    }

    @Operation(
            summary = "세션 강제 로그아웃 (UUID)",
            description = """
            - Path: 세션 UUID
            - 대상 세션이 본인 계정 소유가 아니면 404 처리합니다.
            """,
            security = @SecurityRequirement(name = "bearerAuth"),
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "204", description = "No Content"),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", ref = DocRefs.UNAUTHORIZED),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", ref = DocRefs.NOT_FOUND),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
            }
    )
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true,
            description = "디바이스 식별자", example = "11111111-1111-1111-1111-111111111111")
    @DeleteMapping("/uuid/{sid}")
    public ResponseEntity<Void> revokeByUuid(
            @AuthenticationPrincipal String userUuid,
            @Parameter(name = "sid", in = ParameterIn.PATH, required = true,
                    description = "강제 종료할 세션의 UUID")
            @PathVariable("sid") UUID sessionUuid
    ) {
        sessionService.revokeByUuid(userUuid, sessionUuid);
        return ResponseEntity.noContent().build();
    }
}
