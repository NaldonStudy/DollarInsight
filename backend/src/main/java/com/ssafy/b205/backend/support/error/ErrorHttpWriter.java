package com.ssafy.b205.backend.support.error;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ssafy.b205.backend.support.response.ApiResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

public class ErrorHttpWriter {
    private static final ObjectMapper om = new ObjectMapper();

    public static void write(HttpServletRequest req, HttpServletResponse res,
                             ErrorCode code, String message) throws IOException {
        res.setStatus(code.status.value());
        res.setCharacterEncoding(StandardCharsets.UTF_8.name());
        res.setContentType("application/json;charset=UTF-8");

        var body = ApiResponse.error(ApiError.of(code, message, req.getRequestURI()));
        res.getWriter().write(om.writeValueAsString(body));
    }
}
