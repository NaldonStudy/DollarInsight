package com.ssafy.b205.backend.infra.security;

import com.ssafy.b205.backend.support.error.ErrorCode;
import com.ssafy.b205.backend.support.error.ErrorHttpWriter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.web.AuthenticationEntryPoint;
import java.io.IOException;

public class JsonAuthenticationEntryPoint implements AuthenticationEntryPoint {
    private static final Logger log = LoggerFactory.getLogger(JsonAuthenticationEntryPoint.class);

    @Override
    public void commence(HttpServletRequest req, HttpServletResponse res,
                         org.springframework.security.core.AuthenticationException ex) throws IOException {
        // SSE 스트림 등 이미 응답이 시작된 경우 무시
        if (res.isCommitted()) {
            log.debug("[Security] Authentication required but response already committed: {}", req.getRequestURI());
            return;
        }
        ErrorHttpWriter.write(req, res, ErrorCode.UNAUTHORIZED, "인증이 필요합니다.");
    }
}
