package com.ssafy.b205.backend.domain.user.controller;

import com.ssafy.b205.backend.domain.auth.service.OAuthLoginService;
import com.ssafy.b205.backend.domain.user.dto.request.GoogleLoginRequest;
import com.ssafy.b205.backend.domain.user.dto.request.KakaoLoginRequest;
import com.ssafy.b205.backend.domain.user.dto.response.TokenPairResponse;
import com.ssafy.b205.backend.support.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.enums.ParameterIn;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

@Tag(name = "Auth", description = "소셜 로그인(OAuth) 교환 API")
@RestController
@RequestMapping("/api/auth/oauth")
@RequiredArgsConstructor
public class OAuthController {

    private final OAuthLoginService oAuthLoginService;

    @Operation(
            summary = "카카오 OAuth 로그인 (인가코드 교환)",
            description = """
                - Body: code(필수), redirectUri(선택: 없으면 서버 기본값 사용)
                - 헤더 `X-Device-Id` 필수 (기기 바인딩)
                - 성공 시 우리 서비스 accessToken, refreshToken 반환
                """,
            requestBody = @io.swagger.v3.oas.annotations.parameters.RequestBody(
                    required = true,
                    content = @Content(
                            schema = @Schema(implementation = KakaoLoginRequest.class),
                            examples = @ExampleObject(value = """
                                    {
                                      "code": "J9abcdEfg...xyz",
                                      "redirectUri": "kakao123456://oauth"
                                    }
                                    """)
                    )
            )
    )
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true,
            description = "디바이스 식별자(UUID v4 등)", example = "f1d2d2f9-...-c8b6e8a3")
    @PostMapping(value = "/kakao", consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
    public ApiResponse<TokenPairResponse> loginWithKakao(
            @Valid @RequestBody KakaoLoginRequest req,
            @RequestHeader("X-Device-Id") String deviceId
    ) {
        return ApiResponse.ok(oAuthLoginService.loginWithKakao(req.getCode(), req.getRedirectUri(), deviceId));
    }

    @Operation(
            summary = "구글 OAuth 로그인(인가코드 교환)",
            description = """
                - Body: code(필수), redirectUri(선택: 미전달 시 서버 기본값 사용 허용 시에만)
                - 헤더 `X-Device-Id` 필수 (기기 바인딩)
                - 성공 시 accessToken/refreshToken 반환
                """,
            requestBody = @io.swagger.v3.oas.annotations.parameters.RequestBody(
                    required = true,
                    content = @Content(
                            schema = @Schema(implementation = GoogleLoginRequest.class),
                            examples = @ExampleObject(value = """
                                    {
                                      "code": "4/0AbCdEfGhIjKlMn...",
                                      "redirectUri": "com.dollarinsight.app:/oauth2redirect/google"
                                    }
                                    """)
                    )
            )
    )
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true,
            description = "클라이언트 기기 UUID v4", example = "f1d2d2f9-...-c8b6e8a3")
    @PostMapping(value = "/google", consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
    public ApiResponse<TokenPairResponse> loginWithGoogle(
            @Valid @RequestBody GoogleLoginRequest req,
            @RequestHeader("X-Device-Id") String deviceId
    ) {
        return ApiResponse.ok(oAuthLoginService.loginWithGoogle(
                req.getCode(),
                req.getRedirectUri(),
                req.getCodeVerifier(),
                deviceId
        ));
    }
}
