package com.ssafy.b205.backend.domain.user.controller;

import com.ssafy.b205.backend.domain.user.dto.request.LoginRequest;
import com.ssafy.b205.backend.domain.user.dto.request.SignupRequest;
import com.ssafy.b205.backend.domain.user.dto.response.TokenPairResponse;
import com.ssafy.b205.backend.domain.auth.service.AuthApplicationService;
import com.ssafy.b205.backend.infra.docs.DocRefs;
import com.ssafy.b205.backend.support.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.enums.ParameterIn;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@Tag(name = "Auth", description = "회원가입/로그인 및 토큰 페어 발급 API")
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthApplicationService authAppService;

    @Operation(
            summary = "회원가입 (access+refresh 즉시 발급, 기기 자동 등록)",
            description = """
            - 요청 본문: email, nickname, password, pushEnabled(선택; 기본=false)
            - 필수 헤더: `X-Device-Id` — 임의 문자열(서버에서 trim+lowercase+최대128자로 정규화)
            - 성공 시: 해당 DID로 기기를 자동 등록/갱신하고 토큰 페어 발급
            """)
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "200", description = "가입 성공",
                    content = @Content(mediaType = "application/json",
                            schema = @Schema(implementation = TokenPairResponse.class),
                            examples = @ExampleObject(name = "success", value = """
                            { "accessToken": "eyJhbGciOi...", "refreshToken": "eyJhbGciOi..." }
                            """))),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", ref = DocRefs.BAD_REQUEST),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "409", ref = DocRefs.CONFLICT),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
    })
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true,
            description = "디바이스 식별자(임의 문자열; 서버가 정규화)", example = "my-phone-01")
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
            - 요청 본문: email, password
            - 필수 헤더: `X-Device-Id` — 임의 문자열(서버 정규화)
            - 성공 시: 해당 DID로 기기를 자동 등록/갱신하고 토큰 페어 발급
            """)
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "200", description = "로그인 성공",
                    content = @Content(mediaType = "application/json",
                            schema = @Schema(implementation = TokenPairResponse.class),
                            examples = @ExampleObject(name = "success", value = """
                            { "accessToken": "eyJhbGciOi...", "refreshToken": "eyJhbGciOi..." }
                            """))),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", ref = DocRefs.BAD_REQUEST),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", ref = DocRefs.UNAUTHORIZED),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
    })
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true,
            description = "디바이스 식별자(임의 문자열; 서버가 정규화)", example = "office-laptop#a")
    @PostMapping("/login")
    public ApiResponse<TokenPairResponse> login(
            @Valid @RequestBody LoginRequest req,
            @RequestHeader("X-Device-Id") String deviceId
    ) {
        return ApiResponse.ok(authAppService.loginAndIssue(req, deviceId));
    }
}
