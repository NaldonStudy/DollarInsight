package com.ssafy.b205.backend.infra.security;

import com.ssafy.b205.backend.support.error.ErrorCode;
import com.ssafy.b205.backend.support.error.ErrorHttpWriter;
import io.jsonwebtoken.Claims;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpHeaders;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Collection;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

@Component
public class TokenFilter extends OncePerRequestFilter {

    private final TokenProvider tokenProvider;

    public TokenFilter(TokenProvider tokenProvider) {
        this.tokenProvider = tokenProvider;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest req) {
        String p = req.getRequestURI();

        // 공개/문서/헬스체크/인증 경로는 토큰 검사 스킵
        if (p.equals("/api/public") || p.startsWith("/api/public/")) return true;
        if (p.startsWith("/api/auth/login"))   return true;
        if (p.startsWith("/api/auth/refresh")) return true;
        if (p.startsWith("/api/auth/signup"))  return true;
        if (p.startsWith("/v3/api-docs"))      return true;
        if (p.startsWith("/swagger-ui"))       return true;
        if (p.equals("/swagger-ui.html"))      return true;
        if (p.startsWith("/actuator/health"))  return true;

        // CORS preflight도 통과
        if ("OPTIONS".equalsIgnoreCase(req.getMethod())) return true;

        return false;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
            throws ServletException, IOException {

        String h = req.getHeader(HttpHeaders.AUTHORIZATION);
        if (h == null || !h.startsWith(SecurityConstants.BEARER_PREFIX)) {
            // 보호 자원 접근 시 최종 401 처리는 Security의 EntryPoint가 담당
            chain.doFilter(req, res);
            return;
        }

        String token = h.substring(SecurityConstants.BEARER_PREFIX.length());
        try {
            var jws = tokenProvider.parse(token);   // Jws<Claims>
            Claims c = jws.getPayload();

            // ── Device binding 검증
            String didInToken  = String.valueOf(c.get("did"));              // TokenProvider에서 normalize하여 저장됨
            String didInHeader = DeviceIdResolver.resolveValidOrNull(req);  // 헤더도 normalize + 빈값 거절
            if (didInHeader == null || !didInToken.equals(didInHeader)) {
                ErrorHttpWriter.write(
                        req, res,
                        ErrorCode.FORBIDDEN,
                        "[AuthService-013] 토큰의 디바이스와 요청 디바이스가 일치하지 않습니다."
                );
                return;
            }

            // ── 권한 설정: roles 클레임이 있으면 반영, 없으면 ROLE_USER 기본
            var authorities = extractAuthorities(c);
            if (authorities.isEmpty()) {
                authorities = List.of(new SimpleGrantedAuthority("ROLE_USER"));
            }

            var auth = new UsernamePasswordAuthenticationToken(
                    c.getSubject(), null, authorities);
            SecurityContextHolder.getContext().setAuthentication(auth);

        } catch (Exception ex) {
            // 토큰 파싱/검증 실패 → 401 고정 포맷으로 응답
            ErrorHttpWriter.write(
                    req, res,
                    ErrorCode.UNAUTHORIZED,
                    "유효하지 않은 토큰입니다."
            );
            return;
        }

        chain.doFilter(req, res);
    }

    @SuppressWarnings("unchecked")
    private static List<SimpleGrantedAuthority> extractAuthorities(Claims c) {
        Object rolesObj = c.get("roles");
        if (rolesObj instanceof Collection<?> col) {
            return col.stream()
                    .filter(Objects::nonNull)
                    .map(Object::toString)
                    .map(r -> r.startsWith("ROLE_") ? r : "ROLE_" + r)
                    .map(SimpleGrantedAuthority::new)
                    .collect(Collectors.toList());
        }
        if (rolesObj instanceof String s && !s.isBlank()) {
            // 쉼표구분 문자열도 허용: "USER,ADMIN"
            return List.of(s.split("\\s*,\\s*")).stream()
                    .filter(str -> !str.isBlank())
                    .map(r -> r.startsWith("ROLE_") ? r : "ROLE_" + r)
                    .map(SimpleGrantedAuthority::new)
                    .collect(Collectors.toList());
        }
        return List.of();
    }
}
