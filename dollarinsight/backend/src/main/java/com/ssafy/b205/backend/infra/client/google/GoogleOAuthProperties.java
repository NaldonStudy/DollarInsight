package com.ssafy.b205.backend.infra.client.google;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.ConstructorBinding;

@ConfigurationProperties(prefix = "app.oauth.google")
public class GoogleOAuthProperties {

    private static final String DEFAULT_TOKEN_URI = "https://oauth2.googleapis.com/token";
    private static final String DEFAULT_USERINFO_URI = "https://openidconnect.googleapis.com/v1/userinfo";

    private final String clientId;
    private final String clientSecret;
    private final String defaultRedirectUri;
    private final int timeoutSeconds;
    private final boolean allowDefaultRedirect;
    private final String tokenUri;
    private final String userInfoUri;

    @ConstructorBinding
    public GoogleOAuthProperties(
            String clientId,
            String clientSecret,
            String defaultRedirectUri,
            Integer timeoutSeconds,
            Boolean allowDefaultRedirect,
            String tokenUri,
            String userInfoUri
    ) {
        this.clientId = clientId;
        this.clientSecret = clientSecret;
        this.defaultRedirectUri = defaultRedirectUri;
        this.timeoutSeconds = timeoutSeconds != null ? timeoutSeconds : 5;
        this.allowDefaultRedirect = allowDefaultRedirect != null ? allowDefaultRedirect : false;
        this.tokenUri = (tokenUri == null || tokenUri.isBlank()) ? DEFAULT_TOKEN_URI : tokenUri;
        this.userInfoUri = (userInfoUri == null || userInfoUri.isBlank()) ? DEFAULT_USERINFO_URI : userInfoUri;
    }

    public String getClientId() {
        return clientId;
    }

    public String getClientSecret() {
        return clientSecret;
    }

    public String getDefaultRedirectUri() {
        return defaultRedirectUri;
    }

    public int getTimeoutSeconds() {
        return timeoutSeconds;
    }

    public boolean getAllowDefaultRedirect() {
        return allowDefaultRedirect;
    }

    public String getTokenUri() {
        return tokenUri;
    }

    public String getUserInfoUri() {
        return userInfoUri;
    }
}
