package com.ssafy.b205.backend.domain.chat.service;

import com.ssafy.b205.backend.domain.chat.dto.response.HistoryCursorResponse;
import com.ssafy.b205.backend.domain.chat.entity.ChatSession;
import com.ssafy.b205.backend.domain.chat.entity.ChatTopicType;
import com.ssafy.b205.backend.domain.chat.repository.ChatSessionPersonaRepository;
import com.ssafy.b205.backend.domain.chat.repository.ChatSessionRepository;
import com.ssafy.b205.backend.domain.persona.repository.PersonaRepository;
import com.ssafy.b205.backend.domain.user.entity.User;
import com.ssafy.b205.backend.domain.user.entity.UserStatus;
import com.ssafy.b205.backend.domain.user.repository.UserRepository;
import com.ssafy.b205.backend.infra.client.fastai.FastAiGateway;
import com.ssafy.b205.backend.infra.mongo.chat.ChatMessageDoc;
import com.ssafy.b205.backend.infra.mongo.chat.ChatMessageRepository;
import com.ssafy.b205.backend.infra.sse.SseEmitterRegistry;
import com.ssafy.b205.backend.support.error.AppException;
import com.ssafy.b205.backend.support.error.ErrorCode;
import org.bson.types.ObjectId;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.time.Instant;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.CopyOnWriteArrayList;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ChatServiceImplTest {

    @Mock ChatSessionRepository sessionRepo;
    @Mock ChatSessionPersonaRepository cspRepo;
    @Mock ChatMessageRepository msgRepo;
    @Mock PersonaRepository personaRepo;
    @Mock UserRepository userRepository;
    @Mock FastAiGateway gateway;
    @Mock SseEmitterRegistry emitterRegistry;
    @Mock PlatformTransactionManager txManager;

    @InjectMocks
    ChatServiceImpl chatService;

    private User user;
    private String userUuid;

    @BeforeEach
    void setUp() {
        userUuid = UUID.randomUUID().toString();
        user = User.builder()
                .id(1)
                .uuid(UUID.fromString(userUuid))
                .email("user@test.com")
                .nickname("nick")
                .status(UserStatus.ACTIVE)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
        when(userRepository.findByUuidAndDeletedAtIsNull(UUID.fromString(userUuid)))
                .thenReturn(Optional.of(user));
    }

    private ChatSession sessionOwnedByUser(UUID sessionUuid, int userId) {
        ChatSession s = ChatSession.createWithUuid(userId, sessionUuid, ChatTopicType.CUSTOM, "t", null, null);
        ReflectionTestUtils.setField(s, "id", 10);
        return s;
    }

    @Test
    @DisplayName("interrupt는 세션 소유 검증 후 STOP 제어를 전송한다")
    void interruptSendsStop() {
        UUID sessionId = UUID.randomUUID();
        when(sessionRepo.findByUuidAndDeletedAtIsNull(sessionId))
                .thenReturn(Optional.of(sessionOwnedByUser(sessionId, user.getId())));

        chatService.interrupt(userUuid, sessionId);

        verify(gateway).control(sessionId.toString(), "STOP", null);
    }

    @Test
    @DisplayName("resume은 RESUME 제어를 전송한다")
    void resumeSendsControl() {
        UUID sessionId = UUID.randomUUID();
        when(sessionRepo.findByUuidAndDeletedAtIsNull(sessionId))
                .thenReturn(Optional.of(sessionOwnedByUser(sessionId, user.getId())));

        chatService.resume(userUuid, sessionId);

        verify(gateway).control(sessionId.toString(), "RESUME", null);
    }

    @Test
    @DisplayName("changePace는 paceMs를 포함해 제어를 전송한다")
    void changePaceSendsControl() {
        UUID sessionId = UUID.randomUUID();
        when(sessionRepo.findByUuidAndDeletedAtIsNull(sessionId))
                .thenReturn(Optional.of(sessionOwnedByUser(sessionId, user.getId())));

        chatService.changePace(userUuid, sessionId, 1500);

        verify(gateway).control(sessionId.toString(), "CHANGE_PACE", 1500);
    }

    @Test
    @DisplayName("세션 소유자가 아니면 FORBIDDEN 예외가 발생한다")
    void forbiddenWhenNotOwner() {
        UUID sessionId = UUID.randomUUID();
        when(sessionRepo.findByUuidAndDeletedAtIsNull(sessionId))
                .thenReturn(Optional.of(sessionOwnedByUser(sessionId, 999)));

        assertThatThrownBy(() -> chatService.resume(userUuid, sessionId))
                .isInstanceOf(AppException.class)
                .satisfies(ex -> assertThat(((AppException) ex).getCode()).isEqualTo(ErrorCode.FORBIDDEN));
    }

    @Test
    @DisplayName("history2는 내림차순 페치 후 과거→최신으로 반환하고 nextCursor를 설정한다")
    void history2OrdersAndSetsCursor() {
        UUID sessionId = UUID.randomUUID();
        when(sessionRepo.findByUuidAndDeletedAtIsNull(sessionId))
                .thenReturn(Optional.of(sessionOwnedByUser(sessionId, user.getId())));

        String id3 = new ObjectId().toHexString();
        String id2 = new ObjectId().toHexString();
        String id1 = new ObjectId().toHexString();
        Instant now = Instant.now();
        List<ChatMessageDoc> docsDesc = List.of(
                ChatMessageDoc.builder().id(id3).sessionUuid(sessionId).role("assistant").content("c3").ts(now).build(),
                ChatMessageDoc.builder().id(id2).sessionUuid(sessionId).role("assistant").content("c2").ts(now.minusSeconds(1)).build(),
                ChatMessageDoc.builder().id(id1).sessionUuid(sessionId).role("assistant").content("c1").ts(now.minusSeconds(2)).build()
        );
        when(msgRepo.pageFirst(eq(sessionId), any())).thenReturn(docsDesc);

        HistoryCursorResponse res = chatService.history2(userUuid, sessionId, 2, null);

        assertThat(res.isHasMore()).isTrue();
        assertThat(res.getNextCursor()).isEqualTo(id2); // slice last element id
        assertThat(res.getItems()).hasSize(2);
        assertThat(res.getItems().get(0).getId()).isEqualTo(id2); // 과거→최신
        assertThat(res.getItems().get(1).getId()).isEqualTo(id3);
    }

    @Test
    @DisplayName("Last-Event-ID가 주어지면 Mongo 이후 메시지를 재전송한다")
    void streamAssistantReplaysMissedMessages() throws Exception {
        UUID sessionId = UUID.randomUUID();
        when(sessionRepo.findByUuidAndDeletedAtIsNull(sessionId))
                .thenReturn(Optional.of(sessionOwnedByUser(sessionId, user.getId())));

        String lastId = new ObjectId().toHexString();
        ChatMessageDoc doc1 = ChatMessageDoc.builder().id(new ObjectId().toHexString()).sessionUuid(sessionId).content("c1").ts(Instant.now()).build();
        ChatMessageDoc doc2 = ChatMessageDoc.builder().id(new ObjectId().toHexString()).sessionUuid(sessionId).content("c2").ts(Instant.now()).build();
        when(msgRepo.findAfterId(sessionId, new ObjectId(lastId))).thenReturn(List.of(doc1, doc2));

        SseEmitter emitter = org.mockito.Mockito.spy(new SseEmitter());
        var captured = new CopyOnWriteArrayList<SseEmitter.SseEventBuilder>();
        org.mockito.Mockito.doAnswer(inv -> { captured.add(inv.getArgument(0)); return null; })
                .when(emitter).send(any(SseEmitter.SseEventBuilder.class));
        when(emitterRegistry.create(eq(sessionId), any(), any())).thenReturn(emitter);

        when(gateway.stream(sessionId.toString())).thenReturn(reactor.core.publisher.Flux.never());

        chatService.streamAssistant(userUuid, sessionId, "dev-1", lastId);

        assertThat(captured).hasSize(2);
        assertThat(getField(captured.get(0), "name")).isEqualTo("message");
        assertThat(getField(captured.get(0), "id")).isEqualTo(doc1.getId());
        assertThat(getField(captured.get(1), "id")).isEqualTo(doc2.getId());
        assertThat(getField(captured.get(0), "data")).isEqualTo("c1");
    }

    @Test
    @DisplayName("ready 이벤트를 수신하면 클라이언트로 전달한다")
    void streamAssistantBridgesReadyEvent() throws Exception {
        UUID sessionId = UUID.randomUUID();
        when(sessionRepo.findByUuidAndDeletedAtIsNull(sessionId))
                .thenReturn(Optional.of(sessionOwnedByUser(sessionId, user.getId())));

        SseEmitter emitter = org.mockito.Mockito.spy(new SseEmitter());
        var captured = new CopyOnWriteArrayList<SseEmitter.SseEventBuilder>();
        org.mockito.Mockito.doAnswer(inv -> { captured.add(inv.getArgument(0)); return null; })
                .when(emitter).send(any(SseEmitter.SseEventBuilder.class));
        when(emitterRegistry.create(eq(sessionId), any(), any())).thenReturn(emitter);

        var ready = org.springframework.http.codec.ServerSentEvent.<String>builder()
                .event("ready")
                .id("1")
                .data("ok")
                .build();
        when(gateway.stream(sessionId.toString())).thenReturn(reactor.core.publisher.Flux.just(ready));

        chatService.streamAssistant(userUuid, sessionId, "dev-1", null);

        // subscribe는 비동기지만 단일 ready 이벤트라 즉시 처리
        assertThat(captured).isNotEmpty();
        assertThat(getField(captured.get(0), "name")).isEqualTo("ready");
        assertThat(getField(captured.get(0), "id")).isEqualTo("1");
    }

    private static Object getField(Object target, String name) {
        return ReflectionTestUtils.getField(target, name);
    }
}
