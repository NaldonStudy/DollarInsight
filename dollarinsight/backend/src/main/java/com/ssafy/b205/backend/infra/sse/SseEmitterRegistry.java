// src/main/java/com/ssafy/b205/backend/infra/sse/SseEmitterRegistry.java
package com.ssafy.b205.backend.infra.sse;

import org.springframework.stereotype.Component;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class SseEmitterRegistry {

    private static final long DEFAULT_TIMEOUT_MS = 30L * 60 * 1000; // 30분
    private final Map<String, SseEmitter> emitters = new ConcurrentHashMap<>();

    private static String key(UUID sessionUuid, String deviceId) {
        return sessionUuid + "|" + deviceId;
    }

    /** 기존 단일키 등록 */
    public SseEmitter register(UUID sessionUuid) {
        SseEmitter emitter = new SseEmitter(DEFAULT_TIMEOUT_MS);
        emitters.put(sessionUuid.toString(), emitter);
        emitter.onCompletion(() -> emitters.remove(sessionUuid.toString()));
        emitter.onTimeout(() -> emitters.remove(sessionUuid.toString()));
        emitter.onError(e -> emitters.remove(sessionUuid.toString()));
        return emitter;
    }

    /** ✅ 디바이스 단위 다중 등록 + (옵션) lastEventId */
    public SseEmitter create(UUID sessionUuid, String deviceId, String lastEventId) {
        String k = key(sessionUuid, deviceId);
        SseEmitter emitter = new SseEmitter(DEFAULT_TIMEOUT_MS);
        emitters.put(k, emitter);
        emitter.onCompletion(() -> emitters.remove(k));
        emitter.onTimeout(() -> emitters.remove(k));
        emitter.onError(e -> emitters.remove(k));
        // 여기서 lastEventId 기반 replay 로직을 붙일 수 있음(현재는 패스)
        return emitter;
    }

    public SseEmitter get(UUID sessionUuid, String deviceId) {
        return emitters.get(key(sessionUuid, deviceId));
    }

    public void remove(UUID sessionUuid, String deviceId) {
        emitters.remove(key(sessionUuid, deviceId));
    }
}
