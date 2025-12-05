package com.ssafy.b205.backend.infra.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ssafy.b205.backend.support.response.ApiResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import static org.assertj.core.api.Assertions.assertThat;

class JsonHandlersTest {

    private final ObjectMapper om = new ObjectMapper();

    @Test
    @DisplayName("AuthenticationEntryPoint는 401 JSON 에러를 반환한다")
    void entryPointWrites401() throws Exception {
        JsonAuthenticationEntryPoint entryPoint = new JsonAuthenticationEntryPoint();
        HttpServletRequest req = new MockHttpServletRequest("GET", "/secure");
        MockHttpServletResponse res = new MockHttpServletResponse();

        entryPoint.commence(req, res, new org.springframework.security.core.AuthenticationException("x") {});

        assertThat(res.getStatus()).isEqualTo(401);
        ApiResponse<?> api = om.readValue(res.getContentAsByteArray(), ApiResponse.class);
        assertThat(api.isOk()).isFalse();
    }

    @Test
    @DisplayName("AccessDeniedHandler는 403 JSON 에러를 반환한다")
    void accessDeniedWrites403() throws Exception {
        JsonAccessDeniedHandler handler = new JsonAccessDeniedHandler();
        HttpServletRequest req = new MockHttpServletRequest("GET", "/secure");
        MockHttpServletResponse res = new MockHttpServletResponse();

        handler.handle(req, res, new org.springframework.security.access.AccessDeniedException("nope"));

        assertThat(res.getStatus()).isEqualTo(403);
        ApiResponse<?> api = om.readValue(res.getContentAsByteArray(), ApiResponse.class);
        assertThat(api.isOk()).isFalse();
    }
}
