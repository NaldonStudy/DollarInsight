package com.ssafy.b205.backend.infra.security;

import com.ssafy.b205.backend.support.error.ErrorCode;
import com.ssafy.b205.backend.support.error.ErrorHttpWriter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
public class DeviceHeaderFilter extends OncePerRequestFilter {

    private static String normalizedPath(HttpServletRequest req) {
        String uri = req.getRequestURI();    // 예: /api//swagger-ui/index.html
        String ctx = req.getContextPath();   // 예: /api
        String p = (ctx != null && !ctx.isEmpty() && uri.startsWith(ctx))
                ? uri.substring(ctx.length()) // => //swagger-ui/index.html
                : uri;
        return p.replaceAll("/{2,}", "/");   // => /swagger-ui/index.html
    }

    private static boolean isWhitelisted(String path) {
        if (path.equals("/error")) return true;

        // Swagger / OpenAPI
        if (path.startsWith("/v3/api-docs") || path.startsWith("/swagger-ui") || path.equals("/swagger-ui.html")) return true;
        if (path.startsWith("/api/v3/api-docs") || path.startsWith("/api/swagger-ui") || path.equals("/api/swagger-ui.html")) return true;

        // Actuator
        if (path.startsWith("/actuator") || path.startsWith("/api/actuator")) return true;

        // Public
        if (path.equals("/public") || path.startsWith("/public/")) return true;
        if (path.equals("/api/public") || path.startsWith("/api/public/")) return true;

        // Auth (로그인/회원가입/재발급은 헤더/토큰 검사 면제)
        if (path.equals("/auth/login") || path.equals("/auth/signup") || path.equals("/auth/refresh")) return true;
        if (path.equals("/api/auth/login") || path.equals("/api/auth/signup") || path.equals("/api/auth/refresh")) return true;

        // OAuth
        if (path.startsWith("/api/auth/oauth/")) return true;

        // (운영에서 자주 오는 정적 리퀘스트)
        if (path.equals("/favicon.ico") || path.equals("/robots.txt")) return true;
        if (path.equals("/api/favicon.ico") || path.equals("/api/robots.txt")) return true;

        return false;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest req) {
        if ("OPTIONS".equalsIgnoreCase(req.getMethod())) return true;
        String path = normalizedPath(req);
        return isWhitelisted(path);
    }

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
            throws ServletException, IOException {

        // 🔒 null-safe: normalize 이전에 헤더 존재/공백 체크
        String raw = req.getHeader("X-Device-Id");
        if (raw == null || raw.isBlank()) {
            ErrorHttpWriter.write(req, res, ErrorCode.BAD_REQUEST,
                    "[DeviceSvc-E01] required header missing or empty: X-Device-Id");
            return;
        }

        // 여기서부터는 null 아님이 보장됨
        String deviceId = DeviceIdResolver.normalize(raw);

        // (선택) 정규화된 값을 다시 헤더에 덮어써두면 뒤 필터에서 동일 규칙 사용 가능
        // req.setAttribute("X-Device-Id-Normalized", deviceId);

        chain.doFilter(req, res);
    }
}
