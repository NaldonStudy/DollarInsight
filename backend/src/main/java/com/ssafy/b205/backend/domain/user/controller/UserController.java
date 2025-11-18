package com.ssafy.b205.backend.domain.user.controller;

import com.ssafy.b205.backend.domain.persona.dto.PersonaResponse;
import com.ssafy.b205.backend.domain.persona.service.PersonaQueryService;
import com.ssafy.b205.backend.domain.user.dto.request.NicknameUpdateRequest;
import com.ssafy.b205.backend.domain.user.dto.request.PasswordChangeRequest;
import com.ssafy.b205.backend.domain.user.dto.request.UserPersonaUpdateRequest;
import com.ssafy.b205.backend.domain.user.dto.response.UserResponse;
import com.ssafy.b205.backend.domain.user.service.UserService;
import com.ssafy.b205.backend.infra.docs.DocRefs;
import com.ssafy.b205.backend.support.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.enums.ParameterIn;
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

@Tag(name = "Users", description = "사용자 프로필 조회/수정 및 계정 탈퇴 API")
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
@SecurityRequirement(name = "bearerAuth")
public class UserController {

    private final UserService userService;
    private final PersonaQueryService personaQueryService;

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
                                    """)
                            )
                    ),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", ref = DocRefs.UNAUTHORIZED),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
            }
    )
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true,
            description = "디바이스 식별자", example = "11111111-1111-1111-1111-111111111111")
    @GetMapping("/me")
    public ApiResponse<UserResponse> me(@AuthenticationPrincipal String userUuid) {
        return ApiResponse.ok(new UserResponse(userService.getByUuid(userUuid)));
    }

    @Operation(
            summary = "닉네임 변경",
            description = "닉네임은 2~20자",
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "204", description = "No Content"),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", ref = DocRefs.BAD_REQUEST),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", ref = DocRefs.UNAUTHORIZED),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "409", ref = DocRefs.CONFLICT),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
            }
    )
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true,
            description = "디바이스 식별자", example = "11111111-1111-1111-1111-111111111111")
    @io.swagger.v3.oas.annotations.parameters.RequestBody(
            required = true,
            content = @Content(
                    mediaType = "application/json",
                    schema = @Schema(implementation = NicknameUpdateRequest.class),
                    examples = @ExampleObject(value = """
                        { "nickname": "NewNick_2025" }
                    """)
            )
    )
    @PatchMapping("/me/nickname")
    public ResponseEntity<Void> changeNickname(@AuthenticationPrincipal String userUuid,
                                               @RequestBody @Valid NicknameUpdateRequest req) {
        userService.changeNickname(userUuid, req.getNickname());
        return ResponseEntity.noContent().build();
    }

    @Operation(
            summary = "비밀번호 변경",
            description = "oldPassword 검증 후 newPassword로 변경",
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "204", description = "No Content"),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", ref = DocRefs.BAD_REQUEST),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", ref = DocRefs.UNAUTHORIZED),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
            }
    )
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true,
            description = "디바이스 식별자", example = "11111111-1111-1111-1111-111111111111")
    @io.swagger.v3.oas.annotations.parameters.RequestBody(
            required = true,
            content = @Content(
                    mediaType = "application/json",
                    schema = @Schema(implementation = PasswordChangeRequest.class),
                    examples = @ExampleObject(value = """
                        { "oldPassword": "P@ssw0rd!", "newPassword": "N3wP@ssw0rd!" }
                    """)
            )
    )
    @PatchMapping("/me/password")
    public ResponseEntity<Void> changePassword(@AuthenticationPrincipal String userUuid,
                                               @RequestBody @Valid PasswordChangeRequest req) {
        userService.changePassword(userUuid, req.getOldPassword(), req.getNewPassword());
        return ResponseEntity.noContent().build();
    }

    @Operation(
            summary = "내 활성 페르소나 조회",
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(
                            responseCode = "200", description = "OK",
                            content = @Content(
                                    mediaType = "application/json",
                                    schema = @Schema(implementation = PersonaResponse.class),
                                    examples = @ExampleObject(value = """
                                        [
                                          { "id": 1, "code": "Minji" },
                                          { "id": 2, "code": "Taeo" }
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
    @GetMapping("/me/personas")
    public ApiResponse<java.util.List<PersonaResponse>> getMyPersonas(@AuthenticationPrincipal String userUuid) {
        final var personas = personaQueryService.findEnabledForUser(userUuid).stream()
                .map(PersonaResponse::from)
                .toList();
        return ApiResponse.ok(personas);
    }

    @Operation(
            summary = "활성 페르소나 변경",
            description = "사용자가 사용할 페르소나 코드 목록을 갱신합니다.",
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "204", description = "No Content"),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", ref = DocRefs.BAD_REQUEST),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", ref = DocRefs.UNAUTHORIZED),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
            }
    )
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true,
            description = "디바이스 식별자", example = "11111111-1111-1111-1111-111111111111")
    @io.swagger.v3.oas.annotations.parameters.RequestBody(
            required = true,
            content = @Content(
                    mediaType = "application/json",
                    schema = @Schema(implementation = UserPersonaUpdateRequest.class),
                    examples = @ExampleObject(value = """
                        { "personaCodes": ["Minji", "Taeo", "Ducksu"] }
                    """)
            )
    )
    @PatchMapping("/me/personas")
    public ResponseEntity<Void> changePersonas(@AuthenticationPrincipal String userUuid,
                                               @Valid @RequestBody UserPersonaUpdateRequest req) {
        userService.changePersonas(userUuid, req.getPersonaCodes());
        return ResponseEntity.noContent().build();
    }

    @Operation(
            summary = "계정 탈퇴(soft delete)",
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "204", description = "No Content"),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", ref = DocRefs.UNAUTHORIZED),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
            }
    )
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true,
            description = "디바이스 식별자", example = "11111111-1111-1111-1111-111111111111")
    @DeleteMapping("/me")
    public ResponseEntity<Void> deleteMe(@AuthenticationPrincipal String userUuid) {
        userService.softDelete(userUuid);
        return ResponseEntity.noContent().build();
    }
}
