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
        String deviceId = DeviceIdResolver.normalize(req.getHeader("X-Device-Id"));
        if (deviceId == null || deviceId.isBlank()) {
            ErrorHttpWriter.write(req, res, ErrorCode.BAD_REQUEST,
                    "[DeviceSvc-E01] required header missing or empty: X-Device-Id");
            return;
        }
        chain.doFilter(req, res);
    }
}
