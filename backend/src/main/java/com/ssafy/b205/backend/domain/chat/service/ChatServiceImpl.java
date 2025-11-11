package com.ssafy.b205.backend.domain.chat.service;

import com.ssafy.b205.backend.domain.chat.dto.request.AppendMessageRequest;
import com.ssafy.b205.backend.domain.chat.dto.request.CreateSessionRequest;
import com.ssafy.b205.backend.domain.chat.dto.response.AppendMessageResponse;
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
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.codec.ServerSentEvent;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;
import org.bson.types.ObjectId;
import org.springframework.data.domain.PageRequest;
import reactor.core.Disposable;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicLong;

@Slf4j
@Service
@RequiredArgsConstructor
public class ChatServiceImpl implements ChatService {

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

        return new CreateSessionResponse(
                session.getUuid(),
                personaCodes,
                session.getCreatedAt().toInstant() // ✅ DTO가 Instant
        );
    }

    @Override
    @Transactional
    public AppendMessageResponse appendUserMessage(String userUuid, UUID sessionUuid, AppendMessageRequest req) {
        final int userId = toUserId(userUuid);
        final ChatSession session = loadOwnedSession(userId, sessionUuid);

        final ChatMessageDoc saved = msgRepo.save(ChatMessageDoc.builder()
                .sessionUuid(sessionUuid)
                .role("user")
                .content(req.getContent())
                .seq(System.nanoTime()) // 최초 메시지 트리거 판단은 count로 하므로 OK
                .ts(Instant.now())
                .build());

        final long userMsgCount = msgRepo.countBySessionUuidAndRole(sessionUuid, "user");

        if (userMsgCount <= 1) {
            final var personaIds = cspRepo.findPersonaIdsBySessionId(session.getId());
            if (personaIds.isEmpty()) {
                throw new AppException(ErrorCode.BAD_REQUEST, "세션의 페르소나 매핑이 없습니다.");
            }
            final var personas = personaRepo.findAllById(personaIds).stream().map(Persona::getCode).toList();
            gateway.start(sessionUuid.toString(), req.getContent(), 3000, personas);
        } else {
            gateway.sendUserInput(sessionUuid.toString(), req.getContent());
        }
        return new AppendMessageResponse(saved.getId());
    }

    // ============ Stream ============

    @Override
    @Transactional(readOnly = true)
    public SseEmitter streamAssistant(String userUuid, UUID sessionUuid, String deviceId, String lastEventId) {
        final int userId = toUserId(userUuid);
        loadOwnedSession(userId, sessionUuid); // 소유권 검증

        final SseEmitter emitter = emitterRegistry.create(sessionUuid, deviceId, lastEventId);
        final AtomicLong seq = new AtomicLong(1);

        final Disposable sub = gateway.stream(sessionUuid.toString())
                .doOnError(err -> {
                    try { emitter.completeWithError(err); } catch (Exception ignored) {}
                })
                .doOnComplete(() -> {
                    try { emitter.complete(); } catch (Exception ignored) {}
                })
                .subscribe((ServerSentEvent<String> sse) -> {
                    try {
                        final String eventName = (sse.event() != null ? sse.event() : "message");
                        final String data = sse.data();

                        // 메시지 이벤트는 Mongo에 저장 (token chunk가 아니라 완성 텍스트 기준이면 게이트웨이 쪽에서 제어)
                        if ("message".equals(eventName) && data != null && !data.isBlank()) {
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
                    } catch (Exception e) {
                        log.warn("[ChatSvc-Stream] SSE send error: {}", e.getMessage());
                    }
                });

        emitter.onCompletion(sub::dispose);
        emitter.onTimeout(sub::dispose);
        return emitter;
    }

    @Override
    @Transactional
    public void interrupt(String userUuid, UUID sessionUuid) {
        final int userId = toUserId(userUuid);
        loadOwnedSession(userId, sessionUuid);
        try {
            gateway.control(sessionUuid.toString(), "INTERRUPT", null);
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

        final int pageSize = Math.max(1, Math.min(100, limit)) + 1; // limit+1 조회
        final var pageable = PageRequest.of(0, pageSize);

        final List<ChatMessageDoc> docsDesc = (cursorId == null || cursorId.isBlank())
                ? msgRepo.pageFirst(sessionUuid, pageable)
                : msgRepo.pageByCursor(sessionUuid, new ObjectId(cursorId), pageable);

        // _id desc → 응답은 과거→최신
        final var orderedAsc = new ArrayList<>(docsDesc);
        Collections.reverse(orderedAsc);

        return com.ssafy.b205.backend.domain.chat.dto.response.HistoryCursorResponse.of(orderedAsc, pageSize);
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

    private ChatSession loadOwnedSession(Integer userId, UUID sessionUuid) {
        final ChatSession s = sessionRepo.findByUuid(sessionUuid)
                .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND, E_NOTF));
        if (!s.getUserId().equals(userId)) {
            throw new AppException(ErrorCode.FORBIDDEN, E_OWNER);
        }
        return s;
    }
}
