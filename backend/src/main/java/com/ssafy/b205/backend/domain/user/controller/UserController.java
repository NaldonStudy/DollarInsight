package com.ssafy.b205.backend.domain.user.controller;

import com.ssafy.b205.backend.domain.user.dto.request.NicknameUpdateRequest;
import com.ssafy.b205.backend.domain.user.dto.request.PasswordChangeRequest;
import com.ssafy.b205.backend.domain.user.dto.response.UserResponse;
import com.ssafy.b205.backend.domain.user.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@Tag(name = "Users")
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
@SecurityRequirement(name = "bearerAuth") // 보호 API 전부 적용
public class UserController {

    private final UserService userService;

    @Operation(
            summary = "내 프로필 조회",
            description = """
        보호 API. 상단 Authorize에서 한 번만 설정하면 됩니다.
        - Authorization: Bearer {accessToken}
        - X-Device-Id: 디바이스 식별자(임의 문자열, 서버에서 trim+소문자+최대128자로 정규화)
        """,
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

    @Operation(
            summary = "닉네임 변경",
            description = "- 요구 헤더: X-Device-Id, Authorization: Bearer <AT>\n- 닉네임은 2~20자",
            responses = {
                    @ApiResponse(responseCode = "200", description = "OK")
            }
    )
    @PatchMapping("/me/nickname")
    public void changeNickname(@AuthenticationPrincipal String userUuid,
                               @RequestBody @Valid NicknameUpdateRequest req) {
        userService.changeNickname(userUuid, req.getNickname());
    }

    @Operation(
            summary = "비밀번호 변경",
            description = "- 요구 헤더: X-Device-Id, Authorization: Bearer <AT>\n- oldPassword 검증 후 newPassword로 변경",
            responses = {
                    @ApiResponse(responseCode = "200", description = "OK")
            }
    )
    @PatchMapping("/me/password")
    public void changePassword(@AuthenticationPrincipal String userUuid,
                               @RequestBody @Valid PasswordChangeRequest req) {
        userService.changePassword(userUuid, req.getOldPassword(), req.getNewPassword());
    }

    @Operation(
            summary = "계정 탈퇴(soft delete)",
            description = "- 요구 헤더: X-Device-Id, Authorization: Bearer <AT>\n- 상태를 WITHDRAWN으로 전환",
            responses = {
                    @ApiResponse(responseCode = "200", description = "OK")
            }
    )
    @DeleteMapping("/me")
    public void deleteMe(@AuthenticationPrincipal String userUuid) {
        userService.softDelete(userUuid);
    }
}
