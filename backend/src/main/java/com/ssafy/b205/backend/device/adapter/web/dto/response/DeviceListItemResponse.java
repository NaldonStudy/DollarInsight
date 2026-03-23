package com.ssafy.b205.backend.device.adapter.web.dto.response;

import com.ssafy.b205.backend.device.domain.entity.UserDevice;
import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "등록된 사용자 기기 한 건")
public record DeviceListItemResponse(
        @Schema(description = "기기 PK") Integer id,
        @Schema(description = "클라이언트 device id", example = "my-phone-01") String deviceId,
        @Schema(description = "플랫폼", example = "ANDROID") String platform,
        @Schema(description = "푸시 수신 여부") boolean pushEnabled
) {
    public static DeviceListItemResponse from(UserDevice d) {
        return new DeviceListItemResponse(
                d.getId(),
                d.getDeviceId(),
                d.getPlatform().name(),
                d.isPushEnabled()
        );
    }
}
