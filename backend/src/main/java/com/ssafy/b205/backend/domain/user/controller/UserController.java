package com.ssafy.b205.backend.domain.user.controller;

import com.ssafy.b205.backend.domain.user.dto.response.UserResponse;
import com.ssafy.b205.backend.domain.user.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
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
        보호 API. 상단 Authorize에서 한 번만 설정하면 됩니다.
        - Authorization: Bearer {accessToken}
        - X-Device-Id: 디바이스 식별자(임의 문자열, 서버에서 trim+소문자+최대128자로 정규화)
        """,
            security = {
                    @SecurityRequirement(name = "bearerAuth"),
                    @SecurityRequirement(name = "deviceId")
            },
            responses = {
                    @ApiResponse(
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
