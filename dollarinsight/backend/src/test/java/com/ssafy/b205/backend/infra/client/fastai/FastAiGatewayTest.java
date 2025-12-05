package com.ssafy.b205.backend.infra.client.fastai;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import okhttp3.mockwebserver.MockResponse;
import okhttp3.mockwebserver.MockWebServer;
import okhttp3.mockwebserver.RecordedRequest;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.http.codec.ServerSentEvent;
import org.springframework.web.reactive.function.client.WebClient;

import java.io.IOException;
import java.time.Duration;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class FastAiGatewayTest {

    private MockWebServer server;
    private FastAiGateway gateway;
    private final ObjectMapper mapper = new ObjectMapper();

    @BeforeEach
    void setUp() throws IOException {
        server = new MockWebServer();
        server.start();
        WebClient client = WebClient.builder()
                .baseUrl(server.url("/").toString())
                .build();
        gateway = new FastAiGateway(client);
    }

    @AfterEach
    void tearDown() throws IOException {
        server.shutdown();
    }

    @Test
    void start_shouldPostJsonAndParseResponse() throws Exception {
        String body = """
                {"ok":true,"session_id":"sid-1","pace_ms":2500,"active_agents":["a","b"]}
                """;
        server.enqueue(new MockResponse()
                .setHeader("Content-Type", MediaType.APPLICATION_JSON_VALUE)
                .setBody(body));

        FastAiGateway.MonoStartResponse res = gateway.start("sid-1", "hello", 2500, List.of("a", "b"));

        RecordedRequest req = server.takeRequest();
        assertEquals("/start", req.getPath());
        JsonNode json = mapper.readTree(req.getBody().readUtf8());
        assertEquals("sid-1", json.get("session_id").asText());
        assertEquals("hello", json.get("user_input").asText());
        assertEquals(2500, json.get("pace_ms").asInt());
        assertEquals(List.of("a", "b"), mapper.convertValue(json.get("personas"), List.class));

        assertTrue(res.ok);
        assertEquals("sid-1", res.session_id);
        assertEquals(2500, res.pace_ms);
        assertEquals(List.of("a", "b"), res.active_agents);
    }

    @Test
    void control_shouldPostActionWithoutPaceWhenNull() throws Exception {
        server.enqueue(new MockResponse().setResponseCode(204));

        gateway.control("sid-ctrl", "STOP", null);

        RecordedRequest req = server.takeRequest();
        assertEquals("/control", req.getPath());
        JsonNode json = mapper.readTree(req.getBody().readUtf8());
        assertEquals("sid-ctrl", json.get("session_id").asText());
        assertEquals("STOP", json.get("action").asText());
        assertNull(json.get("pace_ms"));
    }

    @Test
    void stream_shouldConsumeSseEvents() throws Exception {
        String sseBody = "id: 1\n" +
                "event: message\n" +
                "data: hello\n\n";
        server.enqueue(new MockResponse()
                .setHeader("Content-Type", MediaType.TEXT_EVENT_STREAM_VALUE)
                .setBody(sseBody));

        ServerSentEvent<String> event = gateway.stream("sid-stream")
                .blockFirst(Duration.ofSeconds(1));

        RecordedRequest req = server.takeRequest();
        assertEquals("/stream?session_id=sid-stream", req.getPath());
        assertNotNull(event);
        assertEquals("message", event.event());
        assertEquals("1", event.id());
        assertEquals("hello", event.data());
    }
}
