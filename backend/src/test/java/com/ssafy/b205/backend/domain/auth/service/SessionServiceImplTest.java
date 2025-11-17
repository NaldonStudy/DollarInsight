package com.ssafy.b205.backend.domain.auth.service;

import com.ssafy.b205.backend.domain.device.entity.PlatformType;
import com.ssafy.b205.backend.domain.device.entity.UserDevice;
import com.ssafy.b205.backend.domain.device.repository.UserDeviceRepository;
import com.ssafy.b205.backend.domain.session.entity.UserSession;
import com.ssafy.b205.backend.domain.session.repository.UserSessionRepository;
import com.ssafy.b205.backend.domain.user.entity.User;
import com.ssafy.b205.backend.domain.user.entity.UserStatus;
import com.ssafy.b205.backend.domain.user.repository.UserRepository;
import com.ssafy.b205.backend.infra.security.RefreshTokenUtil;
import com.ssafy.b205.backend.infra.security.TokenProvider;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jws;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class SessionServiceImplTest {

    @Mock
    private TokenProvider tokenProvider;
    @Mock
    private UserRepository userRepository;
    @Mock
    private UserDeviceRepository userDeviceRepository;
    @Mock
    private UserSessionRepository userSessionRepository;

    private SessionServiceImpl sessionService;

    @BeforeEach
    void setUp() {
        sessionService = new SessionServiceImpl(tokenProvider, userRepository, userDeviceRepository, userSessionRepository);
        ReflectionTestUtils.setField(sessionService, "refreshTtlDays", 7);
        ReflectionTestUtils.setField(sessionService, "refreshPepper", "pep");
    }

    @Test
    void issueRefreshAndStoreCreatesDeviceWhenMissing() {
        UUID userUuid = UUID.randomUUID();
        User user = createUser(userUuid);
        when(userRepository.findByUuidAndDeletedAtIsNull(userUuid)).thenReturn(Optional.of(user));
        when(tokenProvider.createRefreshToken(userUuid.toString(), "device-1", 7)).thenReturn("refresh-token");
        when(userDeviceRepository.findByUserAndDeviceId(user, "device-1")).thenReturn(Optional.empty());
        when(userDeviceRepository.save(any(UserDevice.class))).thenAnswer(invocation -> invocation.getArgument(0));

        String refresh = sessionService.issueRefreshAndStore(userUuid.toString(), "  device-1  ", true, "push-token");

        assertThat(refresh).isEqualTo("refresh-token");

        ArgumentCaptor<UserDevice> deviceCaptor = ArgumentCaptor.forClass(UserDevice.class);
        verify(userDeviceRepository).save(deviceCaptor.capture());
        UserDevice savedDevice = deviceCaptor.getValue();
        assertThat(savedDevice.getUser()).isEqualTo(user);
        assertThat(savedDevice.getDeviceId()).isEqualTo("device-1");
        assertThat(savedDevice.getPlatform()).isEqualTo(PlatformType.ANDROID);
        assertThat(savedDevice.isPushEnabled()).isTrue();
        assertThat(savedDevice.getPushToken()).isEqualTo("push-token");

        ArgumentCaptor<UserSession> sessionCaptor = ArgumentCaptor.forClass(UserSession.class);
        verify(userSessionRepository).save(sessionCaptor.capture());
        UserSession savedSession = sessionCaptor.getValue();
        assertThat(savedSession.getUser()).isEqualTo(user);
        assertThat(savedSession.getUserDevice()).isEqualTo(savedDevice);
        assertThat(savedSession.getRefreshTokenHash())
                .isEqualTo(RefreshTokenUtil.sha256Base64("refresh-token", "pep"));
        assertThat(savedSession.getExpiresAt()).isNotNull();
        assertThat(savedSession.getExpiresAt()).isAfter(LocalDateTime.now());
    }

    @Test
    void issueRefreshAndStoreUpdatesExistingDeviceWhenPushInfoChanges() {
        UUID userUuid = UUID.randomUUID();
        User user = createUser(userUuid);
        UserDevice device = UserDevice.builder()
                .user(user)
                .deviceId("device-1")
                .platform(PlatformType.ANDROID)
                .pushEnabled(false)
                .pushToken("old-token")
                .build();
        when(userRepository.findByUuidAndDeletedAtIsNull(userUuid)).thenReturn(Optional.of(user));
        when(tokenProvider.createRefreshToken(anyString(), anyString(), anyInt())).thenReturn("refresh-token");
        when(userDeviceRepository.findByUserAndDeviceId(user, "device-1")).thenReturn(Optional.of(device));
        when(userDeviceRepository.save(any(UserDevice.class))).thenAnswer(invocation -> invocation.getArgument(0));

        sessionService.issueRefreshAndStore(userUuid.toString(), "device-1", true, "new-token");

        assertThat(device.isPushEnabled()).isTrue();
        assertThat(device.getPushToken()).isEqualTo("new-token");
        verify(userDeviceRepository).save(device);
        verify(userSessionRepository).save(any(UserSession.class));
    }

    @Test
    void logoutByDeviceWithRefreshTokenRevokesMatchingSession() {
        UUID userUuid = UUID.randomUUID();
        User user = createUser(userUuid);
        when(userRepository.findByUuidAndDeletedAtIsNull(userUuid)).thenReturn(Optional.of(user));
        UserDevice device = UserDevice.builder()
                .user(user)
                .deviceId("device-1")
                .platform(PlatformType.ANDROID)
                .pushEnabled(true)
                .build();
        UserSession session = UserSession.builder()
                .user(user)
                .userDevice(device)
                .refreshTokenHash("hash")
                .expiresAt(LocalDateTime.now().plusDays(1))
                .build();
        when(userSessionRepository.findByRefreshTokenHash(anyString())).thenReturn(Optional.of(session));

        sessionService.logoutByDevice(userUuid.toString(), "device-1", "refresh-token");

        assertThat(session.getRevokedAt()).isNotNull();
        verify(userSessionRepository, never()).findByUserAndUserDevice(any(), any());
    }

    @Test
    void logoutByDeviceWithoutTokenRevokesAllSessionsForDevice() {
        UUID userUuid = UUID.randomUUID();
        User user = createUser(userUuid);
        when(userRepository.findByUuidAndDeletedAtIsNull(userUuid)).thenReturn(Optional.of(user));
        UserDevice device = UserDevice.builder()
                .user(user)
                .deviceId("device-1")
                .platform(PlatformType.ANDROID)
                .pushEnabled(true)
                .build();
        when(userDeviceRepository.findByUserAndDeviceId(user, "device-1")).thenReturn(Optional.of(device));
        UserSession active = UserSession.builder()
                .user(user)
                .userDevice(device)
                .refreshTokenHash("h1")
                .expiresAt(LocalDateTime.now().plusDays(1))
                .build();
        UserSession revoked = UserSession.builder()
                .user(user)
                .userDevice(device)
                .refreshTokenHash("h2")
                .expiresAt(LocalDateTime.now().minusDays(1))
                .revokedAt(LocalDateTime.now().minusDays(1))
                .build();
        when(userSessionRepository.findByUserAndUserDevice(user, device)).thenReturn(List.of(active, revoked));

        sessionService.logoutByDevice(userUuid.toString(), "device-1", null);

        assertThat(active.getRevokedAt()).isNotNull();
        assertThat(revoked.getRevokedAt()).isNotNull();
    }

    @Test
    void reissueAccessByRefreshReturnsAccessTokenWhenValid() {
        UUID userUuid = UUID.randomUUID();
        Claims claims = mock(Claims.class);
        when(claims.getSubject()).thenReturn(userUuid.toString());
        when(claims.get("did")).thenReturn("device-1");
        when(claims.get("typ")).thenReturn("refresh");
        @SuppressWarnings("unchecked")
        Jws<Claims> jws = mock(Jws.class);
        when(jws.getPayload()).thenReturn(claims);
        when(tokenProvider.parse("refresh-token")).thenReturn(jws);
        String hash = RefreshTokenUtil.sha256Base64("refresh-token", "pep");
        UserSession session = UserSession.builder()
                .refreshTokenHash(hash)
                .expiresAt(LocalDateTime.now().plusDays(1))
                .build();
        when(userSessionRepository.findByRefreshTokenHash(hash)).thenReturn(Optional.of(session));
        when(tokenProvider.createAccessToken(userUuid.toString(), "device-1")).thenReturn("new-access");

        String access = sessionService.reissueAccessByRefresh("refresh-token", "device-1");

        assertThat(access).isEqualTo("new-access");
    }

    @Test
    void reissueAccessByRefreshFailsWhenParseFails() {
        when(tokenProvider.parse("rt")).thenThrow(new IllegalArgumentException("bad token"));

        assertThatThrownBy(() -> sessionService.reissueAccessByRefresh("rt", "device-1"))
                .isInstanceOf(IllegalArgumentException.class);
    }

    private User createUser(UUID uuid) {
        return User.builder()
                .id(1)
                .uuid(uuid)
                .email("user@example.com")
                .nickname("User")
                .status(UserStatus.ACTIVE)
                .build();
    }
}
