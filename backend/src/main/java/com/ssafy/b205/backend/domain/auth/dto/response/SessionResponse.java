package com.ssafy.b205.backend.domain.auth.dto.response;

import lombok.Getter;

import java.time.Instant;
import java.util.UUID;

@Getter
public class SessionResponse {

    private final UUID sessionUuid;    // 공개용 세션 식별자
    private final UUID deviceUuid;     // 공개용 디바이스 식별자
    private final String deviceLabel;  // 사용자용 구분 텍스트(마스킹)
    private final Instant issuedAt;
    private final Instant expiresAt;
    private final Instant revokedAt;   // null 가능
    private final Boolean pushEnabled;

    public SessionResponse(
            UUID sessionUuid,
            UUID deviceUuid,
            String deviceLabel,
            Instant issuedAt,
            Instant expiresAt,
            Instant revokedAt,
            Boolean pushEnabled
    ) {
        this.sessionUuid = sessionUuid;
        this.deviceUuid = deviceUuid;
        this.deviceLabel = deviceLabel;
        this.issuedAt = issuedAt;
        this.expiresAt = expiresAt;
        this.revokedAt = revokedAt;
        this.pushEnabled = pushEnabled;
    }
}
