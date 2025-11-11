package com.ssafy.b205.backend.infra.client.kakao;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.ConstructorBinding;

@ConfigurationProperties(prefix = "app.oauth.kakao")
public class KakaoOAuthProperties {

    private final String clientId;              // 필수
    private final String clientSecret;          // 선택
    private final String defaultRedirectUri;    // 선택(웹 켤 때만)
    private final int timeoutSeconds;           // 기본 5
    private final boolean allowDefaultRedirect; // 기본 false

    @ConstructorBinding
    public KakaoOAuthProperties(
            String clientId,
            String clientSecret,
            String defaultRedirectUri,
            Integer timeoutSeconds,
            Boolean allowDefaultRedirect
    ) {
        this.clientId = clientId;
        this.clientSecret = clientSecret;
        this.defaultRedirectUri = defaultRedirectUri;
        this.timeoutSeconds = (timeoutSeconds != null ? timeoutSeconds : 5);
        this.allowDefaultRedirect = (allowDefaultRedirect != null ? allowDefaultRedirect : false);
    }

    public String getClientId() { return clientId; }
    public String getClientSecret() { return clientSecret; }
    public String getDefaultRedirectUri() { return defaultRedirectUri; }
    public int getTimeoutSeconds() { return timeoutSeconds; }
    public boolean getAllowDefaultRedirect() { return allowDefaultRedirect; }
}
