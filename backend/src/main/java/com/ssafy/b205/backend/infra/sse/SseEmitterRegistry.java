package com.ssafy.b205.backend.infra.sse;

import org.springframework.stereotype.Component;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class SseEmitterRegistry {

    private final Map<UUID, SseEmitter> emitters = new ConcurrentHashMap<>();

    public SseEmitter register(UUID sessionUuid) {
        SseEmitter emitter = new SseEmitter(0L);
        emitters.put(sessionUuid, emitter);
        emitter.onCompletion(() -> emitters.remove(sessionUuid));
        emitter.onTimeout(() -> emitters.remove(sessionUuid));
        emitter.onError(e -> emitters.remove(sessionUuid));
        return emitter;
    }

    public SseEmitter get(UUID sessionUuid) {
        return emitters.get(sessionUuid);
    }

    public void remove(UUID sessionUuid) {
        emitters.remove(sessionUuid);
    }
}
