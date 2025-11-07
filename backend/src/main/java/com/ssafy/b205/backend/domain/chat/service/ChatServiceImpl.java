package com.ssafy.b205.backend.domain.chat.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ssafy.b205.backend.domain.chat.dto.request.AppendMessageRequest;
import com.ssafy.b205.backend.domain.chat.dto.request.CreateSessionRequest;
import com.ssafy.b205.backend.domain.chat.dto.response.AppendMessageResponse;
import com.ssafy.b205.backend.domain.chat.dto.response.CreateSessionResponse;
import com.ssafy.b205.backend.domain.chat.dto.response.HistoryItem;
import com.ssafy.b205.backend.domain.chat.dto.response.HistoryResponse;
import com.ssafy.b205.backend.domain.chat.entity.ChatSession;
import com.ssafy.b205.backend.domain.chat.entity.ChatSessionPersona;
import com.ssafy.b205.backend.domain.chat.entity.ChatTopicType;
import com.ssafy.b205.backend.domain.chat.repository.ChatSessionPersonaRepository;
import com.ssafy.b205.backend.domain.chat.repository.ChatSessionRepository;
import com.ssafy.b205.backend.domain.persona.entity.Persona;
import com.ssafy.b205.backend.domain.persona.repository.PersonaRepository;
import com.ssafy.b205.backend.infra.client.fastai.FastAiGateway;
import com.ssafy.b205.backend.infra.mongo.chat.ChatMessageDoc;
import com.ssafy.b205.backend.infra.mongo.chat.ChatMessageRepository;
import com.ssafy.b205.backend.infra.sse.SseEmitterRegistry;
import com.ssafy.b205.backend.support.error.AppException;
import com.ssafy.b205.backend.support.error.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.codec.ServerSentEvent;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;
import reactor.core.Disposable;

import java.io.IOException;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicLong;

@Slf4j
@Service
@RequiredArgsConstructor
public class ChatServiceImpl implements ChatService {

    private static final int REPLAY_LIMIT = 20;

    private static final String E02_SESSION_NOT_FOUND = "[ChatSvc-E02] 세션 없음";
    private static final String E03_FORBIDDEN         = "[ChatSvc-E03] 세션 소유자 불일치";
    private static final String E04_PIPE_ERROR        = "[ChatSvc-E04] FastAPI 파이프 오류";
    private static final String E05_INTERRUPT_FAIL    = "[ChatSvc-E05] 중단 실패(전달오류)";

    private final ChatSessionRepository sessionRepo;
    private final ChatSessionPersonaRepository cspRepo;
    private final ChatMessageRepository msgRepo;
    private final PersonaRepository personaRepo;
    private final FastAiGateway gateway;
    private final SseEmitterRegistry emitterRegistry;
    private final ObjectMapper objectMapper;

    // ==================== Session ====================
    @Override
    @Transactional
    public CreateSessionResponse createSession(Integer userId, CreateSessionRequest req) {
        // 1) 활성 페르소나 전체 조회 (영문 코드)
        var enabled = personaRepo.findEnabledByUserId(userId);
        if (enabled.isEmpty()) throw new AppException(ErrorCode.BAD_REQUEST, "활성화된 페르소나가 없습니다.");
        var personaCodes = enabled.stream().map(Persona::getCode).toList();

        if (req.getTopicType() == ChatTopicType.COMPANY && (req.getTicker() == null || req.getTicker().isBlank())) {
            throw new AppException(ErrorCode.BAD_REQUEST, "COMPANY 세션에는 ticker가 필요합니다.");
        }

        // 2) 세션 생성
        var session = ChatSession.create(
                userId,
                req.getTopicType(),
                req.getTitle(),
                req.getTicker(),
                req.getCompanyNewsId()
        );
        sessionRepo.save(session);

        // 3) 세션↔페르소나 매핑 저장 (트리거가 enabled 검증)
        cspRepo.saveAll(
                enabled.stream()
                        .map(p -> ChatSessionPersona.of(session.getId(), p.getId()))
                        .toList()
        );

        log.info("[ChatSvc-02] 세션 생성 완료 uuid={}, personas={}", session.getUuid(), personaCodes);
        return new CreateSessionResponse(session.getUuid(), personaCodes, session.getCreatedAt());
    }

