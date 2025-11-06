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

    @Override
    protected boolean shouldNotFilter(HttpServletRequest req) {
        final String uri = req.getRequestURI();

        // CORS preflight
        if ("OPTIONS".equalsIgnoreCase(req.getMethod())) return true;

        // 공개/문서/헬스체크 등 제외
        if (uri.equals("/api/public") || uri.startsWith("/api/public/")) return true;
        if (uri.startsWith("/v3/api-docs")) return true;
        if (uri.startsWith("/swagger-ui")) return true;
        if (uri.equals("/swagger-ui.html")) return true;
        if (uri.startsWith("/actuator")) return true;

        // /api/** 만 검증
        return !uri.startsWith("/api/");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
            throws ServletException, IOException {

        String deviceId = DeviceIdResolver.resolveValidOrNull(req);
        if (deviceId == null) {
            ErrorHttpWriter.write(
                    req, res,
                    ErrorCode.BAD_REQUEST,
                    "[DeviceService-001] X-Device-Id 헤더가 누락되었거나 비어 있습니다."
            );
            return;
        }

        chain.doFilter(req, res);
    }
}
