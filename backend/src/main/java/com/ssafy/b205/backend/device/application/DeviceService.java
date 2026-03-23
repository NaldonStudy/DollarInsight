package com.ssafy.b205.backend.device.application;

import com.ssafy.b205.backend.device.domain.entity.UserDevice;

import java.util.List;

public interface DeviceService {
    List<UserDevice> list(String userUuid);
    void updatePushByDeviceId(String userUuid, String deviceId, String pushToken, boolean enabled); // /me 용
    void deleteByDeviceId(String userUuid, String deviceId);
}