    @Override
    public AppendMessageResponse appendUserMessage(Integer userId, UUID sessionUuid, AppendMessageRequest req) {
        var session = loadOwnedSession(userId, sessionUuid);

        var saved = msgRepo.save(ChatMessageDoc.builder()
                .sessionUuid(sessionUuid)
                .role("user")
                .content(req.getContent())
                .seq(System.nanoTime())
                .ts(Instant.now())
                .build());

        long userMsgCount = msgRepo.countBySessionUuidAndRole(sessionUuid, "user");

        if (userMsgCount <= 1) {
            // 세션 생성 시 스냅샷한 페르소나 목록으로 /start
            var personaIds = cspRepo.findPersonaIdsBySessionId(session.getId());
            if (personaIds.isEmpty()) throw new AppException(ErrorCode.BAD_REQUEST, "세션의 페르소나 매핑이 없습니다.");

            // 코드 리스트
            var personas = personaRepo.findAllById(personaIds).stream()
                    .map(Persona::getCode).toList();

            gateway.start(sessionUuid.toString(), req.getContent(), 3000, personas);
        } else {
            gateway.sendUserInput(sessionUuid.toString(), req.getContent());
        }
        return new AppendMessageResponse(saved.getId());
    }

    // ==================== Stream ====================
    @Override
    public SseEmitter streamAssistant(Integer userId, UUID sessionUuid, String deviceId, String lastEventId) {
        loadOwnedSession(userId, sessionUuid);
        log.info("[ChatSvc-21] SSE 시작 sessionUuid={}, deviceId={}, lastEventId={}", sessionUuid, deviceId, lastEventId);

        SseEmitter emitter = emitterRegistry.register(sessionUuid);

        try {
            if (lastEventId != null && !lastEventId.isBlank()) {
                replayRecent(emitter, sessionUuid);
            }
        } catch (IOException ioe) {
            log.warn("[ChatSvc-W21] 리플레이 전송 실패 sessionUuid={}, reason={}", sessionUuid, ioe.toString());
            emitter.completeWithError(ioe);
            return emitter;
        }

        AtomicLong seq = new AtomicLong(1);
        Disposable subscription = gateway.stream(sessionUuid.toString())
                .doOnError(err -> {
                    log.error("[ChatSvc-E21] FastAPI 스트림 오류 sessionUuid={}, err={}", sessionUuid, err.toString());
                    try {
                        emitter.send(SseEmitter.event().name("error")
                                .data("{\"type\":\"error\",\"code\":\"ChatSvc-E04\",\"message\":\"파이프 오류\"}"));
                    } catch (IOException ignored) {}
                    emitter.completeWithError(new AppException(ErrorCode.INTERNAL_ERROR, E04_PIPE_ERROR));
                })
                .doOnComplete(() -> {
                    log.info("[ChatSvc-22] FastAPI 스트림 완료 sessionUuid={}", sessionUuid);
                    emitter.complete();
                })
                .subscribe((ServerSentEvent<String> sse) -> {
                    try {
                        String eventName = sse.event() == null ? "message" : sse.event();
                        String data = sse.data() == null ? "" : sse.data();

                        if ("message".equals(eventName) && !data.isBlank()) {
                            msgRepo.save(ChatMessageDoc.builder()
                                    .sessionUuid(sessionUuid)
                                    .role("assistant")
                                    .content(data)
                                    .seq(seq.get())
                                    .ts(Instant.now())
                                    .build());
                        }

                        emitter.send(SseEmitter.event()
                                .id(String.valueOf(seq.getAndIncrement()))
                                .name(eventName)
                                .data(data));
                    } catch (IOException io) {
                        log.warn("[ChatSvc-W22] SSE 전송 실패 sessionUuid={}, reason={}", sessionUuid, io.toString());
                        emitter.completeWithError(io);
                    }
                });

        emitter.onCompletion(() -> {
            log.info("[ChatSvc-23] SSE onCompletion sessionUuid={}", sessionUuid);
            subscription.dispose();
            emitterRegistry.remove(sessionUuid);
        });
        emitter.onTimeout(() -> {
            log.info("[ChatSvc-24] SSE onTimeout sessionUuid={}", sessionUuid);
            subscription.dispose();
            emitter.complete();
            emitterRegistry.remove(sessionUuid);
        });
        emitter.onError(e -> {
            log.info("[ChatSvc-25] SSE onError sessionUuid={}, err={}", sessionUuid, e.toString());
            subscription.dispose();
            emitterRegistry.remove(sessionUuid);
        });

        try {
            emitter.send(SseEmitter.event().name("heartbeat").data("{\"ts\":\"" + Instant.now() + "\"}"));
        } catch (IOException ignored) {}

        return emitter;
    }

