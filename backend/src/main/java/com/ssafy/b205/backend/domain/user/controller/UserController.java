package com.ssafy.b205.backend.domain.user.controller;

import com.ssafy.b205.backend.domain.user.dto.request.NicknameUpdateRequest;
import com.ssafy.b205.backend.domain.user.dto.request.PasswordChangeRequest;
import com.ssafy.b205.backend.domain.user.dto.response.UserResponse;
import com.ssafy.b205.backend.domain.user.service.UserService;
import com.ssafy.b205.backend.support.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@Tag(name = "Users")
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
@SecurityRequirement(name = "bearerAuth")
public class UserController {

    private final UserService userService;

    @Operation(
            summary = "내 프로필 조회",
            description = "- 보호 API: Authorization + X-Device-Id 필요",
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(
                            responseCode = "200", description = "OK",
                            content = @Content(mediaType = "application/json",
                                    schema = @Schema(implementation = UserResponse.class),
                                    examples = @ExampleObject(value = """
                                        {
                                          "uuid": "7e26b6df-bcb8-48ff-85af-b7b5ae9c46cd",
                                          "email": "minji@example.com",
                                          "nickname": "Minji",
                                          "status": "ACTIVE",
                                          "createdAt": "2025-11-01T08:21:34.123Z"
                                        }
                                    """)))
            }
    )
    @GetMapping("/me")
    public ApiResponse<UserResponse> me(@AuthenticationPrincipal String userUuid) {
        return ApiResponse.ok(new UserResponse(userService.getByUuid(userUuid)));
    }

    @Operation(summary = "닉네임 변경", description = "닉네임은 2~20자",
            responses = { @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "204", description = "No Content") })
    @PatchMapping("/me/nickname")
    public ResponseEntity<Void> changeNickname(@AuthenticationPrincipal String userUuid,
                                               @RequestBody @Valid NicknameUpdateRequest req) {
        userService.changeNickname(userUuid, req.getNickname());
        return ResponseEntity.noContent().build();
    }

    @Operation(summary = "비밀번호 변경", description = "oldPassword 검증 후 newPassword로 변경",
            responses = { @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "204", description = "No Content") })
    @PatchMapping("/me/password")
    public ResponseEntity<Void> changePassword(@AuthenticationPrincipal String userUuid,
                                               @RequestBody @Valid PasswordChangeRequest req) {
        userService.changePassword(userUuid, req.getOldPassword(), req.getNewPassword());
        return ResponseEntity.noContent().build();
    }

    @Operation(summary = "계정 탈퇴(soft delete)",
            responses = { @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "204", description = "No Content") })
    @DeleteMapping("/me")
    public ResponseEntity<Void> deleteMe(@AuthenticationPrincipal String userUuid) {
        userService.softDelete(userUuid);
        return ResponseEntity.noContent().build();
    }
}
