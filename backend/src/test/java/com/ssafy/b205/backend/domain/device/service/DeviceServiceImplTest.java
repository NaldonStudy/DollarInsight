package com.ssafy.b205.backend.domain.device.service;

import com.ssafy.b205.backend.domain.device.entity.PlatformType;
import com.ssafy.b205.backend.domain.device.entity.UserDevice;
import com.ssafy.b205.backend.domain.device.repository.UserDeviceRepository;
import com.ssafy.b205.backend.domain.user.entity.User;
import com.ssafy.b205.backend.domain.user.entity.UserStatus;
import com.ssafy.b205.backend.domain.user.repository.UserRepository;
import com.ssafy.b205.backend.support.error.AppException;
import com.ssafy.b205.backend.support.error.ErrorCode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class DeviceServiceImplTest {

    @Mock
    private UserRepository userRepository;
    @Mock
    private UserDeviceRepository userDeviceRepository;

    private DeviceServiceImpl deviceService;

    @BeforeEach
    void setUp() {
        deviceService = new DeviceServiceImpl(userRepository, userDeviceRepository);
    }

    @Test
    void listReturnsDevicesForActiveUser() {
        User user = createUser();
        List<UserDevice> devices = List.of(UserDevice.builder()
                .user(user)
                .deviceId("device-1")
                .platform(PlatformType.ANDROID)
                .pushEnabled(true)
                .build());
        when(userRepository.findByUuidAndDeletedAtIsNull(user.getUuid())).thenReturn(Optional.of(user));
        when(userDeviceRepository.findByUser(user)).thenReturn(devices);

        List<UserDevice> result = deviceService.list(user.getUuid().toString());

        assertThat(result).isEqualTo(devices);
    }

    @Test
    void listThrowsWhenUserMissing() {
        UUID uuid = UUID.randomUUID();
        when(userRepository.findByUuidAndDeletedAtIsNull(uuid)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> deviceService.list(uuid.toString()))
                .isInstanceOf(AppException.class)
                .hasFieldOrPropertyWithValue("code", ErrorCode.NOT_FOUND);
    }

    @Test
    void updatePushByDeviceIdUpdatesDeviceState() {
        User user = createUser();
        UserDevice device = UserDevice.builder()
                .user(user)
                .deviceId("device-1")
                .platform(PlatformType.ANDROID)
                .pushEnabled(false)
                .build();
        when(userRepository.findByUuidAndDeletedAtIsNull(user.getUuid())).thenReturn(Optional.of(user));
        when(userDeviceRepository.findByUserAndDeviceId(user, "device-1")).thenReturn(Optional.of(device));

        deviceService.updatePushByDeviceId(user.getUuid().toString(), "  device-1  ", "new-token", true);

        assertThat(device.getPushToken()).isEqualTo("new-token");
        assertThat(device.isPushEnabled()).isTrue();
        verify(userDeviceRepository, times(1)).findByUserAndDeviceId(user, "device-1");
    }

    @Test
    void updatePushThrowsWhenDeviceMissing() {
        User user = createUser();
        when(userRepository.findByUuidAndDeletedAtIsNull(user.getUuid())).thenReturn(Optional.of(user));
        when(userDeviceRepository.findByUserAndDeviceId(any(), any())).thenReturn(Optional.empty());

        assertThatThrownBy(() -> deviceService.updatePushByDeviceId(user.getUuid().toString(), "device-1", "token", true))
                .isInstanceOf(AppException.class)
                .hasFieldOrPropertyWithValue("code", ErrorCode.NOT_FOUND);
    }

    @Test
    void deleteByDeviceIdRemovesDeviceWhenExists() {
        User user = createUser();
        UserDevice device = UserDevice.builder()
                .user(user)
                .deviceId("device-1")
                .platform(PlatformType.ANDROID)
                .pushEnabled(true)
                .build();
        when(userRepository.findByUuidAndDeletedAtIsNull(user.getUuid())).thenReturn(Optional.of(user));
        when(userDeviceRepository.findByUserAndDeviceId(user, "device-1")).thenReturn(Optional.of(device));

        deviceService.deleteByDeviceId(user.getUuid().toString(), "device-1");

        verify(userDeviceRepository).delete(device);
    }

    @Test
    void deleteByDeviceIdThrowsWhenMissing() {
        User user = createUser();
        when(userRepository.findByUuidAndDeletedAtIsNull(user.getUuid())).thenReturn(Optional.of(user));
        when(userDeviceRepository.findByUserAndDeviceId(any(), any())).thenReturn(Optional.empty());

        assertThatThrownBy(() -> deviceService.deleteByDeviceId(user.getUuid().toString(), "device-1"))
                .isInstanceOf(AppException.class)
                .hasFieldOrPropertyWithValue("code", ErrorCode.NOT_FOUND);
    }

    private User createUser() {
        return User.builder()
                .id(1)
                .uuid(UUID.randomUUID())
                .email("user@example.com")
                .nickname("User")
                .status(UserStatus.ACTIVE)
                .build();
    }
}
