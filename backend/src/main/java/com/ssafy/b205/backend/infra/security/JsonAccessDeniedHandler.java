package com.ssafy.b205.backend.infra.security;

import com.ssafy.b205.backend.support.error.ErrorCode;
import com.ssafy.b205.backend.support.error.ErrorHttpWriter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.web.access.AccessDeniedHandler;
import java.io.IOException;

public class JsonAccessDeniedHandler implements AccessDeniedHandler {
    private static final Logger log = LoggerFactory.getLogger(JsonAccessDeniedHandler.class);

    @Override
    public void handle(HttpServletRequest req, HttpServletResponse res,
                       org.springframework.security.access.AccessDeniedException ex) throws IOException {
        // SSE 스트림 등 이미 응답이 시작된 경우 무시
        if (res.isCommitted()) {
            log.debug("[Security] Access denied but response already committed: {}", req.getRequestURI());
            return;
        }
        ErrorHttpWriter.write(req, res, ErrorCode.FORBIDDEN, "접근 권한이 없습니다.");
    }
}
