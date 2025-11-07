package com.ssafy.b205.backend.domain.user.controller;

import com.ssafy.b205.backend.domain.user.dto.request.LoginRequest;
import com.ssafy.b205.backend.domain.user.dto.request.SignupRequest;
import com.ssafy.b205.backend.domain.user.dto.response.TokenPairResponse;
import com.ssafy.b205.backend.domain.auth.service.AuthApplicationService;
import com.ssafy.b205.backend.support.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@Tag(name = "Auth")
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthApplicationService authAppService;

    @Operation(
            summary = "회원가입 (access+refresh 즉시 발급, 기기 자동 등록)",
            description = """
            - Body: email, nickname, password, pushEnabled(선택, 기본 false)
            - X-Device-Id: 디바이스 식별자(임의 문자열, 서버가 trim+소문자+최대128자로 정규화)
            회원가입/로그인 성공 시 해당 DID로 기기를 자동 등록/갱신합니다.
            """,
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(
                            responseCode = "200", description = "OK",
                            content = @Content(mediaType = "application/json",
                                    schema = @Schema(implementation = TokenPairResponse.class),
                                    examples = @ExampleObject(value = """
                                        { "accessToken": "eyJhbGciOi...", "refreshToken": "eyJhbGciOi..." }
                                    """)))
            }
    )
    @PostMapping("/signup")
    public ApiResponse<TokenPairResponse> signup(
            @Valid @RequestBody SignupRequest req,
            @RequestHeader("X-Device-Id") String deviceId
    ) {
        return ApiResponse.ok(authAppService.signupAndIssue(req, deviceId));
    }

    @Operation(
            summary = "로그인 (access+refresh 발급, 기기 자동 등록)",
            description = """
            - Body: email, password
            - X-Device-Id: 디바이스 식별자(임의 문자열, 서버가 정규화)
            """,
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(
                            responseCode = "200", description = "OK",
                            content = @Content(mediaType = "application/json",
                                    schema = @Schema(implementation = TokenPairResponse.class)))
            }
    )
    @PostMapping("/login")
    public ApiResponse<TokenPairResponse> login(
            @Valid @RequestBody LoginRequest req,
            @RequestHeader("X-Device-Id") String deviceId
    ) {
        return ApiResponse.ok(authAppService.loginAndIssue(req, deviceId));
    }
}
