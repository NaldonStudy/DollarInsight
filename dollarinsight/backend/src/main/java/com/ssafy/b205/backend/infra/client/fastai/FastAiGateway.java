package com.ssafy.b205.backend.infra.client.fastai;

import lombok.RequiredArgsConstructor;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.MediaType;
import org.springframework.http.codec.ServerSentEvent;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Flux;

import java.util.List;
import java.util.Map;

@Component
@RequiredArgsConstructor
public class FastAiGateway {

    private final WebClient fastAiWebClient;
    private final ParameterizedTypeReference<ServerSentEvent<String>> sseType = new ParameterizedTypeReference<>() {};

    public MonoStartResponse start(String sessionId, String userInput, Integer paceMs, List<String> personas) {
        Map<String, Object> body = Map.of(
                "session_id", sessionId,
                "user_input", userInput,
                "pace_ms", paceMs == null ? 3000 : paceMs,
                "personas", personas
        );
        return fastAiWebClient.post()
                .uri("/start")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(body)
                .retrieve()
                .bodyToMono(MonoStartResponse.class)
                .block();
    }

    public void sendUserInput(String sessionId, String userInput) {
        Map<String, Object> body = Map.of(
                "session_id", sessionId,
                "user_input", userInput
        );
        fastAiWebClient.post()
                .uri("/input")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(body)
                .retrieve()
                .toBodilessEntity().block();
    }

    public void control(String sessionId, String action, Integer paceMs) {
        Map<String, Object> body = paceMs == null
                ? Map.of("session_id", sessionId, "action", action)
                : Map.of("session_id", sessionId, "action", action, "pace_ms", paceMs);

        fastAiWebClient.post()
                .uri("/control")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(body)
                .retrieve()
                .toBodilessEntity().block();
    }

    public Flux<ServerSentEvent<String>> stream(String sessionId) {
        return fastAiWebClient.get()
                .uri(uriBuilder -> uriBuilder.path("/stream")
                        .queryParam("session_id", sessionId)
                        .build())
                .accept(MediaType.TEXT_EVENT_STREAM)
                .retrieve()
                .bodyToFlux(sseType);
    }

    // 최소 응답 DTO
    public static class MonoStartResponse {
        public boolean ok;
        public String session_id;
        public Integer pace_ms;
        public List<String> active_agents;
    }
}
