package com.ssafy.b205.backend.domain.auth.service;

import com.ssafy.b205.backend.domain.device.entity.PlatformType;
import com.ssafy.b205.backend.domain.device.entity.UserDevice;
import com.ssafy.b205.backend.domain.device.repository.UserDeviceRepository;
import com.ssafy.b205.backend.domain.session.entity.UserSession;
import com.ssafy.b205.backend.domain.session.repository.UserSessionRepository;
import com.ssafy.b205.backend.domain.user.entity.User;
import com.ssafy.b205.backend.domain.user.repository.UserRepository;
import com.ssafy.b205.backend.infra.security.RefreshTokenUtil;
import com.ssafy.b205.backend.infra.security.TokenProvider;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jws;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.UUID;

import static com.ssafy.b205.backend.infra.security.DeviceIdResolver.normalize;

@Slf4j
@Service
@RequiredArgsConstructor
public class SessionServiceImpl implements SessionService {

    private final TokenProvider tokenProvider;
    private final UserRepository userRepository;
    private final UserDeviceRepository userDeviceRepository;
    private final UserSessionRepository userSessionRepository;

    @Value("${app.jwt.refresh-ttl-days:14}")
    private int refreshTtlDays;

    @Value("${app.jwt.refresh-pepper:}")
    private String refreshPepper; // 비워두면 pepper 미사용

    @Override
    @Transactional
    public String issueRefreshAndStore(String userUuid, String deviceId) {
        return issueRefreshAndStore(userUuid, deviceId, null, null);
    }

    @Override
    @Transactional
    public String issueRefreshAndStore(String userUuid, String deviceId, Boolean pushEnabled, String pushToken) {
        String did = normalize(deviceId);
        log.info("[SessionSvc-01] 리프레시 발급 & 세션 저장 userUuid={}, deviceId(normalized)={}, ttlDays={}, pushEnabled={}, hasPushToken={}",
                userUuid, did, refreshTtlDays, pushEnabled, (pushToken != null && !pushToken.isBlank()));

        // 1) refresh 토큰 생성
        String refresh = tokenProvider.createRefreshToken(userUuid, did, refreshTtlDays);

        // 2) 사용자 조회
        User user = userRepository.findByUuid(UUID.fromString(userUuid))
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        // 3) 기기 업서트(자동 등록/갱신)
        UserDevice device = userDeviceRepository.findByDeviceId(did)
                .orElseGet(() -> userDeviceRepository.save(
                        UserDevice.builder()
                                .user(user)
                                .deviceId(did)
                                .platform(PlatformType.ANDROID) // 기본값
                                .pushEnabled(pushEnabled != null ? pushEnabled : false) // 초기값
                                .pushToken(pushToken) // null 허용
                                .build()
                                .activateNow()
                ));

        // 존재하던 기기라면 전달된 값만 반영: setter 없이 updatePush 한 번으로 갱신
        String newToken = device.getPushToken();
        boolean newEnabled = device.isPushEnabled();
        boolean changed = false;

        if (pushToken != null && !pushToken.isBlank() && !pushToken.equals(newToken)) {
            newToken = pushToken;
            changed = true;
        }
        if (pushEnabled != null && newEnabled != pushEnabled) {
            newEnabled = pushEnabled;
            changed = true;
        }
        if (changed) {
            device.updatePush(newToken, newEnabled);
            userDeviceRepository.save(device);
        }

        // 4) 세션 저장
        String hash = RefreshTokenUtil.sha256Base64(refresh, refreshPepper);
        LocalDateTime exp = LocalDateTime.now().plusDays(refreshTtlDays);

        userSessionRepository.save(
                UserSession.builder()
                        .user(user)
                        .userDevice(device)
                        .refreshTokenHash(hash)
                        .expiresAt(exp)
                        .build()
        );

        log.info("[SessionSvc-02] 세션 저장 완료 userId={}, deviceId={}, exp={}",
                user.getId(), device.getDeviceId(), exp);
        return refresh;
    }

    @Override
    @Transactional(readOnly = true)
    public String reissueAccessByRefresh(String refreshToken, String deviceId) {
        String headerDid = normalize(deviceId);
        log.info("[SessionSvc-11] 리프레시 검증 및 액세스 재발급 deviceId(normalized)={}", headerDid);

        Jws<Claims> jws = tokenProvider.parse(refreshToken);
        Claims c = jws.getPayload();

        String typ = TokenProvider.readTyp(c);
        if (!"refresh".equals(typ)) {
            log.warn("[SessionSvc-E01] 토큰 typ 불일치 typ={}", typ);
            throw new IllegalArgumentException("Invalid token type");
        }
        String didInToken = String.valueOf(c.get("did"));
        if (!headerDid.equals(didInToken)) {
            log.warn("[SessionSvc-E02] 디바이스 불일치 tokenDid={}, headerDid={}", didInToken, headerDid);
            throw new IllegalArgumentException("Device mismatch");
        }

        String userUuid = c.getSubject();
        String hash = RefreshTokenUtil.sha256Base64(refreshToken, refreshPepper);

        var sessionOpt = userSessionRepository.findByRefreshTokenHash(hash);
        if (sessionOpt.isEmpty() || !sessionOpt.get().isActive()) {
            log.warn("[SessionSvc-E03] 세션 없음 또는 만료/리보크 hash={}", hash.substring(0, 8));
            throw new IllegalArgumentException("Session not found or revoked");
        }

        String access = tokenProvider.createAccessToken(userUuid, headerDid);
        log.info("[SessionSvc-13] 액세스 토큰 재발급 완료 userUuid={}, deviceId={}", userUuid, headerDid);
        return access;
    }

    @Override
    @Transactional
    public void logoutByDevice(String userUuid, String deviceId, String refreshTokenOrNull) {
        String did = normalize(deviceId);
        log.info("[SessionSvc-21] 로그아웃 요청 수신 userUuid={}, deviceId(normalized)={}", userUuid, did);

        User user = userRepository.findByUuid(UUID.fromString(userUuid))
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        var device = userDeviceRepository.findByUserAndDeviceId(user, did)
                .orElseThrow(() -> new IllegalArgumentException("디바이스를 찾을 수 없습니다."));

        if (refreshTokenOrNull != null && !refreshTokenOrNull.isBlank()) {
            String hash = RefreshTokenUtil.sha256Base64(refreshTokenOrNull, refreshPepper);
            userSessionRepository.findByRefreshTokenHash(hash)
                    .ifPresent(s -> { if (s.isActive()) s.revoke("user logout"); });
            log.info("[SessionSvc-22] 특정 refresh 리보크 완료");
        } else {
            userSessionRepository.findByUserAndUserDevice(user, device)
                    .forEach(s -> { if (s.isActive()) s.revoke("logout all by device"); });
            log.info("[SessionSvc-23] 디바이스 전체 세션 리보크 완료");
        }
    }
}
