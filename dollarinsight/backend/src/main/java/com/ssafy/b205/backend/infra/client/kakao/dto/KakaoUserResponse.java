package com.ssafy.b205.backend.infra.client.kakao.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class KakaoUserResponse {
    private Long id;

    @JsonProperty("kakao_account")
    private KakaoAccount kakaoAccount;

    @Getter @NoArgsConstructor
    public static class KakaoAccount {
        private String email;
        @JsonProperty("has_email") private Boolean hasEmail;
        @JsonProperty("is_email_valid") private Boolean isEmailValid;
        @JsonProperty("is_email_verified") private Boolean isEmailVerified;
        private Profile profile;
    }

    @Getter @NoArgsConstructor
    public static class Profile {
        private String nickname;
    }
}
