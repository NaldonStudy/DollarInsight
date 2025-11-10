package com.ssafy.b205.backend.support.error;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.ssafy.b205.backend.support.response.ApiResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.MediaType;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

public final class ErrorHttpWriter {

    private static final ObjectMapper om = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    private ErrorHttpWriter() {}

    public static void write(HttpServletRequest req, HttpServletResponse res,
                             ErrorCode code, String message) throws IOException {

        if (res.isCommitted()) return;

        res.setStatus(code.status.value());
        res.setCharacterEncoding(StandardCharsets.UTF_8.name());
        res.setContentType(MediaType.APPLICATION_JSON_VALUE + ";charset=UTF-8");

        var body = ApiResponse.error(ApiError.of(code, message, req.getRequestURI()));
        res.getWriter().write(om.writeValueAsString(body));
        res.getWriter().flush();
    }
}
