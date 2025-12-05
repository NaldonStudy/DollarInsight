package com.ssafy.b205.backend.infra.security;

import io.jsonwebtoken.Claims;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class TokenProviderTest {

    private TokenProvider providerWithSecret(String secret, long ttlSeconds) {
        TokenProvider p = new TokenProvider();
        ReflectionTestUtils.setField(p, "secretRaw", secret);
        ReflectionTestUtils.setField(p, "accessTtlSec", ttlSeconds);
        p.init();
        return p;
    }

    @Test
    @DisplayName("32바이트 이상 시크릿으로 토큰을 생성/파싱할 수 있다")
    void createAndParse() {
        String secret = "12345678901234567890123456789012";
        TokenProvider p = providerWithSecret(secret, 3600);

        String token = p.createAccessToken("user-uuid", "device-1");
        Claims claims = p.parse(token).getPayload();

        assertThat(claims.getSubject()).isEqualTo("user-uuid");
        assertThat(claims.get("did")).isEqualTo("device-1");
    }

    @Test
    @DisplayName("시크릿이 32바이트 미만이면 초기화 시 예외가 발생한다")
    void secretTooShort() {
        TokenProvider p = new TokenProvider();
        ReflectionTestUtils.setField(p, "secretRaw", "short");
        assertThatThrownBy(p::init).isInstanceOf(IllegalStateException.class);
    }
}
