package com.ssafy.b205.backend.domain.chat.service;

import com.ssafy.b205.backend.domain.chat.dto.request.AppendMessageRequest;
import com.ssafy.b205.backend.domain.chat.dto.request.CreateSessionRequest;
import com.ssafy.b205.backend.domain.chat.dto.response.AppendMessageResponse;
import com.ssafy.b205.backend.domain.chat.dto.response.CreateSessionResponse;
import com.ssafy.b205.backend.domain.chat.dto.response.HistoryResponse;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.UUID;

public interface ChatService {
    CreateSessionResponse createSession(Integer userId, CreateSessionRequest req);
    AppendMessageResponse appendUserMessage(Integer userId, UUID sessionUuid, AppendMessageRequest req);
    SseEmitter streamAssistant(Integer userId, UUID sessionUuid, String deviceId, String lastEventId);
    void interrupt(Integer userId, UUID sessionUuid);
    HistoryResponse history(Integer userId, UUID sessionUuid, int limit);
    void resume(Integer userId, UUID sessionUuid);
    void changePace(Integer userId, UUID sessionUuid, int paceMs);
}
