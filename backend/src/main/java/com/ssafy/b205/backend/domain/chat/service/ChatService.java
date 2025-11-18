package com.ssafy.b205.backend.domain.chat.service;

import com.ssafy.b205.backend.domain.chat.dto.request.AppendMessageRequest;
import com.ssafy.b205.backend.domain.chat.dto.request.CreateSessionRequest;
import com.ssafy.b205.backend.domain.chat.dto.response.AppendMessageResponse;
import com.ssafy.b205.backend.domain.chat.dto.response.ChatSessionSummaryResponse;
import com.ssafy.b205.backend.domain.chat.dto.response.CreateSessionResponse;
import com.ssafy.b205.backend.domain.chat.dto.response.HistoryCursorResponse;
import com.ssafy.b205.backend.domain.chat.dto.response.HistoryResponse;
import com.ssafy.b205.backend.support.response.PageResponse;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.UUID;

public interface ChatService {
    CreateSessionResponse createSession(String userUuid, CreateSessionRequest req);
    PageResponse<ChatSessionSummaryResponse> listSessions(String userUuid, int page, int size);
    void deleteSession(String userUuid, UUID sessionUuid);
    AppendMessageResponse appendUserMessage(String userUuid, UUID sessionUuid, AppendMessageRequest req);
    SseEmitter streamAssistant(String userUuid, UUID sessionUuid, String deviceId, String lastEventId);
    void interrupt(String userUuid, UUID sessionUuid);
    HistoryResponse history(String userUuid, UUID sessionUuid, int limit);
    HistoryCursorResponse history2(String userUuid, java.util.UUID sessionUuid, int limit, String cursorId);
    void resume(String userUuid, UUID sessionUuid);
    void changePace(String userUuid, UUID sessionUuid, int paceMs);
}
