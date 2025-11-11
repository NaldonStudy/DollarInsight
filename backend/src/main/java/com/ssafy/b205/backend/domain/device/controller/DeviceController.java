package com.ssafy.b205.backend.domain.device.controller;

import com.ssafy.b205.backend.domain.device.entity.UserDevice;
import com.ssafy.b205.backend.domain.device.service.DeviceService;
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

@Tag(name = "Device", description = "사용자 디바이스 목록/푸시 설정/삭제 API")
@RestController
@RequestMapping("/api/devices")
@RequiredArgsConstructor
@SecurityRequirement(name = "bearerAuth")
public class DeviceController {

    private final DeviceService deviceService;

    @Operation(
            summary = "내 기기 목록",
            description = "현재 로그인한 사용자 계정에 등록된 모든 기기를 반환합니다.",
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(
                            responseCode = "200", description = "OK",
                            content = @Content(mediaType = "application/json",
                                    array = @ArraySchema(schema = @Schema(implementation = UserDevice.class)),
                                    examples = @ExampleObject(value = """
                                        [
                                          { "id":12, "deviceId":"my-phone-01", "platform":"ANDROID", "pushEnabled":true },
                                          { "id":13, "deviceId":"office-laptop#a", "platform":"ANDROID", "pushEnabled":false }
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
    public ApiResponse<List<UserDevice>> list(@AuthenticationPrincipal String userUuid) {
        return ApiResponse.ok(deviceService.list(userUuid));
    }

    @Operation(
            summary = "내(현재 기기) 푸시 토큰/활성 상태 갱신",
            description = "헤더 X-Device-Id로 현재 기기를 찾아 pushToken / enabled 상태를 갱신합니다.",
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "204", description = "No Content"),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", ref = DocRefs.BAD_REQUEST),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", ref = DocRefs.UNAUTHORIZED),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", ref = DocRefs.NOT_FOUND),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
            }
    )
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true,
            description = "현재 기기의 DID", example = "11111111-1111-1111-1111-111111111111")
    @Parameter(name = "pushToken", in = ParameterIn.QUERY, required = true,
            description = "FCM/APNS 토큰", example = "fcm_XXX")
    @Parameter(name = "enabled", in = ParameterIn.QUERY, required = true,
            description = "푸시 활성화 여부", example = "true")
    @PatchMapping("/me/push")
    public ResponseEntity<Void> updatePushMe(
            @AuthenticationPrincipal String userUuid,
            @RequestHeader("X-Device-Id") String deviceId,
            @RequestParam String pushToken,
            @RequestParam boolean enabled
    ) {
        deviceService.updatePushByDeviceId(userUuid, deviceId, pushToken, enabled);
        return ResponseEntity.noContent().build();
    }

    @Operation(
            summary = "기기 삭제(deviceId)",
            description = "deviceId(UUID)로 내 기기를 삭제합니다.",
            responses = {
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "204", description = "삭제 성공"),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", ref = DocRefs.UNAUTHORIZED),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", ref = DocRefs.NOT_FOUND),
                    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", ref = DocRefs.INTERNAL)
            }
    )
    @Parameter(name = "X-Device-Id", in = ParameterIn.HEADER, required = true,
            description = "디바이스 식별자", example = "11111111-1111-1111-1111-111111111111")
    @DeleteMapping("/by-device/{deviceId}")
    public ResponseEntity<Void> deleteByDeviceId(
            @AuthenticationPrincipal String userUuid,
            @PathVariable String deviceId
    ) {
        deviceService.deleteByDeviceId(userUuid, deviceId);
        return ResponseEntity.noContent().build();
    }
}
