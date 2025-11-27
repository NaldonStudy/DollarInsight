package com.ssafy.b205.backend.domain.chat.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ssafy.b205.backend.domain.chat.dto.request.AppendMessageRequest;
import com.ssafy.b205.backend.domain.chat.dto.request.CreateSessionRequest;
import com.ssafy.b205.backend.domain.chat.dto.request.ChangePaceRequest;
import com.ssafy.b205.backend.domain.chat.dto.response.AppendMessageResponse;
import com.ssafy.b205.backend.domain.chat.dto.response.CreateSessionResponse;
import com.ssafy.b205.backend.domain.chat.dto.response.HistoryCursorResponse;
import com.ssafy.b205.backend.domain.chat.dto.response.HistoryResponse;
import com.ssafy.b205.backend.domain.chat.service.ChatService;
import com.ssafy.b205.backend.support.response.ApiResponse;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = ChatController.class)
@AutoConfigureMockMvc(addFilters = false) // 보안 필터 제외하고 단순 매핑/바인딩 검증
@org.springframework.context.annotation.Import(com.ssafy.b205.backend.support.error.GlobalExceptionHandler.class)
class ChatControllerTest {

    @Autowired
    MockMvc mvc;

    @Autowired
    ObjectMapper objectMapper;

    @MockBean
    ChatService chatService;

    @Test
    @DisplayName("세션 생성 요청을 받으면 ChatService로 위임하고 ApiResponse를 반환한다")
    void createSession() throws Exception {
        UUID sessionId = UUID.randomUUID();
        CreateSessionResponse res = new CreateSessionResponse(sessionId, List.of("A", "B"), Instant.parse("2025-01-01T00:00:00Z"));
        when(chatService.createSession(eq("user-123"), any(CreateSessionRequest.class))).thenReturn(res);

        String body = """
                { "topicType": "CUSTOM", "title": "테스트 세션" }
                """;

        mvc.perform(post("/api/chat/sessions")
                        .with(user("user-123"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(result -> {
                    ApiResponse<?> api = objectMapper.readValue(result.getResponse().getContentAsByteArray(), ApiResponse.class);
                    assertThat(api.isOk()).isTrue();
                });

        ArgumentCaptor<CreateSessionRequest> captor = ArgumentCaptor.forClass(CreateSessionRequest.class);
        verify(chatService).createSession(eq("user-123"), captor.capture());
        assertThat(captor.getValue().getTitle()).isEqualTo("테스트 세션");
    }

    @Test
    @DisplayName("사용자 메시지 등록 요청을 위임하고 응답을 감싼다")
    void appendMessage() throws Exception {
        UUID sessionId = UUID.randomUUID();
        when(chatService.appendUserMessage(eq("user-123"), eq(sessionId), any(AppendMessageRequest.class)))
                .thenReturn(new AppendMessageResponse("msg-1"));

        String body = """
                { "content": "hello" }
                """;

        mvc.perform(post("/api/chat/sessions/{sid}/messages", sessionId)
                        .with(user("user-123"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON));
    }

    @Test
    @DisplayName("세션 삭제 요청은 204를 반환한다")
    void deleteSession() throws Exception {
        UUID sessionId = UUID.randomUUID();

        mvc.perform(delete("/api/chat/sessions/{sid}", sessionId)
                        .with(user("user-123")))
                .andExpect(status().isNoContent());

        verify(chatService).deleteSession("user-123", sessionId);
    }

    @Test
    @DisplayName("발화 간격 변경 요청은 ChatService.changePace를 호출한다")
    void changePace() throws Exception {
        UUID sessionId = UUID.randomUUID();
        String body = """
                { "paceMs": 1500 }
                """;

        mvc.perform(post("/api/chat/sessions/{sid}/control/pace", sessionId)
                        .with(user("user-123"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isNoContent());

        verify(chatService).changePace("user-123", sessionId, 1500);
    }

    @Test
    @DisplayName("SSE 스트림 엔드포인트는 SseEmitter를 반환한다")
    void stream() throws Exception {
        UUID sessionId = UUID.randomUUID();
        SseEmitter emitter = new SseEmitter(0L);
        emitter.complete();
        when(chatService.streamAssistant(eq("user-123"), eq(sessionId), any(), any())).thenReturn(emitter);

        mvc.perform(get("/api/chat/sessions/{sid}/stream", sessionId)
                        .with(user("user-123"))
                        .accept(MediaType.TEXT_EVENT_STREAM))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.TEXT_EVENT_STREAM));
    }

    @Test
    @DisplayName("히스토리 조회는 서비스 결과를 ApiResponse에 감싸서 반환한다")
    void history() throws Exception {
        UUID sessionId = UUID.randomUUID();
        when(chatService.history(eq("user-123"), eq(sessionId), eq(50)))
                .thenReturn(new HistoryResponse(List.of()));

        mvc.perform(get("/api/chat/sessions/{sid}/history", sessionId)
                        .with(user("user-123"))
                        .param("limit", "50"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON));
    }

    @Test
    @DisplayName("커서 기반 히스토리 조회는 nextCursor와 hasMore를 포함해 반환한다")
    void history2() throws Exception {
        UUID sessionId = UUID.randomUUID();
        HistoryCursorResponse mock = new HistoryCursorResponse(List.of(), "next123", true);
        when(chatService.history2(eq("user-123"), eq(sessionId), eq(20), eq("cursor-1")))
                .thenReturn(mock);

        mvc.perform(get("/api/chat/sessions/{sid}/history2", sessionId)
                        .with(user("user-123"))
                        .param("limit", "20")
                        .param("cursor", "cursor-1"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(result -> {
                    ApiResponse<?> api = objectMapper.readValue(result.getResponse().getContentAsByteArray(), ApiResponse.class);
                    assertThat(api.isOk()).isTrue();
                });
    }

    @Test
    @DisplayName("서비스에서 AppException을 던지면 GlobalExceptionHandler가 JSON 에러를 반환한다")
    void appExceptionHandled() throws Exception {
        when(chatService.listSessions(eq("user-123"), anyInt(), anyInt()))
                .thenThrow(new com.ssafy.b205.backend.support.error.AppException(
                        com.ssafy.b205.backend.support.error.ErrorCode.FORBIDDEN, "forbidden"
                ));

        mvc.perform(get("/api/chat/sessions")
                        .with(user("user-123")))
                .andExpect(status().isForbidden())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(result -> {
                    ApiResponse<?> api = objectMapper.readValue(result.getResponse().getContentAsByteArray(), ApiResponse.class);
                    assertThat(api.isOk()).isFalse();
                });
    }
}
