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

        // 1) CORS preflight는 항상 통과
        if ("OPTIONS".equalsIgnoreCase(req.getMethod())) return true;

        // 2) 공개/문서/헬스체크 경로 화이트리스트
        if (uri.equals("/api/public") || uri.startsWith("/api/public/")) return true;
        if (uri.startsWith("/api/auth/signup")) return true;                // 가입만 예외 (기존 로직 유지)
        if (uri.startsWith("/v3/api-docs") || uri.startsWith("/swagger-ui")) return true;
        if (uri.startsWith("/actuator")) return true;                       // /actuator/health 포함

        // 3) /api/** 에만 필터 적용 (그 외는 패스)
        return !uri.startsWith("/api/");
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
                            "\"message\": \"[DeviceService-001] X-Device-Id 헤더가 누락되었거나 형식이 유효하지 않습니다.\"," +
                            "\"data\": null }"
            );
            return;
        }
        chain.doFilter(req, res);
    }
}
