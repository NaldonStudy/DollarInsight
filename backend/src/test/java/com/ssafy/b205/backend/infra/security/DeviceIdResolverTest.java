package com.ssafy.b205.backend.infra.security;

import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class DeviceIdResolverTest {

    @Test
    void normalizeTrimsAndLimitsLength() {
        String trimmed = DeviceIdResolver.normalize("   device-01   ");
        assertThat(trimmed).isEqualTo("device-01");

        String longId = "x".repeat(300);
        String normalized = DeviceIdResolver.normalize(longId);
        assertThat(normalized.length()).isEqualTo(256);
        assertThat(normalized).isEqualTo(longId.substring(0, 256));
    }

    @Test
    void normalizeRejectsNullOrEmpty() {
        assertThatThrownBy(() -> DeviceIdResolver.normalize(null))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> DeviceIdResolver.normalize("   "))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void resolveValidOrNullReadsFromRequest() {
        MockHttpServletRequest req = new MockHttpServletRequest();
        req.addHeader("X-Device-Id", "   abc-def   ");
        assertThat(DeviceIdResolver.resolveValidOrNull(req)).isEqualTo("abc-def");

        req = new MockHttpServletRequest();
        req.addHeader("X-Device-Id", "   ");
        assertThat(DeviceIdResolver.resolveValidOrNull(req)).isNull();
    }
}
