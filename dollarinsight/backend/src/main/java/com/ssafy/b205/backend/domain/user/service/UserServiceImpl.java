package com.ssafy.b205.backend.domain.user.service;

import com.ssafy.b205.backend.domain.user.entity.User;
import com.ssafy.b205.backend.domain.user.entity.UserCredential;
import com.ssafy.b205.backend.domain.user.repository.UserCredentialRepository;
import com.ssafy.b205.backend.domain.user.repository.UserRepository;
import com.ssafy.b205.backend.domain.persona.service.UserPersonaService;
import com.ssafy.b205.backend.infra.security.TokenProvider;
import com.ssafy.b205.backend.support.error.AppException;
import com.ssafy.b205.backend.support.error.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

import static com.ssafy.b205.backend.infra.security.DeviceIdResolver.normalize;

@Slf4j
@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final UserCredentialRepository credentialRepository;
    private final UserPersonaService userPersonaService;
    private final PasswordEncoder passwordEncoder;
    private final TokenProvider tokenProvider;

    private static final java.util.regex.Pattern STRONG_PW =
            java.util.regex.Pattern.compile("^(?=.*[A-Za-z])(?=.*\\d)(?=.*[^A-Za-z0-9])\\S{8,64}$");

    @Override
    @Transactional
    public User signup(String email, String nickname, String rawPassword) {
        log.info("[UserSvc-01] 회원가입 요청 수신 email={}", email);

        if (!STRONG_PW.matcher(rawPassword).matches()) {
            log.warn("[UserSvc-E06] 비밀번호 규칙 위반 email={}", email);
            throw new IllegalArgumentException("비밀번호 규칙을 만족하지 않습니다. (영문/숫자/특수문자 각 1자 이상, 공백 불가, 8~64자)");
        }

        if (userRepository.existsByEmailIgnoreCaseAndDeletedAtIsNull(email)) {
            log.warn("[UserSvc-E01] 이미 존재하는 이메일 email={}", email);
            throw new IllegalArgumentException("이미 사용 중인 이메일입니다.");
        }

        User u = userRepository.save(User.builder()
                .email(email)
                .nickname(nickname)
                .build());
        log.info("[UserSvc-02] 사용자 저장 완료 id={}, uuid={}, email={}", u.getId(), u.getUuid(), u.getEmail());

        credentialRepository.save(UserCredential.builder()
                .user(u)
                .passwordHash(passwordEncoder.encode(rawPassword))
                .build());
        log.info("[UserSvc-03] 자격증명 저장 완료 userId={}", u.getId());

        userPersonaService.initializeForUser(u.getId());

        return u;
    }

    @Override
    public String issueAccess(String email, String rawPassword, String deviceId) {
        String did = normalize(deviceId);
        log.info("[UserSvc-11] 액세스 토큰 발급 시도 email={}, deviceId(normalized)={}", email, did);

        User u = getByEmailActive(email);
        String hash = credentialRepository.findByUser(u)
                .orElseThrow(() -> {
                    log.warn("[UserSvc-E02] 자격증명 없음 userId={}", u.getId());
                    return new IllegalStateException("자격증명을 찾을 수 없습니다.");
                })
                .getPasswordHash();

        if (!passwordEncoder.matches(rawPassword, hash)) {
            log.warn("[UserSvc-E03] 비밀번호 불일치 email={}", email);
            throw new IllegalArgumentException("비밀번호가 일치하지 않습니다.");
        }

        String access = tokenProvider.createAccessToken(u.getUuid().toString(), did);
        log.info("[UserSvc-12] 액세스 토큰 발급 완료 userUuid={}, deviceId(normalized)={}", u.getUuid(), did);

        return access;
    }

    @Override
    public String createAccessFor(User user, String deviceId) {
        String did = normalize(deviceId);
        String access = tokenProvider.createAccessToken(user.getUuid().toString(), did);
        log.info("[UserSvc-21] (회원가입 직후) 액세스 토큰 발급 완료 userUuid={}, deviceId(normalized)={}", user.getUuid(), did);
        return access;
    }

    @Override
    public User getByEmailActive(String email) {
        User u = userRepository.findByEmailIgnoreCaseAndDeletedAtIsNull(email)
                .orElseThrow(() -> {
                    log.warn("[UserSvc-E04] 활성 사용자 없음 email={}", email);
                    return new IllegalArgumentException("사용자를 찾을 수 없습니다.");
                });
        log.info("[UserSvc-31] 이메일로 사용자 조회 완료 id={}, uuid={}, email={}", u.getId(), u.getUuid(), u.getEmail());
        return u;
    }

    @Override
    public User getByUuid(String userUuid) {
        User u = userRepository.findByUuidAndDeletedAtIsNull(UUID.fromString(userUuid))
                .orElseThrow(() -> {
                    log.warn("[UserSvc-E05] UUID로 활성 사용자 없음 uuid={}", userUuid);
                    return new IllegalArgumentException("사용자를 찾을 수 없습니다.");
                });
        log.info("[UserSvc-41] UUID로 사용자 조회 완료 id={}, uuid={}, email={}", u.getId(), u.getUuid(), u.getEmail());
        return u;
    }

    @Override
    @Transactional
    public void changeNickname(String userUuid, String nickname) {
        User user = userRepository.findByUuidAndDeletedAtIsNull(UUID.fromString(userUuid))
                .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND, "[UserSvc-E05] UUID로 사용자 없음: " + userUuid));

        // 동일 닉네임(대소문자 무시)로 변경 시 빠른 종료
        if (user.getNickname() != null && user.getNickname().equalsIgnoreCase(nickname)) {
            log.info("[UserSvc-51] 닉네임 동일(대소문자 무시) → 변경 스킵 userId={}, nickname={}", user.getId(), nickname);
            return;
        }

        // 자기 자신 제외하고 중복 검사
        if (userRepository.existsByNicknameIgnoreCaseAndDeletedAtIsNullAndIdNot(nickname, user.getId())) {
            throw new AppException(ErrorCode.CONFLICT, "[UserSvc-E07] 닉네임 중복: " + nickname);
        }

        user.updateNickname(nickname);
        log.info("[UserSvc-52] 닉네임 변경 완료 userId={}, newNickname={}", user.getId(), nickname);
    }

    @Override
    @Transactional
    public void changePassword(String userUuid, String oldPassword, String newPassword) {
        User user = userRepository.findByUuidAndDeletedAtIsNull(UUID.fromString(userUuid))
                .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND, "[UserSvc-E05] UUID로 사용자 없음: " + userUuid));

        UserCredential cred = credentialRepository.findByUser(user)
                .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND, "[UserCredSvc-E01] 자격증명 없음: user=" + user.getId()));

        if (!passwordEncoder.matches(oldPassword, cred.getPasswordHash())) {
            throw new AppException(ErrorCode.FORBIDDEN, "[UserCredSvc-E02] 현재 비밀번호 불일치");
        }
        if (passwordEncoder.matches(newPassword, cred.getPasswordHash())) {
            throw new AppException(ErrorCode.BAD_REQUEST, "[UserCredSvc-E03] 새 비밀번호가 기존과 동일");
        }

        cred.updatePassword(passwordEncoder.encode(newPassword));
        log.info("[UserSvc-61] 비밀번호 변경 완료 userId={}", user.getId());
    }

    @Override
    @Transactional
    public void changePersonas(String userUuid, List<String> personaCodes) {
        User user = userRepository.findByUuidAndDeletedAtIsNull(UUID.fromString(userUuid))
                .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND, "[UserSvc-E05] UUID로 사용자 없음: " + userUuid));

        userPersonaService.updateEnabledPersonas(user.getId(), personaCodes);
        log.info("[UserSvc-81] 페르소나 변경 완료 userId={}, personaCount={}", user.getId(),
                personaCodes == null ? 0 : personaCodes.size());
    }

    @Override
    @Transactional
    public void softDelete(String userUuid) {
        User user = userRepository.findByUuidAndDeletedAtIsNull(UUID.fromString(userUuid))
                .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND, "[UserSvc-E05] UUID로 사용자 없음: " + userUuid));
        user.markWithdrawn();
        log.info("[UserSvc-71] 소프트 삭제 완료 userId={}", user.getId());
    }
}
