package com.ssafy.b205.backend.infra.security;

import com.ssafy.b205.backend.support.error.ErrorCode;
import com.ssafy.b205.backend.support.error.ErrorHttpWriter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.web.access.AccessDeniedHandler;
import java.io.IOException;

public class JsonAccessDeniedHandler implements AccessDeniedHandler {
    @Override
    public void handle(HttpServletRequest req, HttpServletResponse res,
                       org.springframework.security.access.AccessDeniedException ex) throws IOException {
        ErrorHttpWriter.write(req, res, ErrorCode.FORBIDDEN, "접근 권한이 없습니다.");
    }
}
