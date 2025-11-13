package com.ssafy.b205.backend.domain.auth.service;

import com.ssafy.b205.backend.domain.auth.dto.response.SessionResponse;
import com.ssafy.b205.backend.domain.device.entity.PlatformType;
import com.ssafy.b205.backend.domain.device.entity.UserDevice;
import com.ssafy.b205.backend.domain.device.repository.UserDeviceRepository;
import com.ssafy.b205.backend.domain.session.entity.UserSession;
import com.ssafy.b205.backend.domain.session.repository.UserSessionRepository;
import com.ssafy.b205.backend.domain.user.entity.User;
import com.ssafy.b205.backend.domain.user.repository.UserRepository;
import com.ssafy.b205.backend.infra.security.RefreshTokenUtil;
import com.ssafy.b205.backend.infra.security.TokenProvider;
import com.ssafy.b205.backend.support.error.AppException;
import com.ssafy.b205.backend.support.error.ErrorCode;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jws;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.List;
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
        final String did = normalize(deviceId);
        log.info("[SessionSvc-01] 리프레시 발급 & 세션 저장 userUuid={}, deviceId(normalized)={}, ttlDays={}, pushEnabled={}, hasPushToken={}",
                userUuid, did, refreshTtlDays, pushEnabled, (pushToken != null && !pushToken.isBlank()));

        // 1) refresh 토큰 생성
        final String refresh = tokenProvider.createRefreshToken(userUuid, did, refreshTtlDays);

        // 2) 사용자 조회 (소프트 삭제 제외)
        final User user = userRepository.findByUuidAndDeletedAtIsNull(UUID.fromString(userUuid))
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        // 3) 기기 업서트(자동 등록/갱신) — 기본 pushEnabled=false
        UserDevice device = userDeviceRepository.findByUserAndDeviceId(user, did)
                .orElseGet(() -> userDeviceRepository.save(
                        UserDevice.builder()
                                .user(user)
                                .deviceId(did)
                                .platform(PlatformType.ANDROID) // 기본값
                                .pushEnabled(pushEnabled != null ? pushEnabled : false)
                                .pushToken(pushToken) // null 허용
                                .build()
                                .activateNow()
                ));

        // 존재하던 기기라면 전달된 값만 반영 (setter 금지 → 도메인 메서드 사용)
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
        final String hash = RefreshTokenUtil.sha256Base64(refresh, refreshPepper);
        final LocalDateTime exp = LocalDateTime.now().plusDays(refreshTtlDays);

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
        final String headerDid = normalize(deviceId);
        log.info("[SessionSvc-11] 리프레시 검증 및 액세스 재발급 deviceId(normalized)={}", headerDid);

        final Jws<Claims> jws = tokenProvider.parse(refreshToken);
        final Claims c = jws.getPayload();

        final String typ = TokenProvider.readTyp(c);
        if (!"refresh".equals(typ)) {
            log.warn("[SessionSvc-E01] 토큰 typ 불일치 typ={}", typ);
            throw new IllegalArgumentException("Invalid token type");
        }
        final String didInToken = String.valueOf(c.get("did"));
        if (!headerDid.equals(didInToken)) {
            log.warn("[SessionSvc-E02] 디바이스 불일치 tokenDid={}, headerDid={}", didInToken, headerDid);
            throw new IllegalArgumentException("Device mismatch");
        }

        final String userUuid = c.getSubject();
        final String hash = RefreshTokenUtil.sha256Base64(refreshToken, refreshPepper);

        var sessionOpt = userSessionRepository.findByRefreshTokenHash(hash);
        if (sessionOpt.isEmpty() || !sessionOpt.get().isActive()) {
            String safeHash = (hash != null && hash.length() >= 8) ? hash.substring(0, 8) : "NA";
            log.warn("[SessionSvc-E03] 세션 없음 또는 만료/리보크 hash={}", safeHash);
            throw new IllegalArgumentException("Session not found or revoked");
        }

        final String access = tokenProvider.createAccessToken(userUuid, headerDid);
        log.info("[SessionSvc-13] 액세스 토큰 재발급 완료 userUuid={}, deviceId={}", userUuid, headerDid);
        return access;
    }

    @Override
    @Transactional
    public void logoutByDevice(String userUuid, String deviceId, String refreshTokenOrNull) {
        final String did = normalize(deviceId);
        log.info("[SessionSvc-21] 로그아웃 요청 수신 userUuid={}, deviceId(normalized)={}", userUuid, did);

        final User user = userRepository.findByUuidAndDeletedAtIsNull(UUID.fromString(userUuid))
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        if (refreshTokenOrNull != null && !refreshTokenOrNull.isBlank()) {
            final String hash = RefreshTokenUtil.sha256Base64(refreshTokenOrNull, refreshPepper);
            userSessionRepository.findByRefreshTokenHash(hash)
                    .ifPresent(s -> { if (s.isActive()) s.revoke("user logout"); });
            log.info("[SessionSvc-22] 특정 refresh 리보크 완료");
            return;
        }

        final UserDevice device = userDeviceRepository.findByUserAndDeviceId(user, did)
                .orElse(null);

        if (device == null) {
            log.warn("[SessionSvc-W21] userUuid={}, deviceId={} 에 해당하는 기기 레코드가 없어 멱등 처리합니다.", userUuid, did);
            return;
        }

        userSessionRepository.findByUserAndUserDevice(user, device)
                .forEach(s -> { if (s.isActive()) s.revoke("logout all by device"); });
        log.info("[SessionSvc-23] 디바이스 전체 세션 리보크 완료");
    }

    /** UUID 형태의 deviceId를 부분 마스킹 (원형 노출 방지) */
    private static String maskDeviceId(String v) {
        if (v == null || v.isBlank()) return "unknown";
        // UUID라 가정: 앞 8자리 + 마지막 4자리만 노출
        // 예) 11111111-1111-1111-1111-111111111111 → 11111111-****-****-****-1111
        String[] parts = v.split("-");
        if (parts.length == 5) {
            return parts[0] + "-****-****-****-" + parts[4].substring(Math.max(0, parts[4].length()-4));
        }
        // UUID가 아니어도 최소 마스킹
        int len = v.length();
        if (len <= 8) return "****";
        return v.substring(0, 4) + "****" + v.substring(len - 4);
    }

    /** 사람이 구분만 하도록 디바이스 라벨을 만든다: 예) ANDROID • 11111111-****-****-****-1111 */
    private static String buildDeviceLabel(String platform, String rawDeviceId) {
        return (platform == null ? "UNKNOWN" : platform) + " • " + maskDeviceId(rawDeviceId);
    }

    @Override
    @Transactional(readOnly = true)
    public List<SessionResponse> listSessions(String userUuid) {
        final User user = userRepository.findByUuidAndDeletedAtIsNull(UUID.fromString(userUuid))
                .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND, "[UserSvc-E05] UUID로 사용자 없음: " + userUuid));

        return userSessionRepository.findByUser(user).stream()
                .map(s -> new SessionResponse(
                        s.getUuid(),                                  // sessionUuid (공개)
                        s.getUserDevice().getUuid(),                  // deviceUuid  (공개)
                        buildDeviceLabel(s.getUserDevice().getPlatform().name(),
                                s.getUserDevice().getDeviceId()),  // 사람이 구분할 라벨(마스킹)
                        toUtc(s.getIssuedAt()),
                        toUtc(s.getExpiresAt()),
                        toUtc(s.getRevokedAt()),
                        s.getUserDevice().isPushEnabled()
                ))
                .toList();
    }

    /** LocalDateTime(naive)을 UTC 기준 Instant로 표준화 */
    private static Instant toUtc(LocalDateTime ldt) {
        return (ldt == null) ? null : ldt.atOffset(ZoneOffset.UTC).toInstant();
    }

    @Override
    @Transactional
    public void revokeByUuid(String userUuid, UUID sessionUuid) {
        final User user = userRepository.findByUuidAndDeletedAtIsNull(UUID.fromString(userUuid))
                .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND, "[UserSvc-E05] UUID로 사용자 없음: " + userUuid));

        final UserSession session = userSessionRepository.findByUuidAndUser(sessionUuid, user)
                .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND, "[AuthSvc-E12] 세션을 찾을 수 없습니다."));

        if (session.isActive()) {
            session.revoke("manual revoke by uuid");
        }
    }
}
