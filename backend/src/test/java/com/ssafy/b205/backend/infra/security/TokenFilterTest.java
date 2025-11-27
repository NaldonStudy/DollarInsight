package com.ssafy.b205.backend.infra.security;

import com.ssafy.b205.backend.support.error.ErrorCode;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jws;
import io.jsonwebtoken.JwsHeader;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.JwtVisitor;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.http.HttpHeaders;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.io.IOException;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

class TokenFilterTest {

    private final TokenProvider tokenProvider = Mockito.mock(TokenProvider.class);
    private final TokenFilter filter = new TokenFilter(tokenProvider);

    private static final class CountingChain extends MockFilterChain {
        int count = 0;
        @Override
        public void doFilter(ServletRequest request, ServletResponse response) throws IOException, ServletException {
            count++;
            super.doFilter(request, response);
        }
    }

    @AfterEach
    void clear() {
        SecurityContextHolder.clearContext();
    }

    private static Jws<Claims> jws(Claims claims) {
        return new Jws<>() {
            @Override public JwsHeader getHeader() { return null; }
            @Override public Claims getBody() { return claims; }
            @Override public Claims getPayload() { return claims; }
            @Override public byte[] getDigest() { return new byte[0]; }
            @Override public String getSignature() { return ""; }
            @Override public <T> T accept(JwtVisitor<T> visitor) { return visitor.visit(this); }
        };
    }

    @Test
    @DisplayName("유효한 토큰과 기기 헤더가 있으면 인증 컨텍스트를 설정한다")
    void authenticatesWithBearerToken() throws Exception {
        MockHttpServletRequest req = new MockHttpServletRequest("GET", "/api/chat/sessions");
        req.addHeader(HttpHeaders.AUTHORIZATION, "Bearer token-123");
        req.addHeader("X-Device-Id", "device-1");
        MockHttpServletResponse res = new MockHttpServletResponse();
        CountingChain chain = new CountingChain();

        Claims claims = Jwts.claims()
                .subject("user-uuid")
                .add("did", "device-1")
                .add("roles", List.of("USER"))
                .build();
        when(tokenProvider.parse("token-123")).thenReturn(jws(claims));

        filter.doFilter(req, res, chain);

        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        assertThat(auth).isNotNull();
        assertThat(auth.getPrincipal()).isEqualTo("user-uuid");
        assertThat(chain.count).isEqualTo(1);
        assertThat(res.getStatus()).isEqualTo(200);
    }

    @Test
    @DisplayName("기기 헤더가 없으면 403을 반환한다")
    void forbiddenWhenDeviceMissing() throws Exception {
        MockHttpServletRequest req = new MockHttpServletRequest("GET", "/api/chat/sessions");
        req.addHeader(HttpHeaders.AUTHORIZATION, "Bearer token-abc");
        MockHttpServletResponse res = new MockHttpServletResponse();
        CountingChain chain = new CountingChain();

        Claims claims = Jwts.claims()
                .subject("user-uuid")
                .add("did", "device-abc")
                .build();
        when(tokenProvider.parse("token-abc")).thenReturn(jws(claims));

        filter.doFilter(req, res, chain);

        assertThat(res.getStatus()).isEqualTo(ErrorCode.FORBIDDEN.status.value());
        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
        assertThat(chain.count).isZero();
    }

    @Test
    @DisplayName("토큰이 없으면 체인을 그대로 진행한다")
    void noTokenFallsThrough() throws Exception {
        MockHttpServletRequest req = new MockHttpServletRequest("GET", "/api/chat/sessions");
        MockHttpServletResponse res = new MockHttpServletResponse();
        CountingChain chain = new CountingChain();

        filter.doFilter(req, res, chain);

        assertThat(chain.count).isEqualTo(1);
        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
    }
}
