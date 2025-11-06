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

        // 2) (비밀번호 재검증 없이) 액세스 토큰 발급
        String access = userService.createAccessFor(u, deviceId);
        log.info("[AuthApp-03] 액세스 토큰 발급 완료 uuid={}, deviceId={}", u.getUuid(), deviceId);

        // 3) 리프레시 토큰 발급 (V1: 서버 저장 없음, V2에서 세션 저장/리보크 예정)
        String refresh = sessionService.issueRefreshAndStore(u.getUuid().toString(), deviceId);
        log.info("[AuthApp-04] 리프레시 토큰 발급 완료 uuid={}, deviceId={}", u.getUuid(), deviceId);

        return new TokenPairResponse(access, refresh);
    }

    @Override
    public TokenPairResponse loginAndIssue(LoginRequest req, String deviceId) {
        log.info("[AuthApp-11] 로그인 시도 email={}, deviceId={}", req.getEmail(), deviceId);

        String access = userService.issueAccess(req.getEmail(), req.getPassword(), deviceId);
        log.info("[AuthApp-12] 액세스 토큰 발급 완료 email={}, deviceId={}", req.getEmail(), deviceId);

        String userUuid = userService.getByEmailActive(req.getEmail()).getUuid().toString();
        String refresh = sessionService.issueRefreshAndStore(userUuid, deviceId);
        log.info("[AuthApp-13] 리프레시 토큰 발급 완료 userUuid={}, deviceId={}", userUuid, deviceId);

        return new TokenPairResponse(access, refresh);
    }
}
