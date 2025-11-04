package com.ssafy.b205.backend.infra.security;

import io.jsonwebtoken.Claims;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

@Component
public class TokenFilter extends OncePerRequestFilter {

    private final TokenProvider tokenProvider;

    public TokenFilter(TokenProvider tokenProvider) { this.tokenProvider = tokenProvider; }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest req) {
        String p = req.getRequestURI();
        if (p.startsWith("/api/auth/login"))   return true;
        if (p.startsWith("/api/auth/refresh")) return true;
        if (p.startsWith("/api/auth/signup"))  return true;
        if (p.startsWith("/v3/api-docs") || p.startsWith("/swagger-ui") || p.startsWith("/actuator/health")) return true;
        return false;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
            throws ServletException, IOException {

        String h = req.getHeader(HttpHeaders.AUTHORIZATION);
        if (h == null || !h.startsWith(SecurityConstants.BEARER_PREFIX)) {
            chain.doFilter(req, res); // 보호자원 접근 시 401은 SecurityConfig가 책임
            return;
        }

        String token = h.substring(SecurityConstants.BEARER_PREFIX.length());
        try {
            var jws = tokenProvider.parse(token);
            Claims c = jws.getPayload();

            String didInToken  = String.valueOf(c.get("did"));
            String didInHeader = DeviceIdResolver.resolveValidOrNull(req);
            if (didInHeader == null || !didInToken.equals(didInHeader)) {
                res.setStatus(HttpStatus.FORBIDDEN.value());
                res.setContentType("application/json");
                res.getWriter().write(
                        "{ \"success\": false, " +
                                "\"message\": \"[AuthService - 013] 토큰의 디바이스와 요청 디바이스가 일치하지 않습니다.\"," +
                                "\"data\": null }"
                );
                return;
            }

            var auth = new UsernamePasswordAuthenticationToken(
                    c.getSubject(), null, List.of(new SimpleGrantedAuthority("ROLE_USER")));
            SecurityContextHolder.getContext().setAuthentication(auth);

        } catch (Exception ignore) {
            // 파싱 실패 → 이후 보호자원 접근에서 401
        }
        chain.doFilter(req, res);
    }
}
