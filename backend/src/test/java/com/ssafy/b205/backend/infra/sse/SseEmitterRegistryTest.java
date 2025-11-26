package com.ssafy.b205.backend.infra.sse;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class SseEmitterRegistryTest {

    private final SseEmitterRegistry registry = new SseEmitterRegistry();

    @Test
    @DisplayName("디바이스 단위 create/get/remove 동작 및 onCompletion 클린업을 보장한다")
    void registerAndCleanup() throws IOException {
        UUID sessionId = UUID.randomUUID();
        String deviceId = "dev-1";

        SseEmitter emitter = registry.create(sessionId, deviceId, null);
        assertThat(registry.get(sessionId, deviceId)).isSameAs(emitter);

        emitter.complete();
        assertThat(registry.get(sessionId, deviceId)).isNull();
    }
}
