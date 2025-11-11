// src/main/java/com/ssafy/b205/backend/domain/device/service/DeviceServiceImpl.java
package com.ssafy.b205.backend.domain.device.service;

import com.ssafy.b205.backend.domain.device.entity.UserDevice;
import com.ssafy.b205.backend.domain.device.repository.UserDeviceRepository;
import com.ssafy.b205.backend.domain.user.entity.User;
import com.ssafy.b205.backend.domain.user.repository.UserRepository;
import com.ssafy.b205.backend.support.error.AppException;
import com.ssafy.b205.backend.support.error.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

import static com.ssafy.b205.backend.infra.security.DeviceIdResolver.normalize;

@Slf4j
@Service
@RequiredArgsConstructor
public class DeviceServiceImpl implements DeviceService {

    private final UserRepository userRepository;
    private final UserDeviceRepository userDeviceRepository;

    private User getActiveUser(String userUuid) {
        return userRepository.findByUuidAndDeletedAtIsNull(UUID.fromString(userUuid))
                .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND, "[DeviceSvc-E01] 사용자 없음: " + userUuid));
    }

    @Override
    @Transactional(readOnly = true)
    public List<UserDevice> list(String userUuid) {
        User user = getActiveUser(userUuid);
        // 정렬 필요 시 레포지토리 메서드로 확장 (예: findByUserOrderByUpdatedAtDesc)
        return userDeviceRepository.findByUser(user);
    }

    @Override
    @Transactional
    public void updatePushByDeviceId(String userUuid, String deviceId, String pushToken, boolean enabled) {
        User user = getActiveUser(userUuid);
        String did = normalize(deviceId);

        UserDevice dev = userDeviceRepository.findByUserAndDeviceId(user, did)
                .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND,
                        "[DeviceSvc-E02] 현재 기기를 찾을 수 없습니다. deviceId=" + did));

        // 도메인 메서드 사용 (setter 금지)
        dev.updatePush(pushToken, enabled).activateNow();
        // Dirty checking으로 flush
        log.info("[DeviceSvc-11] Push 설정 변경 완료 userId={}, deviceId={}, enabled={}, hasToken={}",
                user.getId(), did, enabled, (pushToken != null && !pushToken.isBlank()));
    }

    @Override
    @Transactional
    public void deleteByDeviceId(String userUuid, String deviceId) {
        User user = getActiveUser(userUuid);
        String did = normalize(deviceId);

        UserDevice dev = userDeviceRepository.findByUserAndDeviceId(user, did)
                .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND,
                        "[DeviceSvc-E05] 내 기기 목록에 deviceId가 없습니다."));

        userDeviceRepository.delete(dev);
        log.info("[DeviceSvc-21] 디바이스 삭제 완료 userId={}, deviceId={}", user.getId(), did);
    }
}
