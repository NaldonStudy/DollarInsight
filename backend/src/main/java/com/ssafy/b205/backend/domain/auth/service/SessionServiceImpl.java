package com.ssafy.b205.backend.domain.auth.service;

import com.ssafy.b205.backend.infra.security.TokenProvider;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jws;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class SessionServiceImpl implements SessionService {

    private final TokenProvider tokenProvider;

    @Value("${app.jwt.refresh-ttl-days:14}")
    private int refreshTtlDays;

    @Override
    public String issueRefreshAndStore(String userUuid, String deviceId) {
        log.info("[SessionSvc-01] 리프레시 토큰 발급 요청 userUuid={}, deviceId={}, ttlDays={}",
                userUuid, deviceId, refreshTtlDays);
        // V1: 저장 없이 발급만. (V2에서 user_session 해시 저장 + device FK 연결 예정)
        return tokenProvider.createRefreshToken(userUuid, deviceId, refreshTtlDays);
    }

    @Override
    public String reissueAccessByRefresh(String refreshToken, String deviceId) {
        log.info("[SessionSvc-11] 리프레시 검증 및 액세스 재발급 시작 deviceId={}", deviceId);

        Jws<Claims> jws = tokenProvider.parse(refreshToken);
        Claims c = jws.getPayload();

        String typ = TokenProvider.readTyp(c);
        if (!"refresh".equals(typ)) {
            log.warn("[SessionSvc-E01] 토큰 typ 불일치 typ={}", typ);
            throw new IllegalArgumentException("Invalid token type");
        }
        String did = String.valueOf(c.get("did"));
        if (!deviceId.equals(did)) {
            log.warn("[SessionSvc-E02] 디바이스 불일치 tokenDid={}, headerDid={}", did, deviceId);
            throw new IllegalArgumentException("Device mismatch");
        }
        String userUuid = c.getSubject();
        log.info("[SessionSvc-12] 리프레시 토큰 검증 완료 userUuid={}, deviceId={}", userUuid, deviceId);

        String access = tokenProvider.createAccessToken(userUuid, deviceId);
        log.info("[SessionSvc-13] 액세스 토큰 재발급 완료 userUuid={}, deviceId={}", userUuid, deviceId);
        return access;
    }

    @Override
    public void logoutByDevice(String userUuid, String deviceId, String refreshTokenOrNull) {
        log.info("[SessionSvc-21] 로그아웃 요청 수신 userUuid={}, deviceId={}", userUuid, deviceId);
        // V1: 저장소가 없으므로 별도 처리 없음. (V2에서 revoke 처리 예정)
    }
}
