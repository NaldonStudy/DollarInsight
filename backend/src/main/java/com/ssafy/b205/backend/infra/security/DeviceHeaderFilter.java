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
        String uri = req.getRequestURI();         // 예: /api/swagger-ui/index.html
        String ctx = req.getContextPath();        // 예: /api
        return (ctx != null && !ctx.isEmpty() && uri.startsWith(ctx))
                ? uri.substring(ctx.length())     // 예: /swagger-ui/index.html
                : uri;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest req) {
        if ("OPTIONS".equalsIgnoreCase(req.getMethod())) return true;

        String path = normalizedPath(req);
        // Swagger & OpenAPI & Actuator는 무조건 면제
        if (path.startsWith("/v3/api-docs")) return true;
        if (path.startsWith("/swagger-ui")) return true;
        if (path.equals("/swagger-ui.html")) return true;
        if (path.startsWith("/actuator")) return true;
        // 공개 엔드포인트 면제
        if (path.equals("/public") || path.startsWith("/public/")) return true;

        // 그 외는 전부 검사 (컨텍스트 경로 유무와 무관)
        return false;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
            throws ServletException, IOException {
        String deviceId = DeviceIdResolver.resolveValidOrNull(req);
        if (deviceId == null) {
            ErrorHttpWriter.write(req, res, ErrorCode.BAD_REQUEST,
                    "[DeviceService-001] X-Device-Id 헤더가 누락되었거나 비어 있습니다.");
            return;
        }
        chain.doFilter(req, res);
    }
}
