package com.ssafy.b205.backend.domain.chat.service;

import com.ssafy.b205.backend.domain.chat.dto.request.AppendMessageRequest;
import com.ssafy.b205.backend.domain.chat.dto.request.CreateSessionRequest;
import com.ssafy.b205.backend.domain.chat.dto.response.AppendMessageResponse;
import com.ssafy.b205.backend.domain.chat.dto.response.ChatSessionSummaryResponse;
import com.ssafy.b205.backend.domain.chat.dto.response.CreateSessionResponse;
import com.ssafy.b205.backend.domain.chat.dto.response.HistoryResponse;
import com.ssafy.b205.backend.domain.chat.entity.ChatSession;
import com.ssafy.b205.backend.domain.chat.entity.ChatSessionPersona;
import com.ssafy.b205.backend.domain.chat.repository.ChatSessionPersonaRepository;
import com.ssafy.b205.backend.domain.chat.repository.ChatSessionRepository;
import com.ssafy.b205.backend.domain.persona.entity.Persona;
import com.ssafy.b205.backend.domain.persona.repository.PersonaRepository;
import com.ssafy.b205.backend.domain.user.entity.User;
import com.ssafy.b205.backend.domain.user.repository.UserRepository;
import com.ssafy.b205.backend.infra.client.fastai.FastAiGateway;
import com.ssafy.b205.backend.infra.mongo.chat.ChatMessageDoc;
import com.ssafy.b205.backend.infra.mongo.chat.ChatMessageRepository;
import com.ssafy.b205.backend.infra.sse.SseEmitterRegistry;
import com.ssafy.b205.backend.support.error.AppException;
import com.ssafy.b205.backend.support.error.ErrorCode;
import com.ssafy.b205.backend.support.response.PageResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.codec.ServerSentEvent;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;
import org.bson.types.ObjectId;
import reactor.core.Disposable;
import reactor.core.publisher.Flux;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;

import java.time.Duration;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;

@Slf4j
@Service
@RequiredArgsConstructor
public class ChatServiceImpl implements ChatService {
    private static final Executor asyncExecutor = Executors.newFixedThreadPool(5);
    private static final ObjectMapper objectMapper = new ObjectMapper();

    private static final String E_OWNER = "[ChatSvc-E01] 세션 소유자 불일치";
    private static final String E_NOTF  = "[ChatSvc-E02] 세션을 찾을 수 없습니다.";
    private static final String T_FAIL  = "[ChatSvc-E05] 중단 실패(전달오류)";

    private final ChatSessionRepository sessionRepo;
    private final ChatSessionPersonaRepository cspRepo;
    private final ChatMessageRepository msgRepo; // Mongo
    private final PersonaRepository personaRepo;
    private final UserRepository userRepository;
    private final FastAiGateway gateway;
    private final SseEmitterRegistry emitterRegistry;
    private final PlatformTransactionManager transactionManager;

