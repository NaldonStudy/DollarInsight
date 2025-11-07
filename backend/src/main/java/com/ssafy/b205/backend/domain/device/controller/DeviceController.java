package com.ssafy.b205.backend.domain.device.controller;

import com.ssafy.b205.backend.domain.device.entity.UserDevice;
import com.ssafy.b205.backend.domain.device.service.DeviceService;
import com.ssafy.b205.backend.support.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
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

@Tag(name = "Device")
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
                                    """)))
            }
    )
    @GetMapping
    public ApiResponse<List<UserDevice>> list(@AuthenticationPrincipal String userUuid) {
        return ApiResponse.ok(deviceService.list(userUuid));
    }

    @Operation(summary = "내(현재 기기) 푸시 토큰/활성 상태 갱신",
            description = "헤더 X-Device-Id로 현재 기기를 찾아 pushToken / enabled 상태를 갱신합니다.",
            responses = { @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "204", description = "No Content") })
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

    @Operation(summary = "기기 삭제", description = "특정 기기를 삭제합니다. (경로의 id는 user_device의 PK)",
            responses = { @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "204", description = "No Content") })
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@AuthenticationPrincipal String userUuid, @PathVariable Integer id) {
        deviceService.delete(userUuid, id);
        return ResponseEntity.noContent().build();
    }
}
