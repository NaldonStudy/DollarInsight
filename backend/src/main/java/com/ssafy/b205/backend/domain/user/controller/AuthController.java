package com.ssafy.b205.backend.domain.user.controller;

import com.ssafy.b205.backend.domain.user.dto.request.LoginRequest;
import com.ssafy.b205.backend.domain.user.dto.request.SignupRequest;
import com.ssafy.b205.backend.domain.user.dto.response.TokenPairResponse;
import com.ssafy.b205.backend.domain.auth.service.AuthApplicationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.enums.ParameterIn;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@Tag(name = "Auth")
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthApplicationService authAppService;

    @Operation(
            summary = "회원가입 (access+refresh 즉시 발급)",
            description = """
            - Body: email, nickname, password
            - 헤더 `X-Device-Id` 필수(디바이스 바인딩)
            성공 시 accessToken + refreshToken을 반환합니다.
            """,
            parameters = {
                    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true, description = "디바이스 고정 UUID v4")
            },
            responses = {
                    @ApiResponse(responseCode = "200", description = "OK",
                            content = @Content(
                                    mediaType = "application/json",
                                    schema = @Schema(implementation = TokenPairResponse.class),
                                    examples = {
                                            @ExampleObject(
                                                    name = "성공",
                                                    value = """
                                                    {
                                                      "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0eXAiOiJhY2Nlc3MiLCJzdWIiOiI3ZTI2YjZkZi1iY2I4LTQ4ZmYtODVhZi1iN2I1YWU5YzQ2Y2QiLCJkaWQiOiI5NGYxZWY1Yy0yYzM3LTRjNjMtOTU0Yy1mN2E2Yzk2ZGU4N2EiLCJleHAiOjE3OTE2NDAwMDB9.sig",
                                                      "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0eXAiOiJyZWZyZXNoIiwic3ViIjoiN2UyNmI2ZGYtYmNiOC00OGZmLTg1YWYtYjdiNWFlOWM0NjNkIiwiZGlkIjoiOTRmMWVmNWMtMmMzNy00YzYzLTk1NGMtZjdhNmM5NmRlODdhIiwiZXhwIjoxNzkyNzIwMDAwfQ.sig"
                                                    }
                                                    """
                                            )
                                    }
                            )),
                    @ApiResponse(responseCode = "400", description = "검증 실패/중복 이메일",
                            content = @Content(
                                    mediaType = "application/json",
                                    examples = @ExampleObject(
                                            name = "중복 이메일",
                                            value = """
                                            {
                                              "type": "about:blank",
                                              "title": "Bad Request",
                                              "status": 400,
                                              "detail": "이미 사용 중인 이메일입니다.",
                                              "instance": "/api/auth/signup"
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
                                              "instance": "/api/auth/signup"
                                            }
                                            """
                                    )
                            ))
            }
    )
    @PostMapping("/signup")
    public ResponseEntity<TokenPairResponse> signup(
            @Valid @RequestBody SignupRequest req,
            @RequestHeader("X-Device-Id") String deviceId) {
        return ResponseEntity.ok(authAppService.signupAndIssue(req, deviceId));
    }

    @Operation(
            summary = "로그인 (access+refresh 발급)",
            description = """
            - Body: email, password
            - 헤더 `X-Device-Id` 필수(디바이스 바인딩)
            성공 시 accessToken + refreshToken을 반환합니다.
            """,
            parameters = {
                    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true, description = "디바이스 고정 UUID v4")
            },
            responses = {
                    @ApiResponse(responseCode = "200", description = "OK",
                            content = @Content(
                                    mediaType = "application/json",
                                    schema = @Schema(implementation = TokenPairResponse.class),
                                    examples = @ExampleObject(
                                            name = "성공",
                                            value = """
                                            {
                                              "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0eXAiOiJhY2Nlc3MiLCJzdWIiOiI3ZTI2YjZkZi1iY2I4LTQ4ZmYtODVhZi1iN2I1YWU5YzQ2Y2QiLCJkaWQiOiI5NGYxZWY1Yy0yYzM3LTRjNjMtOTU0Yy1mN2E2Yzk2ZGU4N2EiLCJleHAiOjE3OTE2NDAwMDB9.sig",
                                              "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0eXAiOiJyZWZyZXNoIiwic3ViIjoiN2UyNmI2ZGYtYmNiOC00OGZmLTg1YWYtYjdiNWFlOWM0NjNkIiwiZGlkIjoiOTRmMWVmNWMtMmMzNy00YzYzLTk1NGMtZjdhNmM5NmRlODdhIiwiZXhwIjoxNzkyNzIwMDAwfQ.sig"
                                            }
                                            """
                                    )
                            )),
                    @ApiResponse(responseCode = "400", description = "검증 실패/비밀번호 불일치",
                            content = @Content(
                                    mediaType = "application/json",
                                    examples = @ExampleObject(
                                            name = "비밀번호 불일치",
                                            value = """
                                            {
                                              "type": "about:blank",
                                              "title": "Bad Request",
                                              "status": 400,
                                              "detail": "비밀번호가 일치하지 않습니다.",
                                              "instance": "/api/auth/login"
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
                                              "instance": "/api/auth/login"
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
                                              "instance": "/api/auth/login"
                                            }
                                            """
                                    )
                            ))
            }
    )
    @PostMapping("/login")
    public ResponseEntity<TokenPairResponse> login(
            @Valid @RequestBody LoginRequest req,
            @RequestHeader("X-Device-Id") String deviceId) {
        return ResponseEntity.ok(authAppService.loginAndIssue(req, deviceId));
    }
}
