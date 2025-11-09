package com.ssafy.b205.backend.infra.security;

import com.ssafy.b205.backend.support.error.ErrorCode;
import com.ssafy.b205.backend.support.error.ErrorHttpWriter;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jws;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.*;
import java.util.stream.Collectors;

import static com.ssafy.b205.backend.infra.security.DeviceIdResolver.resolveValidOrNull;
import static com.ssafy.b205.backend.infra.security.SecurityConstants.BEARER_PREFIX;

@Component
@RequiredArgsConstructor
public class TokenFilter extends OncePerRequestFilter {

    private final TokenProvider tokenProvider;

    @Override
    protected boolean shouldNotFilter(HttpServletRequest req) {
        String p = req.getRequestURI();

        // 공개/예외 경로
        if (p.equals("/api/public") || p.startsWith("/api/public/")) return true;
        if (p.startsWith("/api/auth/login"))   return true;
        if (p.startsWith("/api/auth/refresh")) return true;
        if (p.startsWith("/api/auth/signup"))  return true;
        if (p.startsWith("/v3/api-docs"))      return true;
        if (p.startsWith("/swagger-ui"))       return true;
        if (p.equals("/swagger-ui.html"))      return true;
        if (p.startsWith("/actuator/health"))  return true;

        // CORS preflight
        if ("OPTIONS".equalsIgnoreCase(req.getMethod())) return true;

        return false;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
            throws ServletException, IOException {

        // 이미 인증된 경우(다른 필터에서 넣었을 가능성) → 통과
        if (SecurityContextHolder.getContext().getAuthentication() != null) {
            chain.doFilter(req, res);
            return;
        }

        // 1) 헤더에서 시도
        String token = null;
        String h = req.getHeader(HttpHeaders.AUTHORIZATION);
        if (h != null && h.startsWith(BEARER_PREFIX)) {
            token = h.substring(BEARER_PREFIX.length()).trim();
        }

        // 2) 헤더가 없으면 ?access_token= 허용 (브라우저 EventSource 호환 / 디버깅 편의)
        if (token == null || token.isBlank()) {
            String fromQuery = req.getParameter("access_token");
            if (fromQuery != null && !fromQuery.isBlank()) {
                token = fromQuery.trim();
            }
        }

        // 토큰이 여전히 없으면 → 다음으로 넘기고, 컨트롤러/시큐리티에서 401 처리
        if (token == null || token.isBlank()) {
            chain.doFilter(req, res);
            return;
        }

        try {
            Jws<Claims> jws = tokenProvider.parse(token);
            Claims c = jws.getPayload();

            // ── Device binding
            String didInToken  = String.valueOf(c.get("did"));
            String didInHeader = resolveValidOrNull(req);
            if (didInHeader == null || !didInToken.equals(didInHeader)) {
                ErrorHttpWriter.write(req, res, ErrorCode.FORBIDDEN,
                        "[AuthService-013] 토큰의 디바이스와 요청 디바이스가 일치하지 않습니다.");
                return;
            }

            // ── 권한
            var authorities = extractAuthorities(c);
            if (authorities.isEmpty()) {
                authorities = List.of(new SimpleGrantedAuthority("ROLE_USER"));
            }

            // ✅ principal = userUuid (sub)
            String userUuid = c.getSubject();
            var auth = new UsernamePasswordAuthenticationToken(userUuid, null, authorities);
            SecurityContextHolder.getContext().setAuthentication(auth);

        } catch (Exception ex) {
            // 파싱 실패 → 401 (메시지는 통일)
            ErrorHttpWriter.write(req, res, ErrorCode.UNAUTHORIZED, "유효하지 않은 토큰입니다.");
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
            return Arrays.stream(s.split("\\s*,\\s*"))
                    .filter(str -> !str.isBlank())
                    .map(r -> r.startsWith("ROLE_") ? r : "ROLE_" + r)
                    .map(SimpleGrantedAuthority::new)
                    .collect(Collectors.toList());
        }
        return List.of();
    }
}
