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

import static com.ssafy.b205.backend.infra.security.SecurityConstants.BEARER_PREFIX;

@Component
@RequiredArgsConstructor
public class TokenFilter extends OncePerRequestFilter {

    private final TokenProvider tokenProvider;

    private static String normalizedPath(HttpServletRequest req) {
        String uri = req.getRequestURI();
        String ctx = req.getContextPath();
        String p = (ctx != null && !ctx.isEmpty() && uri.startsWith(ctx))
                ? uri.substring(ctx.length())
                : uri;
        return p.replaceAll("/{2,}", "/");
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest req) {
        final String path = normalizedPath(req);

        if ("OPTIONS".equalsIgnoreCase(req.getMethod())) return true;
        if ("/error".equals(path)) return true;

        // 공개/예외 경로 (컨텍스트 유무 모두 허용)
        if (path.equals("/public") || path.startsWith("/public/")
                || path.equals("/api/public") || path.startsWith("/api/public/")) return true;

        if (path.equals("/auth/login") || path.startsWith("/auth/login")
                || path.equals("/api/auth/login") || path.startsWith("/api/auth/login")) return true;

        if (path.equals("/auth/refresh") || path.startsWith("/auth/refresh")
                || path.equals("/api/auth/refresh") || path.startsWith("/api/auth/refresh")) return true;

        if (path.equals("/auth/signup") || path.startsWith("/auth/signup")
                || path.equals("/api/auth/signup") || path.startsWith("/api/auth/signup")) return true;

        // 문서/헬스 (둘 다 커버)
        if (path.startsWith("/v3/api-docs") || path.startsWith("/api/v3/api-docs")) return true;
        if (path.startsWith("/swagger-ui")  || path.startsWith("/api/swagger-ui"))  return true;
        if (path.equals("/swagger-ui.html") || path.equals("/api/swagger-ui.html")) return true;
        if (path.startsWith("/actuator")    || path.startsWith("/api/actuator"))    return true;

        return false;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
            throws ServletException, IOException {

        // 이미 인증됨 → 통과
        if (SecurityContextHolder.getContext().getAuthentication() != null) {
            chain.doFilter(req, res);
            return;
        }

        // 1) Authorization: Bearer
        String token = null;
        String authHeader = req.getHeader(HttpHeaders.AUTHORIZATION);
        if (authHeader != null && authHeader.startsWith(BEARER_PREFIX)) {
            token = authHeader.substring(BEARER_PREFIX.length()).trim();
        }

        // 2) ?access_token=
        if (token == null || token.isBlank()) {
            String fromQuery = req.getParameter("access_token");
            if (fromQuery != null && !fromQuery.isBlank()) {
                token = fromQuery.trim();
            }
        }

        // 토큰 없음 → 체인 진행 (컨트롤러/시큐리티가 401 처리)
        if (token == null || token.isBlank()) {
            chain.doFilter(req, res);
            return;
        }

        try {
            // JWT 파싱/검증
            Jws<Claims> jws = tokenProvider.parse(token);
            Claims claims = jws.getPayload();

            // ===== Device Binding (null-safe) =====
            String tokenDid = claims.get("did", String.class);

            // 헤더에서 먼저 확인, 없으면 쿼리 파라미터에서 확인 (SSE용)
            String headerDidRaw = req.getHeader("X-Device-Id");
            if (headerDidRaw == null || headerDidRaw.isBlank()) {
                // 헤더가 없으면 쿼리 파라미터에서 확인 (SSE EventSource는 헤더 설정 불가)
                headerDidRaw = req.getParameter("device_id");
            }
            if (headerDidRaw == null || headerDidRaw.isBlank()) {
                // 장치 헤더/파라미터가 없으면 토큰과 비교 이전에 차단
                ErrorHttpWriter.write(req, res, ErrorCode.FORBIDDEN, "[AuthSvc-E07] missing X-Device-Id");
                return;
            }
            String headerDid = com.ssafy.b205.backend.infra.security.DeviceIdResolver.normalize(headerDidRaw);

            if (tokenDid == null || !tokenDid.equals(headerDid)) {
                ErrorHttpWriter.write(req, res, ErrorCode.FORBIDDEN, "[AuthSvc-E07] token.did ≠ X-Device-Id");
                return;
            }
            // =====================================

            // 권한
            var authorities = extractAuthorities(claims);
            if (authorities.isEmpty()) {
                authorities = List.of(new SimpleGrantedAuthority("ROLE_USER"));
            }

            // principal = userUuid
            String userUuid = claims.getSubject();
            var auth = new UsernamePasswordAuthenticationToken(userUuid, null, authorities);
            SecurityContextHolder.getContext().setAuthentication(auth);

        } catch (Exception ex) {
            ErrorHttpWriter.write(req, res, ErrorCode.UNAUTHORIZED, "invalid token");
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