    // ==================== Control ====================
    @Override
    public void interrupt(Integer userId, UUID sessionUuid) {
        loadOwnedSession(userId, sessionUuid);
        log.info("[ChatSvc-31] 인터럽트 요청 sessionUuid={}", sessionUuid);

        try {
            gateway.control(sessionUuid.toString(), "STOP", null);
            var emitter = emitterRegistry.get(sessionUuid);
            if (emitter != null) {
                emitter.send(SseEmitter.event().name("interrupted").data("{\"by\":\"user\"}"));
                emitter.complete();
            }
            emitterRegistry.remove(sessionUuid);
        } catch (Exception e) {
            log.error("[ChatSvc-E31] 인터럽트 실패 sessionUuid={}, err={}", sessionUuid, e.toString());
            throw new AppException(ErrorCode.INTERNAL_ERROR, E05_INTERRUPT_FAIL, e);
        }
    }

    @Override
    @Transactional(readOnly = true)
    public HistoryResponse history(Integer userId, UUID sessionUuid, int limit) {
        loadOwnedSession(userId, sessionUuid);
        log.info("[ChatSvc-41] 히스토리 조회 sessionUuid={}, limit={}", sessionUuid, limit);

        List<HistoryItem> items = msgRepo.findBySessionUuidOrderByTsDesc(sessionUuid, PageRequest.of(0, limit))
                .stream()
                .map(m -> new HistoryItem(m.getRole(), m.getContent(), m.getTs()))
                .toList();

        return new HistoryResponse(items);
    }

    @Override
    public void resume(Integer userId, UUID sessionUuid) {
        loadOwnedSession(userId, sessionUuid);
        log.info("[ChatSvc-51] 재개 요청 sessionUuid={}", sessionUuid);
        gateway.control(sessionUuid.toString(), "RESUME", null);
    }

    @Override
    public void changePace(Integer userId, UUID sessionUuid, int paceMs) {
        loadOwnedSession(userId, sessionUuid);
        log.info("[ChatSvc-61] 페이스 변경 요청 sessionUuid={}, paceMs={}", sessionUuid, paceMs);
        gateway.control(sessionUuid.toString(), "CHANGE_PACE", paceMs);
    }

    // ==================== Helpers ====================
    private ChatSession loadOwnedSession(Integer userId, UUID sessionUuid) {
        ChatSession session = sessionRepo.findByUuid(sessionUuid).orElseThrow(() -> {
            log.warn("[ChatSvc-E02] 세션 없음 sessionUuid={}", sessionUuid);
            return new AppException(ErrorCode.NOT_FOUND, E02_SESSION_NOT_FOUND);
        });
        if (!session.getUserId().equals(userId)) {
            log.warn("[ChatSvc-E03] 세션 소유자 불일치 sessionUuid={}, ownerId={}, reqUserId={}",
                    sessionUuid, session.getUserId(), userId);
            throw new AppException(ErrorCode.FORBIDDEN, E03_FORBIDDEN);
        }
        return session;
    }

    private void replayRecent(SseEmitter emitter, UUID sessionUuid) throws IOException {
        List<ChatMessageDoc> recent = msgRepo.findBySessionUuidOrderByTsDesc(sessionUuid, PageRequest.of(0, REPLAY_LIMIT));
        for (int i = recent.size() - 1; i >= 0; i--) {
            ChatMessageDoc m = recent.get(i);
            emitter.send(SseEmitter.event()
                    .name("replay")
                    .data(objectMapper.writeValueAsString(new HistoryItem(m.getRole(), m.getContent(), m.getTs()))));
        }
    }
}
