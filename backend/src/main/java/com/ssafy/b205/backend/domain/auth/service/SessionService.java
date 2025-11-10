package com.ssafy.b205.backend.domain.auth.service;

import com.ssafy.b205.backend.domain.auth.dto.response.SessionResponse;

import java.util.List;
import java.util.UUID;

public interface SessionService {

    String issueRefreshAndStore(String userUuid, String deviceId);

    String issueRefreshAndStore(String userUuid, String deviceId, Boolean pushEnabled, String pushToken);

    String reissueAccessByRefresh(String refreshToken, String deviceId);

    void logoutByDevice(String userUuid, String deviceId, String refreshTokenOrNull);

    List<SessionResponse> listSessions(String userUuid);

    void revokeByUuid(String userUuid, UUID sessionUuid);
}
