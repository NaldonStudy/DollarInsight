package com.ssafy.b205.backend.domain.device.service;

import com.ssafy.b205.backend.domain.device.entity.UserDevice;

import java.util.List;

public interface DeviceService {
    List<UserDevice> list(String userUuid);
    void updatePushByDeviceId(String userUuid, String deviceId, String pushToken, boolean enabled); // /me 용
    void deleteByDeviceId(String userUuid, String deviceId);
}
