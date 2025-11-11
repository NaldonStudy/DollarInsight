package com.ssafy.b205.backend.domain.auth.service;

import com.ssafy.b205.backend.domain.user.dto.response.TokenPairResponse;
import com.ssafy.b205.backend.domain.user.entity.ProviderType;
import com.ssafy.b205.backend.domain.user.entity.User;
import com.ssafy.b205.backend.domain.user.entity.UserOauthAccount;
import com.ssafy.b205.backend.domain.user.repository.UserOauthAccountRepository;
import com.ssafy.b205.backend.domain.user.repository.UserRepository;
import com.ssafy.b205.backend.domain.user.service.UserService;
import com.ssafy.b205.backend.infra.client.kakao.KakaoOAuthProperties;
import com.ssafy.b205.backend.infra.client.kakao.dto.KakaoTokenResponse;
import com.ssafy.b205.backend.infra.client.kakao.dto.KakaoUserResponse;
import com.ssafy.b205.backend.support.error.AppException;
import com.ssafy.b205.backend.support.error.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.client.WebClient;

import java.security.SecureRandom;
import java.util.Optional;

@Slf4j
@Service
public class OAuthLoginService {

    private final WebClient kakaoWebClient;
    private final KakaoOAuthProperties kakaoProps;
    private final UserRepository userRepository;
    private final UserService userService;
    private final SessionService sessionService;
    private final UserOauthAccountRepository oauthRepo;

    // 명시 생성자 + @Qualifier
    public OAuthLoginService(
            @Qualifier("kakaoWebClient") WebClient kakaoWebClient,
            KakaoOAuthProperties kakaoProps,
            UserRepository userRepository,
            UserService userService,
            SessionService sessionService,
            UserOauthAccountRepository oauthRepo
    ) {
        this.kakaoWebClient = kakaoWebClient;
        this.kakaoProps = kakaoProps;
        this.userRepository = userRepository;
        this.userService = userService;
        this.sessionService = sessionService;
        this.oauthRepo = oauthRepo;
    }

    @Transactional
    public TokenPairResponse loginWithKakao(String code, String redirectUri, String deviceId) {
// --- 1) 코드 → 토큰 교환
        MultiValueMap<String, String> form = new LinkedMultiValueMap<>();
        form.add("grant_type", "authorization_code");
        form.add("client_id", require(kakaoProps.getClientId(), "[AuthSvc-E01] 카카오 client_id 미설정"));
        form.add("code", require(code, "[AuthSvc-E02] 인가코드 누락"));

// ★ 여기만 교체
        if (redirectUri != null && !redirectUri.isBlank()) {
            form.add("redirect_uri", redirectUri); // 모바일: 앱이 보낸 스킴 그대로 사용
        } else if (Boolean.TRUE.equals(kakaoProps.getAllowDefaultRedirect())) {
            form.add("redirect_uri",
                    require(kakaoProps.getDefaultRedirectUri(), "[AuthSvc-E03] default redirectUri 미설정"));
        } else {
            throw new AppException(ErrorCode.BAD_REQUEST, "[AuthSvc-E03] redirectUri 미설정");
        }

        if (kakaoProps.getClientSecret() != null && !kakaoProps.getClientSecret().isBlank()) {
            form.add("client_secret", kakaoProps.getClientSecret());
        }


        KakaoTokenResponse token = kakaoWebClient.post()
                .uri("https://kauth.kakao.com/oauth/token")
                .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                .body(BodyInserters.fromFormData(form))
                .retrieve()
                .bodyToMono(KakaoTokenResponse.class)
                .block();

        if (token == null || token.getAccessToken() == null) {
            throw new AppException(ErrorCode.UNAUTHORIZED, "[AuthSvc-E10] 카카오 토큰 교환 실패");
        }

        // --- 2) 토큰 → 사용자 프로필
        KakaoUserResponse me = kakaoWebClient.get()
                .uri("https://kapi.kakao.com/v2/user/me")
                .headers(h -> h.setBearerAuth(token.getAccessToken()))
                .retrieve()
                .bodyToMono(KakaoUserResponse.class)
                .block();

        if (me == null || me.getId() == null) {
            throw new AppException(ErrorCode.UNAUTHORIZED, "[AuthSvc-E11] 카카오 사용자 조회 실패");
        }

        // --- 3) 연동/업서트
        final ProviderType provider = ProviderType.KAKAO;
        final String providerUserId = String.valueOf(me.getId());
        final String emailFromProvider = (me.getKakaoAccount() != null) ? me.getKakaoAccount().getEmail() : null;
        final String nicknameFromProvider = (me.getKakaoAccount() != null && me.getKakaoAccount().getProfile() != null)
                ? me.getKakaoAccount().getProfile().getNickname()
                : null;

        User user = resolveUser(provider, providerUserId, emailFromProvider, nicknameFromProvider);

        // --- 4) 우리 JWT 발급 (기기 바인딩)
        String access = userService.createAccessFor(user, deviceId);
        String refresh = sessionService.issueRefreshAndStore(user.getUuid().toString(), deviceId);

        return new TokenPairResponse(access, refresh);
    }

    private User resolveUser(ProviderType provider,
                             String providerUserId,
                             String emailFromProvider,
                             String nicknameFromProvider) {

        Optional<UserOauthAccount> linked = oauthRepo.findByProviderAndProviderUserId(provider, providerUserId);
        if (linked.isPresent()) {
            return linked.get().getUser();
        }

        // 이메일이 내려오고 기존 유저가 있으면 연동
        if (emailFromProvider != null) {
            Optional<User> existed = userRepository.findByEmailIgnoreCaseAndDeletedAtIsNull(emailFromProvider);
            if (existed.isPresent()) {
                oauthRepo.save(UserOauthAccount.builder()
                        .user(existed.get())
                        .provider(provider)
                        .providerUserId(providerUserId)
                        .emailAtProvider(emailFromProvider)
                        .build());
                return existed.get();
            }
        }

        // 신규 유저 생성
        String email = (emailFromProvider != null) ? emailFromProvider
                : ("kakao_" + providerUserId + "@oauth.local");
        String nickname = (nicknameFromProvider != null && !nicknameFromProvider.isBlank())
                ? nicknameFromProvider
                : ("kakao_user_" + last4(providerUserId));
        String randomPw = randomPassword();

        User created = userService.signup(email, nickname, randomPw);
        oauthRepo.save(UserOauthAccount.builder()
                .user(created)
                .provider(provider)
                .providerUserId(providerUserId)
                .emailAtProvider(emailFromProvider)
                .build());
        return created;
    }

    private static String require(String v, String err) {
        if (v == null || v.isBlank()) throw new AppException(ErrorCode.BAD_REQUEST, err);
        return v;
    }

    private static String randomPassword() {
        final String chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+";
        SecureRandom r = new SecureRandom();
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < 24; i++) sb.append(chars.charAt(r.nextInt(chars.length())));
        return sb.toString();
    }

    private static String last4(String s) {
        return s.substring(Math.max(0, s.length() - 4));
    }
}
