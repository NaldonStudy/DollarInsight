package com.ssafy.b205.backend.domain.auth.dto.response;

import lombok.Getter;

import java.time.LocalDateTime;

@Getter
public class SessionResponse {
    private final Integer id;
    private final String deviceId;
    private final LocalDateTime issuedAt;
    private final LocalDateTime expiresAt;
    private final LocalDateTime revokedAt;
    private final Boolean pushEnabled;

    public SessionResponse(Integer id, String deviceId, LocalDateTime issuedAt,
                           LocalDateTime expiresAt, LocalDateTime revokedAt, Boolean pushEnabled) {
        this.id = id;
        this.deviceId = deviceId;
        this.issuedAt = issuedAt;
        this.expiresAt = expiresAt;
        this.revokedAt = revokedAt;
        this.pushEnabled = pushEnabled;
    }

    // 정적 팩토리 (엔티티 → 응답 변환)
    public static SessionResponse from(com.ssafy.b205.backend.domain.session.entity.UserSession s) {
        String did = (s.getUserDevice() != null) ? s.getUserDevice().getDeviceId() : null;
        Boolean push = (s.getUserDevice() != null) ? s.getUserDevice().isPushEnabled() : null;
        return new SessionResponse(s.getId(), did, s.getIssuedAt(), s.getExpiresAt(), s.getRevokedAt(), push);
        // ↑ setter 없이 생성자만 사용
    }
}
