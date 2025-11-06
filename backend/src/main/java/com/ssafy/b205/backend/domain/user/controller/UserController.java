package com.ssafy.b205.backend.domain.user.controller;

import com.ssafy.b205.backend.domain.user.dto.response.UserResponse;
import com.ssafy.b205.backend.domain.user.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.enums.ParameterIn;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@Tag(name = "Users")
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @Operation(
            summary = "내 프로필 조회",
            description = """
            보호 API. Authorization(Access Token) + X-Device-Id 헤더가 필요합니다.
            """,
            parameters = {
                    @Parameter(name = "Authorization", in = ParameterIn.HEADER, required = true, description = "Bearer {accessToken}"),
                    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true, description = "디바이스 고정 UUID v4")
            },
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(
                            responseCode = "200",
                            description = "OK",
                            content = @Content(
                                    mediaType = "application/json",
                                    schema = @Schema(implementation = UserResponse.class),
                                    examples = @ExampleObject(
                                            name = "성공",
                                            value = """
                                            {
                                              "uuid": "7e26b6df-bcb8-48ff-85af-b7b5ae9c46cd",
                                              "email": "minji@example.com",
                                              "nickname": "Minji",
                                              "status": "ACTIVE",
                                              "createdAt": "2025-11-01T08:21:34.123Z"
                                            }
                                            """
                                    )
                            )
                    )
            }
    )
    @GetMapping("/me")
    public UserResponse me(@AuthenticationPrincipal String userUuid) {
        return new UserResponse(userService.getByUuid(userUuid));
    }
}
