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
        // 연속 슬래시 압축
        return p.replaceAll("/{2,}", "/");   // => /swagger-ui/index.html
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest req) {
        if ("OPTIONS".equalsIgnoreCase(req.getMethod())) return true;

        String path = normalizedPath(req);
        if (path.equals("/error")) return true;           // ✅ error 디스패치 면제
        if (path.startsWith("/v3/api-docs")) return true;
        if (path.startsWith("/swagger-ui")) return true;
        if (path.equals("/swagger-ui.html")) return true;
        if (path.startsWith("/actuator")) return true;
        // 공개 엔드포인트 면제 (컨텍스트를 뺀 경로 기준)
        if (path.equals("/public") || path.startsWith("/public/")) return true;

        return false;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
            throws ServletException, IOException {
        String deviceId = com.ssafy.b205.backend.infra.security.DeviceIdResolver.normalize(
                req.getHeader("X-Device-Id")
        ); // ← 존재만 확인 + 동일 규칙으로 정규화
        if (deviceId == null || deviceId.isBlank()) {
            ErrorHttpWriter.write(req, res, ErrorCode.BAD_REQUEST,
                    "[DeviceSvc-E01] required header missing or empty: X-Device-Id");
            return;
        }
        chain.doFilter(req, res);
    }

}
