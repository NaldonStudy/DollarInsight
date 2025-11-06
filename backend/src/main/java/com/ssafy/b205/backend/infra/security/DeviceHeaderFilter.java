package com.ssafy.b205.backend.infra.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

@Component
public class DeviceHeaderFilter extends OncePerRequestFilter {

    @Override
    protected boolean shouldNotFilter(HttpServletRequest req) {
        final String uri = req.getRequestURI();
        if ("OPTIONS".equalsIgnoreCase(req.getMethod())) return true;          // preflight
        if (uri.equals("/api/public") || uri.startsWith("/api/public/")) return true;
        if (uri.startsWith("/v3/api-docs")) return true;
        if (uri.startsWith("/swagger-ui")) return true;
        if (uri.startsWith("/actuator")) return true;
        return !uri.startsWith("/api/"); // /api/** 만 검증
    }

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
            throws ServletException, IOException {

        // 한글 깨짐 방지
        res.setCharacterEncoding(StandardCharsets.UTF_8.name());
        res.setContentType("application/json;charset=UTF-8");

        String deviceId = DeviceIdResolver.resolveValidOrNull(req);
        if (deviceId == null) {
            res.setStatus(HttpStatus.BAD_REQUEST.value());
            res.getWriter().write(
                    "{ \"success\": false, " +
                            "\"message\": \"[DeviceService-001] X-Device-Id 헤더가 누락되었거나 비어 있습니다.\"," +
                            "\"data\": null }"
            );
            return;
        }
        chain.doFilter(req, res);
    }
}
