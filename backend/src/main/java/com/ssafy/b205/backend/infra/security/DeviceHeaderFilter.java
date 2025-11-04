package com.ssafy.b205.backend.infra.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;

@Component
public class DeviceHeaderFilter extends OncePerRequestFilter {

    @Override
    protected boolean shouldNotFilter(HttpServletRequest req) {
        String p = req.getRequestURI();
        if (p.startsWith("/api/auth/signup")) return true; // 가입만 예외
        if (p.startsWith("/v3/api-docs") || p.startsWith("/swagger-ui") || p.startsWith("/actuator/health")) return true;
        return !p.startsWith("/api/"); // /api/** 에만 적용
    }

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
            throws ServletException, IOException {
        String deviceId = DeviceIdResolver.resolveValidOrNull(req);
        if (deviceId == null) {
            res.setStatus(HttpStatus.BAD_REQUEST.value());
            res.setContentType("application/json");
            res.getWriter().write(
                    "{ \"success\": false, " +
                            "\"message\": \"[DeviceService - 001] deviceId 헤더가 누락되었거나 형식이 유효하지 않습니다.\"," +
                            "\"data\": null }"
            );
            return;
        }
        chain.doFilter(req, res);
    }
}
