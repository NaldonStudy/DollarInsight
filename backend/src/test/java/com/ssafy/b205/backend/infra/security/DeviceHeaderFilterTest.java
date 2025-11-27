package com.ssafy.b205.backend.infra.security;

import com.ssafy.b205.backend.support.error.ErrorCode;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import java.io.IOException;

import static org.assertj.core.api.Assertions.assertThat;

class DeviceHeaderFilterTest {

    private final DeviceHeaderFilter filter = new DeviceHeaderFilter();

    private static final class CountingChain extends MockFilterChain {
        int count = 0;
        @Override
        public void doFilter(ServletRequest request, ServletResponse response) throws IOException, ServletException {
            count++;
            super.doFilter(request, response);
        }
    }

    @Test
    @DisplayName("X-Device-Id 없으면 400을 응답하고 체인을 진행하지 않는다")
    void missingDeviceHeader() throws Exception {
        MockHttpServletRequest req = new MockHttpServletRequest("GET", "/api/chat/sessions");
        MockHttpServletResponse res = new MockHttpServletResponse();
        CountingChain chain = new CountingChain();

        filter.doFilter(req, res, chain);

        assertThat(res.getStatus()).isEqualTo(ErrorCode.BAD_REQUEST.status.value());
        assertThat(chain.count).isZero();
    }

    @Test
    @DisplayName("화이트리스트 경로는 헤더 없이 통과한다")
    void whitelistedPath() throws Exception {
        MockHttpServletRequest req = new MockHttpServletRequest("GET", "/api/auth/login");
        MockHttpServletResponse res = new MockHttpServletResponse();
        CountingChain chain = new CountingChain();

        filter.doFilter(req, res, chain);

        assertThat(chain.count).isEqualTo(1);
        assertThat(res.getStatus()).isEqualTo(200);
    }

    @Test
    @DisplayName("정상 헤더가 있으면 체인을 진행한다")
    void hasDeviceHeader() throws Exception {
        MockHttpServletRequest req = new MockHttpServletRequest("GET", "/api/chat/sessions");
        req.addHeader("X-Device-Id", "1111-2222-3333-4444");
        MockHttpServletResponse res = new MockHttpServletResponse();
        CountingChain chain = new CountingChain();

        filter.doFilter(req, res, chain);

        assertThat(chain.count).isEqualTo(1);
        assertThat(res.getStatus()).isEqualTo(200);
    }
}
