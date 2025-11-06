package com.ssafy.b205.backend.domain.device.service;

import com.ssafy.b205.backend.domain.device.entity.UserDevice;
import com.ssafy.b205.backend.domain.device.repository.UserDeviceRepository;
import com.ssafy.b205.backend.domain.user.entity.User;
import com.ssafy.b205.backend.domain.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class DeviceServiceImpl implements DeviceService {

    private final UserRepository userRepository;
    private final UserDeviceRepository userDeviceRepository;

    private User getUser(String userUuid) {
        return userRepository.findByUuid(UUID.fromString(userUuid))
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
    }

    @Override
    @Transactional(readOnly = true)
    public List<UserDevice> list(String userUuid) {
        return userDeviceRepository.findByUser(getUser(userUuid));
    }

    @Override
    @Transactional
    public void updatePushByDeviceId(String userUuid, String deviceId, String pushToken, boolean enabled) {
        var user = getUser(userUuid);
        var dev = userDeviceRepository.findByUserAndDeviceId(user, deviceId)
                .orElseThrow(() -> new IllegalArgumentException("현재 기기를 찾을 수 없습니다."));
        dev.updatePush(pushToken, enabled).activateNow();
        // JPA dirty checking으로 자동 flush
    }

    @Override
    @Transactional
    public void delete(String userUuid, Integer id) {
        var user = getUser(userUuid);
        var dev = userDeviceRepository.findById(id).orElseThrow();
        if (!dev.getUser().getId().equals(user.getId())) {
            throw new IllegalArgumentException("권한 없음");
        }
        userDeviceRepository.delete(dev);
    }
}
