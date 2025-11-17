package com.ssafy.b205.backend.infra.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jws;
import org.assertj.core.api.InstanceOfAssertFactories;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.Instant;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class TokenProviderTest {

    private static final String SECRET_32 = "0123456789abcdef0123456789abcdef";

    @Test
    void initFailsWhenSecretMissing() {
        TokenProvider provider = new TokenProvider();
        ReflectionTestUtils.setField(provider, "secretBase64", "");
        ReflectionTestUtils.setField(provider, "secretRaw", "too-short");

        assertThatThrownBy(provider::init)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Invalid JWT secret");
    }

    @Test
    void createAccessTokenIncludesNormalizedDeviceIdAndStandardClaims() {
        TokenProvider provider = newProviderWithRawSecret(SECRET_32, 600);

        String token = provider.createAccessToken("user-uuid", "  device-one  ");
        Jws<Claims> parsed = provider.parse(token);
        Claims claims = parsed.getPayload();

        assertThat(claims.getSubject()).isEqualTo("user-uuid");
        assertThat(claims.get("did", String.class)).isEqualTo("device-one");
        assertThat(claims.get("aud"))
                .asInstanceOf(InstanceOfAssertFactories.set(String.class))
                .containsExactly("mobile");
        assertThat(claims.get("roles"))
                .asInstanceOf(InstanceOfAssertFactories.list(String.class))
                .containsExactly("USER");

        Instant issued = claims.getIssuedAt().toInstant();
        Instant expires = claims.getExpiration().toInstant();
        assertThat(expires).isEqualTo(issued.plusSeconds(600));
    }

    @Test
    void createRefreshTokenSetsTypClaimAndDeviceId() {
        TokenProvider provider = newProviderWithRawSecret(SECRET_32, 60);

        String token = provider.createRefreshToken("user-uuid", " Device#2 ", 3);
        Claims claims = provider.parse(token).getPayload();

        assertThat(claims.getSubject()).isEqualTo("user-uuid");
        assertThat(claims.get("did", String.class)).isEqualTo("Device#2");
        assertThat(TokenProvider.readTyp(claims)).isEqualTo("refresh");
        assertThat(claims.getExpiration().toInstant())
                .isAfter(claims.getIssuedAt().toInstant().plusSeconds(2 * 24 * 3600L));
    }

    private TokenProvider newProviderWithRawSecret(String secret, long accessTtlSeconds) {
        TokenProvider provider = new TokenProvider();
        ReflectionTestUtils.setField(provider, "secretBase64", "");
        ReflectionTestUtils.setField(provider, "secretRaw", secret);
        ReflectionTestUtils.setField(provider, "accessTtlSec", accessTtlSeconds);
        provider.init();
        return provider;
    }
}
