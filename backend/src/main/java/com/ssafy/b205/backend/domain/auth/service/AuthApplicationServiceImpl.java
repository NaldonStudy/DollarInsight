package com.ssafy.b205.backend.domain.auth.service;

import com.ssafy.b205.backend.domain.user.dto.request.LoginRequest;
import com.ssafy.b205.backend.domain.user.dto.request.SignupRequest;
import com.ssafy.b205.backend.domain.user.dto.response.TokenPairResponse;
import com.ssafy.b205.backend.domain.user.entity.User;
import com.ssafy.b205.backend.domain.user.service.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthApplicationServiceImpl implements AuthApplicationService {

    private final UserService userService;
    private final SessionService sessionService;

    @Override
    @Transactional
    public TokenPairResponse signupAndIssue(SignupRequest req, String deviceId) {
        log.info("[AuthApp-01] 회원가입 시작 email={}, deviceId={}", req.getEmail(), deviceId);

        // 1) 회원 생성
        User u = userService.signup(req.getEmail(), req.getNickname(), req.getPassword());
        log.info("[AuthApp-02] 사용자 생성 완료 uuid={}, email={}", u.getUuid(), u.getEmail());

        // 2) access 발급 (DeviceId 정규화는 내부에서 처리)
        String access = userService.createAccessFor(u, deviceId);
        log.info("[AuthApp-03] 액세스 토큰 발급 완료 uuid={}, deviceId={}", u.getUuid(), deviceId);

        // 3) refresh 발급 + 세션/기기 자동 업서트
        //    - 회원가입 단계의 알림 설정을 첫 기기에 초기값으로 반영
        Boolean pushEnabled = (req.getPushEnabled() == null) ? Boolean.FALSE : req.getPushEnabled();
        String refresh = sessionService.issueRefreshAndStore(
                u.getUuid().toString(),
                deviceId,
                pushEnabled,   // 첫 기기 알림 사용 여부 초기값
                null           // 푸시토큰은 로그인 직후엔 없을 수 있으므로 별도 PATCH에서 갱신
        );
        log.info("[AuthApp-04] 리프레시 토큰 발급 완료 uuid={}, deviceId={}, pushEnabled={}",
                u.getUuid(), deviceId, pushEnabled);

        return new TokenPairResponse(access, refresh);
    }

    @Override
    public TokenPairResponse loginAndIssue(LoginRequest req, String deviceId) {
        log.info("[AuthApp-11] 로그인 시도 email={}, deviceId={}", req.getEmail(), deviceId);

        // 1) access 발급 (비밀번호 검증 포함)
        String access = userService.issueAccess(req.getEmail(), req.getPassword(), deviceId);
        log.info("[AuthApp-12] 액세스 토큰 발급 완료 email={}, deviceId={}", req.getEmail(), deviceId);

        // 2) refresh 발급 + 세션/기기 자동 업서트 (알림설정은 기존 상태 유지)
        String userUuid = userService.getByEmailActive(req.getEmail()).getUuid().toString();
        String refresh = sessionService.issueRefreshAndStore(
                userUuid,
                deviceId
                // pushEnabled/pushToken은 null → 기존 값 유지하며 업서트
        );
        log.info("[AuthApp-13] 리프레시 토큰 발급 완료 userUuid={}, deviceId={}", userUuid, deviceId);

        return new TokenPairResponse(access, refresh);
    }
}
