package com.ssafy.b205.backend.domain.device.repository;

import com.ssafy.b205.backend.domain.device.entity.PlatformType;
import com.ssafy.b205.backend.domain.device.entity.UserDevice;
import com.ssafy.b205.backend.domain.user.entity.User;
import com.ssafy.b205.backend.domain.user.entity.UserStatus;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
class UserDeviceRepositoryTest {

    @Autowired
    private UserDeviceRepository userDeviceRepository;

    @Autowired
    private TestEntityManager entityManager;

    private User owner;
    private User anotherUser;

    @BeforeEach
    void setUp() {
        owner = persistUser("alice@example.com", "Alice");
        anotherUser = persistUser("bob@example.com", "Bob");
    }

    @Test
    @DisplayName("findByUser는 특정 유저의 디바이스만 반환한다")
    void findByUserReturnsDevicesForOwnerOnly() {
        // given
        persistDevice(owner, "device-owner-1");
        persistDevice(owner, "device-owner-2");
        persistDevice(anotherUser, "device-other-1");

        // when
        List<UserDevice> devices = userDeviceRepository.findByUser(owner);

        // then
        assertThat(devices)
                .hasSize(2)
                .extracting(UserDevice::getDeviceId)
                .containsExactlyInAnyOrder("device-owner-1", "device-owner-2");
    }

    @Test
    @DisplayName("findByUserAndDeviceId는 일치하는 디바이스를 Optional로 반환한다")
    void findByUserAndDeviceIdReturnsMatch() {
        // given
        UserDevice expected = persistDevice(owner, "device-owner-1");

        // when
        Optional<UserDevice> result = userDeviceRepository.findByUserAndDeviceId(owner, "device-owner-1");

        // then
        assertThat(result).isPresent();
        assertThat(result.map(UserDevice::getId)).contains(expected.getId());
    }

    @Test
    @DisplayName("findByUserAndDeviceId는 존재하지 않으면 Optional.empty를 반환한다")
    void findByUserAndDeviceIdReturnsEmptyWhenMissing() {
        // given
        persistDevice(owner, "device-owner-1");

        // when
        Optional<UserDevice> result = userDeviceRepository.findByUserAndDeviceId(owner, "missing-device");

        // then
        assertThat(result).isEmpty();
    }

    private User persistUser(String email, String nickname) {
        User user = User.builder()
                .uuid(UUID.randomUUID())
                .email(email)
                .nickname(nickname)
                .status(UserStatus.ACTIVE)
                .build();
        return entityManager.persistAndFlush(user);
    }

    private UserDevice persistDevice(User user, String deviceId) {
        UserDevice device = UserDevice.builder()
                .user(user)
                .deviceId(deviceId)
                .platform(PlatformType.ANDROID)
                .pushToken("push-token-" + deviceId)
                .pushEnabled(true)
                .build();
        return entityManager.persistAndFlush(device);
    }
}