    /** UUID → 내부 int id */
    private int toUserId(String userUuid) {
        final User u = userRepository.findByUuidAndDeletedAtIsNull(UUID.fromString(userUuid))
                .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND, "사용자를 찾을 수 없습니다."));
        return u.getId();
    }

    // ============ Session ============

    @Override
    @Transactional
    public CreateSessionResponse createSession(String userUuid, CreateSessionRequest req) {
        final int userId = toUserId(userUuid);

        // 활성 페르소나 코드
        final List<Persona> enabled = personaRepo.findEnabledByUserId(userId);
        final List<String> personaCodes = enabled.stream().map(Persona::getCode).toList();

        final ChatSession session = sessionRepo.save(
                ChatSession.create(userId, req.getTopicType(), req.getTitle(), req.getTicker(), req.getCompanyNewsId())
        );

        // 세션-페르소나 스냅샷
        final var links = enabled.stream()
                .map(p -> ChatSessionPersona.of(session.getId(), p.getId()))
                .toList();
        cspRepo.saveAll(links);

        final UUID sessionUuid = session.getUuid();
        
        // AI 서비스 세션도 미리 생성 (빈 메시지로 초기화)
        // 세션이 생성되지 않은 상태에서 스트림 연결을 방지하기 위함
        try {
            log.info("[ChatSvc-01] AI 서비스 세션 미리 생성 sessionUuid={}, personas={}", sessionUuid, personaCodes);
            // 빈 메시지로 AI 서비스 세션 생성 (실제 메시지는 나중에 전송)
            gateway.start(sessionUuid.toString(), "", 3000, personaCodes);
            log.info("[ChatSvc-02] AI 서비스 세션 생성 완료 sessionUuid={}", sessionUuid);
        } catch (Exception e) {
            log.error("[ChatSvc-E11] AI 서비스 세션 생성 실패 sessionUuid={}, error={}", sessionUuid, e.getMessage());
            throw new AppException(ErrorCode.INTERNAL_ERROR, "AI 서비스 세션 생성 실패: " + e.getMessage());
        }

        return new CreateSessionResponse(
                sessionUuid,
                personaCodes,
                session.getCreatedAt().toInstant() // ✅ DTO가 Instant
        );
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<ChatSessionSummaryResponse> listSessions(String userUuid, int page, int size) {
        final int userId = toUserId(userUuid);
        final int safePage = Math.max(0, page);
        final int safeSize = Math.max(1, Math.min(100, size));
        final var pageable = PageRequest.of(safePage, safeSize, Sort.by(Sort.Direction.DESC, "updatedAt"));
        return PageResponse.of(
                sessionRepo.findByUserIdAndDeletedAtIsNull(userId, pageable)
                        .map(ChatSessionSummaryResponse::from)
        );
    }

    @Override
    @Transactional
    public void deleteSession(String userUuid, UUID sessionUuid) {
        final int userId = toUserId(userUuid);
        final ChatSession session = loadOwnedSession(userId, sessionUuid);
        session.markDeleted();
    }

    @Override
    @Transactional
    public AppendMessageResponse appendUserMessage(String userUuid, UUID sessionUuid, AppendMessageRequest req) {
        final int userId = toUserId(userUuid);
        // 채팅방 입장 시 이미 세션이 존재하므로, 세션 검증만 수행
        final ChatSession session = loadOwnedSession(userId, sessionUuid); // 소유권 검증
        final UUID actualSessionUuid = session.getUuid();

        final ChatMessageDoc saved = msgRepo.save(ChatMessageDoc.builder()
                .sessionUuid(actualSessionUuid)
                .role("user")
                .content(req.getContent())
                .ts(Instant.now())
                .build());

        final long userMsgCount = msgRepo.countBySessionUuidAndRole(actualSessionUuid, "user");

        // AI 서비스 호출을 비동기로 처리하여 응답 지연 방지
        final UUID finalSessionUuid = actualSessionUuid;
        final String finalContent = req.getContent();
        
        if (userMsgCount <= 1) {
            final var personaIds = cspRepo.findPersonaIdsBySessionId(session.getId());
            if (personaIds.isEmpty()) {
                throw new AppException(ErrorCode.BAD_REQUEST, "세션의 페르소나 매핑이 없습니다.");
            }
            final var personas = personaRepo.findAllById(personaIds).stream().map(Persona::getCode).toList();
            
            // /start 호출을 동기로 처리 (AI 서비스 세션 생성 완료 후 응답 반환)
            try {
                log.info("[ChatSvc-11] AI 세션 시작 (동기) sessionUuid={}, personas={}", finalSessionUuid, personas);
                gateway.start(finalSessionUuid.toString(), finalContent, 3000, personas);
                log.info("[ChatSvc-12] AI 세션 시작 완료 sessionUuid={}", finalSessionUuid);
            } catch (Exception e) {
                log.error("[ChatSvc-E12] AI 세션 시작 실패 sessionUuid={}, error={}", finalSessionUuid, e.getMessage());
                throw new AppException(ErrorCode.INTERNAL_ERROR, "AI 서비스 세션 시작 실패: " + e.getMessage());
            }
        } else {
            // /input 호출도 동기로 처리
            try {
                log.info("[ChatSvc-13] 사용자 입력 전달 (동기) sessionUuid={}", finalSessionUuid);
                gateway.sendUserInput(finalSessionUuid.toString(), finalContent);
                log.info("[ChatSvc-14] 사용자 입력 전달 완료 sessionUuid={}", finalSessionUuid);
            } catch (Exception e) {
                log.error("[ChatSvc-E13] 사용자 입력 전달 실패 sessionUuid={}, error={}", finalSessionUuid, e.getMessage());
                throw new AppException(ErrorCode.INTERNAL_ERROR, "AI 서비스 입력 전달 실패: " + e.getMessage());
            }
        }

        sessionRepo.touchUpdatedAt(session.getId(), OffsetDateTime.now());
        return new AppendMessageResponse(saved.getId());
    }

    // ============ Stream ============

    @Override
    @Transactional(readOnly = true)
    public SseEmitter streamAssistant(String userUuid, UUID sessionUuid, String deviceId, String lastEventId) {
        final int userId = toUserId(userUuid);
        // 채팅방 입장 시 이미 세션이 존재하므로, 세션 검증만 수행
        final ChatSession session = loadOwnedSession(userId, sessionUuid); // 소유권 검증
        final int sessionDbId = session.getId();

        final SseEmitter emitter = emitterRegistry.create(sessionUuid, deviceId, lastEventId);
        replayMissedMessages(emitter, sessionUuid, lastEventId);
        final Disposable keepAlive = startKeepAlive(emitter);

        // AI 서비스 스트림 준비 완료를 기다리기 위한 CountDownLatch
        final java.util.concurrent.CountDownLatch readyLatch = new java.util.concurrent.CountDownLatch(1);
        final java.util.concurrent.atomic.AtomicBoolean readyReceived = new java.util.concurrent.atomic.AtomicBoolean(false);

        final Disposable sub = gateway.stream(sessionUuid.toString())
                .doOnError(err -> {
                    // AI 서비스 스트림 에러는 프론트엔드 스트림을 종료하지 않음
                    log.warn("[ChatSvc-W21] AI 서비스 스트림 에러 (프론트엔드 스트림은 유지) msg={}", err.getMessage());
                    // emitter.completeWithError(err); // 주석 처리
                })
                .doOnComplete(() -> {
                    // AI 서비스 스트림이 완료되어도 프론트엔드 스트림은 유지
                    log.debug("[ChatSvc-22] AI 서비스 스트림 완료 (프론트엔드 스트림은 유지)");
                    // emitter.complete(); // 주석 처리
                })
                .subscribe((ServerSentEvent<String> sse) -> {
                    try {
                        final String eventName = (sse.event() != null ? sse.event() : "message");
                        final String data = sse.data();
                        final String eventId = sse.id();
                        log.debug("[ChatSvc-23] AI 서비스 이벤트 수신 event={}, id={}, data={}", eventName, eventId, data);
                        final String defaultPayload = buildPayload(eventName, eventId, data, null, null);

                        // ready 이벤트 처리: AI 서비스가 세션과 스트림 준비 완료를 알릴 때
                        if ("ready".equals(eventName)) {
                            log.info("[ChatSvc-24] AI 서비스 ready 이벤트 수신 (세션 및 스트림 준비 완료)");
                            readyReceived.set(true);
                            readyLatch.countDown(); // 준비 완료 신호
                            emitter.send(buildEvent(eventName, eventId, defaultPayload));
                            return;
                        }

                        // close 이벤트 처리: AI 서비스가 스트림 종료를 알릴 때
                        // 하지만 채팅은 계속 유지되어야 하므로 close 이벤트를 무시
                        if ("close".equals(eventName)) {
                            log.debug("[ChatSvc-25] AI 서비스 close 이벤트 수신 (무시하고 계속 유지)");
                            return; // 스트림 종료하지 않고 계속 유지
                        }

                        // error 이벤트 처리: AI 서비스가 에러를 알릴 때
                        if ("error".equals(eventName)) {
                            log.debug("[ChatSvc-26] AI 서비스 error 이벤트 수신 (무시하고 계속 유지) data={}", data);
                            return; // 스트림 종료하지 않고 계속 유지
                        }

                        // FastAPI가 빈 message 이벤트를 heartbeat 용도로 보내는 경우는 프론트로 전달하지 않음
                        if ("message".equals(eventName) && (data == null || data.isBlank())) {
                            log.trace("[ChatSvc-27] 빈 message 이벤트 무시");
                            return;
                        }

                        // 메시지 이벤트는 Mongo에 저장 (token chunk가 아니라 완성 텍스트 기준이면 게이트웨이 쪽에서 제어)
                        if ("message".equals(eventName)) {
                            final AiPayload aiPayload = parseAiPayload(data);
                            final String finalContent = (aiPayload != null && aiPayload.getContent() != null)
                                    ? aiPayload.getContent()
                                    : data;
                            final Long seq = parseSeq(eventId);
                            final UUID finalSessionUuid = sessionUuid;
                            final int finalSessionDbId = sessionDbId;
                            final String upstreamEventId = eventId;
                            final String emitterEventId = new ObjectId().toHexString();
                            final ChatMessageDoc doc = ChatMessageDoc.builder()
                                    .id(emitterEventId)
                                    .sessionUuid(finalSessionUuid)
                                    .role("assistant")
                                    .content(finalContent)
                                    .speaker(aiPayload != null ? aiPayload.getSpeaker() : null)
                                    .turn(aiPayload != null ? aiPayload.getTurn() : null)
                                    .aiTsMs(aiPayload != null ? aiPayload.getTsMs() : null)
                                    .rawPayload(data)
                                    .ts(Instant.now())
                                    .seq(seq)
                                    .build();

                            final String payload = buildPayload(eventName, emitterEventId, data, aiPayload, upstreamEventId);
                            emitter.send(buildEvent(eventName, emitterEventId, payload));

                            // MongoDB 저장은 비동기로 처리 (프론트엔드 전달을 블로킹하지 않음)
                            CompletableFuture.runAsync(() -> {
                                try {
                                    msgRepo.save(doc);
                                    new TransactionTemplate(transactionManager).executeWithoutResult(status ->
                                            sessionRepo.touchUpdatedAt(finalSessionDbId, OffsetDateTime.now())
                                    );
                                    log.debug("[ChatSvc-28] 메시지 저장 완료 docId={}", doc.getId());
                                } catch (Exception e) {
                                    log.warn("[ChatSvc-W28] 메시지 저장 실패 msg={}", e.getMessage());
                                }
                            }, asyncExecutor);
                            
                            return;
                        }

                        emitter.send(buildEvent(eventName, eventId, defaultPayload));
                    } catch (Exception e) {
                        log.error("[ChatSvc-E29] SSE send error (연결 종료) msg={}", e.getMessage(), e);
                        emitter.completeWithError(e);
                        throw new RuntimeException("SSE 전송 실패로 연결 종료", e);
                    }
                });

        Runnable disposeAll = () -> {
            sub.dispose();
            keepAlive.dispose();
        };
        emitter.onCompletion(disposeAll);
        emitter.onTimeout(disposeAll);
        emitter.onError(e -> disposeAll.run());
        
        // AI 서비스 스트림이 ready 이벤트를 보낼 때까지 대기 (최대 10초)
        // 백그라운드 스레드에서 대기하여 메인 스레드를 블로킹하지 않음
        CompletableFuture.runAsync(() -> {
            try {
                boolean ready = readyLatch.await(10, java.util.concurrent.TimeUnit.SECONDS);
                if (ready) {
                    log.info("[ChatSvc-31] AI 서비스 스트림 준비 완료 확인됨");
                } else {
                    log.warn("[ChatSvc-W31] AI 서비스 ready 이벤트를 10초 내에 받지 못함 (스트림은 계속 유지)");
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                log.warn("[ChatSvc-W32] Ready 이벤트 대기 중단됨");
            }
        }, asyncExecutor);
        
        return emitter;
    }

    @Override
    @Transactional
    public void interrupt(String userUuid, UUID sessionUuid) {
        final int userId = toUserId(userUuid);
        loadOwnedSession(userId, sessionUuid);
        try {
            gateway.control(sessionUuid.toString(), "STOP", null); // FastAPI는 STOP 액션 사용
        } catch (Exception e) {
            throw new AppException(ErrorCode.BAD_REQUEST, T_FAIL);
        }
    }

    @Override
    @Transactional(readOnly = true)
    public HistoryResponse history(String userUuid, UUID sessionUuid, int limit) {
        final int userId = toUserId(userUuid);
        loadOwnedSession(userId, sessionUuid);

        final var page = msgRepo.findBySessionUuidOrderByTsDesc(
                sessionUuid, PageRequest.of(0, Math.max(1, limit))
        );

        // 최신→과거로 온 리스트를 복사 후 역순(과거→최신)으로 전달
        final var docs = new ArrayList<>(page.getContent());
        Collections.reverse(docs);
        return HistoryResponse.from(docs);
    }

    @Override
    @Transactional(readOnly = true)
    public com.ssafy.b205.backend.domain.chat.dto.response.HistoryCursorResponse
    history2(String userUuid, UUID sessionUuid, int limit, String cursorId) {
        final int userId = toUserId(userUuid);
        loadOwnedSession(userId, sessionUuid);

        final int limitClamped = Math.max(1, Math.min(100, limit));
        final var pageable = PageRequest.of(0, limitClamped + 1); // limit+1 조회

        ObjectId cursorObjectId = null;
        if (cursorId != null && !cursorId.isBlank()) {
            try {
                cursorObjectId = new ObjectId(cursorId);
            } catch (IllegalArgumentException e) {
                throw new AppException(ErrorCode.BAD_REQUEST, "유효하지 않은 cursor 입니다.");
            }
        }

        final List<ChatMessageDoc> docsDesc = (cursorObjectId == null)
                ? msgRepo.pageFirst(sessionUuid, pageable)
                : msgRepo.pageByCursor(sessionUuid, cursorObjectId, pageable);

        final boolean hasMore = docsDesc.size() > limitClamped;
        final List<ChatMessageDoc> sliceDesc = hasMore ? docsDesc.subList(0, limitClamped) : docsDesc;
        final String nextCursor = (hasMore && !sliceDesc.isEmpty())
                ? sliceDesc.get(sliceDesc.size() - 1).getId()
                : null;

        // _id desc → 응답은 과거→최신
        final var orderedAsc = new ArrayList<>(sliceDesc);
        Collections.reverse(orderedAsc);

        return com.ssafy.b205.backend.domain.chat.dto.response.HistoryCursorResponse.of(
                orderedAsc,
                nextCursor,
                hasMore
        );
    }


    @Override
    @Transactional
    public void resume(String userUuid, UUID sessionUuid) {
        final int userId = toUserId(userUuid);
        loadOwnedSession(userId, sessionUuid);
        gateway.control(sessionUuid.toString(), "RESUME", null);
    }

    @Override
    @Transactional
    public void changePace(String userUuid, UUID sessionUuid, int paceMs) {
        final int userId = toUserId(userUuid);
        loadOwnedSession(userId, sessionUuid);
        gateway.control(sessionUuid.toString(), "CHANGE_PACE", paceMs);
    }

    private String buildPayload(String eventName, String eventId, String rawData, AiPayload parsed, String upstreamEventId) {
        try {
            final ObjectNode node = objectMapper.createObjectNode();
            node.put("event", eventName);
            if (eventId != null) {
                node.put("eventId", eventId);
            }
            if (rawData != null) {
                node.put("raw", rawData);
            }
            if (parsed != null) {
                if (parsed.getContent() != null) {
                    node.put("content", parsed.getContent());
                }
                if (parsed.getSpeaker() != null) {
                    node.put("speaker", parsed.getSpeaker());
                }
                if (parsed.getTurn() != null) {
                    node.put("turn", parsed.getTurn());
                }
                if (parsed.getTsMs() != null) {
                    node.put("tsMs", parsed.getTsMs());
                }
                if (parsed.getSessionId() != null) {
                    node.put("sessionId", parsed.getSessionId());
                }
            }
            if (upstreamEventId != null) {
                node.put("aiEventId", upstreamEventId);
            }
            return objectMapper.writeValueAsString(node);
        } catch (Exception e) {
            log.debug("[ChatSvc-41] payload 직렬화 실패 msg={}", e.getMessage());
            return rawData != null ? rawData : "";
        }
    }

    private SseEmitter.SseEventBuilder buildEvent(String eventName, String eventId, String payload) {
        SseEmitter.SseEventBuilder builder = SseEmitter.event()
                .name(eventName)
                .data(payload);
        if (eventId != null) {
            builder = builder.id(eventId);
        }
        return builder;
    }

    private AiPayload parseAiPayload(String data) {
        if (data == null || data.isBlank()) {
            return null;
        }
        try {
            JsonNode node = objectMapper.readTree(data);
            final JsonNode contentNode = node.get("content");
            final JsonNode speakerNode = node.get("speaker");
            final JsonNode sessionNode = node.get("session_id");
            final JsonNode turnNode = node.get("turn");
            final JsonNode tsNode = node.get("ts_ms");
            final String content = contentNode != null && contentNode.isTextual() ? contentNode.asText() : null;
            final String speaker = speakerNode != null && speakerNode.isTextual() ? speakerNode.asText() : null;
            final String sessionId = sessionNode != null && sessionNode.isTextual() ? sessionNode.asText() : null;
            final Integer turn = turnNode != null && turnNode.isNumber() ? turnNode.intValue() : null;
            final Long tsMs = tsNode != null && tsNode.isNumber() ? tsNode.longValue() : null;
            if (content == null && speaker == null && turn == null && tsMs == null && sessionId == null) {
                return null; // 빈 json일 때는 굳이 객체 생성하지 않음
            }
            return new AiPayload(content, speaker, turn, tsMs, sessionId);
        } catch (Exception e) {
            log.debug("[ChatSvc-42] AI payload 파싱 실패 msg={}", e.getMessage());
            return null;
        }
    }

    private void replayMissedMessages(SseEmitter emitter, UUID sessionUuid, String lastEventId) {
        if (lastEventId == null || lastEventId.isBlank()) {
            return;
        }
        try {
            final ObjectId cursor = new ObjectId(lastEventId);
            final List<ChatMessageDoc> docs = msgRepo.findAfterId(sessionUuid, cursor);
            for (ChatMessageDoc doc : docs) {
                try {
                    emitter.send(SseEmitter.event()
                            .id(doc.getId())
                            .name("message")
                            .data(doc.getContent()));
                } catch (Exception sendError) {
                    log.debug("[ChatSvc-43] replay send interrupted msg={}", sendError.getMessage());
                    return;
                }
            }
        } catch (IllegalArgumentException e) {
            log.warn("[ChatSvc-W44] lastEventId {} is not a valid ObjectId", lastEventId);
        } catch (Exception e) {
            log.warn("[ChatSvc-W45] replay send error msg={}", e.getMessage());
        }
    }

    private Disposable startKeepAlive(SseEmitter emitter) {
        return Flux.interval(Duration.ofSeconds(15))
                .subscribe(tick -> {
                    try {
                        emitter.send(SseEmitter.event()
                                .name("ping")
                                .data("keep-alive"));
                    } catch (Exception e) {
                        log.warn("[ChatSvc-W46] keep-alive send failed, completing emitter msg={}", e.getMessage());
                        emitter.completeWithError(e);
                    }
                });
    }

    private Long parseSeq(String eventId) {
        if (eventId == null || eventId.isBlank()) {
            return null;
        }
        try {
            return Long.parseLong(eventId);
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private ChatSession loadOwnedSession(Integer userId, UUID sessionUuid) {
        final ChatSession s = sessionRepo.findByUuidAndDeletedAtIsNull(sessionUuid)
                .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND, E_NOTF));
        if (!s.getUserId().equals(userId)) {
            throw new AppException(ErrorCode.FORBIDDEN, E_OWNER);
        }
        return s;
    }

    private static class AiPayload {
        private final String content;
        private final String speaker;
        private final Integer turn;
        private final Long tsMs;
        private final String sessionId;

        private AiPayload(String content, String speaker, Integer turn, Long tsMs, String sessionId) {
            this.content = content;
            this.speaker = speaker;
            this.turn = turn;
            this.tsMs = tsMs;
            this.sessionId = sessionId;
        }

        public String getContent() {
            return content;
        }

        public String getSpeaker() {
            return speaker;
        }

        public Integer getTurn() {
            return turn;
        }

        public Long getTsMs() {
            return tsMs;
        }

        public String getSessionId() {
            return sessionId;
        }
    }
}
