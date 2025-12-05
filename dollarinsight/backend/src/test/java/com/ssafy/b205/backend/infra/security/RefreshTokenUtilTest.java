package com.ssafy.b205.backend.infra.security;

import jakarta.servlet.http.Cookie;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletResponse;

import java.time.Duration;

import static org.assertj.core.api.Assertions.assertThat;

class RefreshTokenUtilTest {

    @Test
    void sha256Base64ReturnsDeterministicValue() {
        String result = RefreshTokenUtil.sha256Base64("token", "pep");
        assertThat(result).isEqualTo("JuU1qvZarcXigFNj4F9XLi2sGodi+JQrx1UnOpYOOOY=");
    }

    @Test
    void setHttpOnlyCookieAddsConfiguredCookie() {
        MockHttpServletResponse res = new MockHttpServletResponse();

        RefreshTokenUtil.setHttpOnlyCookie(res, "refresh", "abc123", Duration.ofMinutes(30), true);

        Cookie cookie = res.getCookie("refresh");
        assertThat(cookie).isNotNull();
        assertThat(cookie.getValue()).isEqualTo("abc123");
        assertThat(cookie.isHttpOnly()).isTrue();
        assertThat(cookie.getMaxAge()).isEqualTo((int) Duration.ofMinutes(30).toSeconds());
        assertThat(cookie.getSecure()).isTrue();
    }

    @Test
    void deleteCookieExpiresCookieImmediately() {
        MockHttpServletResponse res = new MockHttpServletResponse();

        RefreshTokenUtil.deleteCookie(res, "refresh", false);

        Cookie cookie = res.getCookie("refresh");
        assertThat(cookie).isNotNull();
        assertThat(cookie.getMaxAge()).isZero();
        assertThat(cookie.getValue()).isEmpty();
        assertThat(cookie.getSecure()).isFalse();
    }
}
