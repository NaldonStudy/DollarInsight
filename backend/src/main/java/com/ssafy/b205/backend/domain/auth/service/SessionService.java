package com.ssafy.b205.backend.domain.auth.service;

import com.ssafy.b205.backend.domain.auth.dto.response.SessionResponse;

import java.util.List;

public interface SessionService {
    /** refresh 발급 (V1: DB 저장 없이 발급만) */
    String issueRefreshAndStore(String userUuid, String deviceId);

    String issueRefreshAndStore(String userUuid, String deviceId, Boolean pushEnabled, String pushToken);


    /** refresh 검증 후 access 재발급 */
    String reissueAccessByRefresh(String refreshToken, String deviceId);

    /** 로그아웃 (V1: no-op, V2에서 DB revoke) */
    void logoutByDevice(String userUuid, String deviceId, String refreshTokenOrNull);

    List<SessionResponse> listSessions(String userUuid);

    void revokeById(String userUuid, Integer sessionId);
}
