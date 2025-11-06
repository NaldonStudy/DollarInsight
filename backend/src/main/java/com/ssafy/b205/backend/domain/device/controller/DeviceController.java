package com.ssafy.b205.backend.domain.device.controller;

import com.ssafy.b205.backend.domain.device.entity.UserDevice;
import com.ssafy.b205.backend.domain.device.service.DeviceService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.ArraySchema;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "Device")
@RestController
@RequestMapping("/api/devices")
@RequiredArgsConstructor
@SecurityRequirement(name = "bearerAuth") // 보호 API → bearerAuth만 명시
public class DeviceController {

    private final DeviceService deviceService;

    @Operation(
            summary = "내 기기 목록",
            description = "현재 로그인한 사용자 계정에 등록된 모든 기기를 반환합니다.",
            responses = {
                    @ApiResponse(
                            responseCode = "200",
                            description = "기기 목록",
                            content = @Content(
                                    mediaType = "application/json",
                                    array = @ArraySchema(schema = @Schema(implementation = UserDevice.class)),
                                    examples = @ExampleObject(
                                            name = "성공",
                                            value = """
                        [
                          { "id":12, "deviceId":"my phone  01", "platform":"ANDROID", "pushEnabled":true },
                          { "id":13, "deviceId":"office-laptop#a", "platform":"ANDROID", "pushEnabled":false }
                        ]
                        """
                                    )
                            )
                    )
            }
    )
    @GetMapping
    public List<UserDevice> list(@AuthenticationPrincipal String userUuid) {
        return deviceService.list(userUuid);
    }

    @Operation(
            summary = "내(현재 기기) 푸시 토큰/활성 상태 갱신",
            description = """
        헤더 X-Device-Id로 현재 기기를 찾아 pushToken / enabled 상태를 갱신합니다.
        - pushToken: 새 푸시 토큰
        - enabled: 푸시 사용 여부
        """,
            responses = {
                    @ApiResponse(responseCode = "200", description = "OK(본문 없음)"),
                    @ApiResponse(responseCode = "404", description = "현재 기기를 찾을 수 없음")
            }
    )
    @PatchMapping("/me/push")
    public void updatePushMe(
            @AuthenticationPrincipal String userUuid,
            @RequestHeader("X-Device-Id") String deviceId,
            @RequestParam String pushToken,
            @RequestParam boolean enabled
    ) {
        deviceService.updatePushByDeviceId(userUuid, deviceId, pushToken, enabled);
    }

    @Operation(summary = "기기 삭제", description = "특정 기기를 삭제합니다. (경로의 id는 user_device의 PK)")
    @DeleteMapping("/{id}")
    public void delete(@AuthenticationPrincipal String userUuid, @PathVariable Integer id) {
        deviceService.delete(userUuid, id);
    }
}
