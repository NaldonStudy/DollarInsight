package com.ssafy.b205.backend.domain.chat.service;

import com.ssafy.b205.backend.domain.chat.dto.request.AppendMessageRequest;
import com.ssafy.b205.backend.domain.chat.dto.request.CreateSessionRequest;
import com.ssafy.b205.backend.domain.chat.dto.response.AppendMessageResponse;
import com.ssafy.b205.backend.domain.chat.dto.response.ChatSessionSummaryResponse;
import com.ssafy.b205.backend.domain.chat.dto.response.CreateSessionResponse;
import com.ssafy.b205.backend.domain.chat.dto.response.HistoryCursorResponse;
import com.ssafy.b205.backend.domain.chat.entity.ChatSession;
import com.ssafy.b205.backend.domain.chat.entity.ChatTopicType;
import com.ssafy.b205.backend.domain.chat.repository.ChatSessionPersonaRepository;
import com.ssafy.b205.backend.domain.chat.repository.ChatSessionRepository;
import com.ssafy.b205.backend.domain.persona.entity.Persona;
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
import com.ssafy.b205.backend.support.response.PageResponse;
import org.bson.types.ObjectId;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;
import reactor.core.publisher.Flux;

import java.io.IOException;
import java.lang.reflect.Method;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.CopyOnWriteArrayList;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

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

    private ChatServiceImpl chatService;

    @BeforeEach
    void setUp() {
        chatService = new ChatServiceImpl(
                sessionRepo, cspRepo, msgRepo, personaRepo, userRepository,
                gateway, emitterRegistry, txManager
        );
    }

    @Test
    @DisplayName("세션 생성 시 페르소나 스냅샷을 저장하고 응답에 코드가 포함된다")
    void createSessionPersistsSessionAndPersonas() {
        User user = createUser();
        when(userRepository.findByUuidAndDeletedAtIsNull(user.getUuid())).thenReturn(Optional.of(user));
        Persona persona = mock(Persona.class);
        when(persona.getCode()).thenReturn("Alpha");
        when(persona.getId()).thenReturn(10);
        when(personaRepo.findEnabledByUserId(user.getId())).thenReturn(List.of(persona));
        ChatSession session = newChatSession(user);
        when(sessionRepo.save(any(ChatSession.class))).thenReturn(session);
        doNothing().when(gateway).start(anyString(), anyString(), anyInt(), anyList());

        CreateSessionRequest req = new CreateSessionRequest();
        ReflectionTestUtils.setField(req, "topicType", ChatTopicType.CUSTOM);
        ReflectionTestUtils.setField(req, "title", "title");

        CreateSessionResponse response = chatService.createSession(user.getUuid().toString(), req);

        assertThat(response.getPersonas()).containsExactly("Alpha");
        verify(cspRepo).saveAll(anyList());
    }

    @Test
    @DisplayName("세션 목록을 페이지 단위로 반환한다")
    void listSessionsReturnsPagedResponse() {
        User user = createUser();
        when(userRepository.findByUuidAndDeletedAtIsNull(user.getUuid())).thenReturn(Optional.of(user));
        ChatSession session = newChatSession(user);
        Page<ChatSession> page = new PageImpl<>(List.of(session));
        when(sessionRepo.findByUserIdAndDeletedAtIsNull(eq(user.getId()), any(PageRequest.class)))
                .thenReturn(page);

        PageResponse<ChatSessionSummaryResponse> response = chatService.listSessions(user.getUuid().toString(), 0, 10);

        assertThat(response.getItems()).hasSize(1);
        assertThat(response.getItems().getFirst().getTitle()).isEqualTo("title");
    }

    @Test
    @DisplayName("첫 사용자 메시지면 FastAI start를 호출한다")
    void appendUserMessageStartsGatewayOnFirstMessage() {
        User user = createUser();
        when(userRepository.findByUuidAndDeletedAtIsNull(user.getUuid())).thenReturn(Optional.of(user));
        ChatSession session = newChatSession(user);
        UUID sessionUuid = session.getUuid();
        when(sessionRepo.findByUuidAndDeletedAtIsNull(sessionUuid)).thenReturn(Optional.of(session));
        when(msgRepo.save(any(ChatMessageDoc.class))).thenAnswer(inv -> {
            ChatMessageDoc doc = inv.getArgument(0);
            ReflectionTestUtils.setField(doc, "id", "msg-1");
            return doc;
        });
        when(msgRepo.countBySessionUuidAndRole(sessionUuid, "user")).thenReturn(1L);
        when(cspRepo.findPersonaIdsBySessionId(session.getId())).thenReturn(List.of(1));
        Persona persona = mock(Persona.class);
        when(persona.getCode()).thenReturn("Alpha");
        when(personaRepo.findAllById(List.of(1))).thenReturn(List.of(persona));

        AppendMessageRequest req = new AppendMessageRequest();
        ReflectionTestUtils.setField(req, "content", "hello");

        AppendMessageResponse response = chatService.appendUserMessage(user.getUuid().toString(), sessionUuid, req);

        assertThat(response.getMessageId()).isNotBlank();
        verify(gateway).start(eq(sessionUuid.toString()), eq("hello"), anyInt(), eq(List.of("Alpha")));
    }

    @Test
    @DisplayName("첫 메시지가 아니면 FastAI input을 호출한다")
    void appendUserMessageSendsInputWhenNotFirst() {
        User user = createUser();
        when(userRepository.findByUuidAndDeletedAtIsNull(user.getUuid())).thenReturn(Optional.of(user));
        ChatSession session = newChatSession(user);
        UUID sessionUuid = session.getUuid();
        when(sessionRepo.findByUuidAndDeletedAtIsNull(sessionUuid)).thenReturn(Optional.of(session));
        when(msgRepo.save(any(ChatMessageDoc.class))).thenAnswer(inv -> {
            ChatMessageDoc doc = inv.getArgument(0);
            ReflectionTestUtils.setField(doc, "id", "msg-2");
            return doc;
        });
        when(msgRepo.countBySessionUuidAndRole(sessionUuid, "user")).thenReturn(2L);

        AppendMessageRequest req = new AppendMessageRequest();
        ReflectionTestUtils.setField(req, "content", "follow up");

        chatService.appendUserMessage(user.getUuid().toString(), sessionUuid, req);

        verify(gateway).sendUserInput(sessionUuid.toString(), "follow up");
    }

    @Test
    @DisplayName("interrupt/resume/changePace는 제어 신호를 위임한다")
    void controlDelegates() {
        User user = createUser();
        when(userRepository.findByUuidAndDeletedAtIsNull(user.getUuid())).thenReturn(Optional.of(user));
        ChatSession session = newChatSession(user);
        UUID sessionUuid = session.getUuid();
        when(sessionRepo.findByUuidAndDeletedAtIsNull(sessionUuid)).thenReturn(Optional.of(session));

        chatService.interrupt(user.getUuid().toString(), sessionUuid);
        chatService.resume(user.getUuid().toString(), sessionUuid);
        chatService.changePace(user.getUuid().toString(), sessionUuid, 1500);

        verify(gateway).control(sessionUuid.toString(), "STOP", null);
        verify(gateway).control(sessionUuid.toString(), "RESUME", null);
        verify(gateway).control(sessionUuid.toString(), "CHANGE_PACE", 1500);
    }

    @Test
    @DisplayName("gateway 오류 시 interrupt는 AppException으로 변환한다")
    void interruptWrapsGatewayErrors() {
        User user = createUser();
        when(userRepository.findByUuidAndDeletedAtIsNull(user.getUuid())).thenReturn(Optional.of(user));
        ChatSession session = newChatSession(user);
        UUID sessionUuid = session.getUuid();
        when(sessionRepo.findByUuidAndDeletedAtIsNull(sessionUuid)).thenReturn(Optional.of(session));
        doThrow(new RuntimeException("fail")).when(gateway).control(anyString(), anyString(), any());

        assertThatThrownBy(() -> chatService.interrupt(user.getUuid().toString(), sessionUuid))
                .isInstanceOf(AppException.class)
                .hasFieldOrPropertyWithValue("code", ErrorCode.BAD_REQUEST);
    }

    @Test
    @DisplayName("세션 소유자가 아니면 FORBIDDEN을 반환한다")
    void forbiddenWhenNotOwner() {
        User user = createUser();
        when(userRepository.findByUuidAndDeletedAtIsNull(user.getUuid())).thenReturn(Optional.of(user));
        ChatSession session = newChatSession(user);
        ReflectionTestUtils.setField(session, "userId", 999);
        UUID sessionUuid = session.getUuid();
        when(sessionRepo.findByUuidAndDeletedAtIsNull(sessionUuid)).thenReturn(Optional.of(session));

        assertThatThrownBy(() -> chatService.resume(user.getUuid().toString(), sessionUuid))
                .isInstanceOf(AppException.class)
                .hasFieldOrPropertyWithValue("code", ErrorCode.FORBIDDEN);
    }

    @Test
    @DisplayName("history2는 커서 기준으로 정렬/hasMore/nextCursor를 설정한다")
    void history2OrdersAndSetsCursor() {
        User user = createUser();
        when(userRepository.findByUuidAndDeletedAtIsNull(user.getUuid())).thenReturn(Optional.of(user));
        ChatSession session = newChatSession(user);
        UUID sessionUuid = session.getUuid();
        when(sessionRepo.findByUuidAndDeletedAtIsNull(sessionUuid)).thenReturn(Optional.of(session));

        String id3 = new ObjectId().toHexString();
        String id2 = new ObjectId().toHexString();
        String id1 = new ObjectId().toHexString();
        Instant now = Instant.now();
        List<ChatMessageDoc> docsDesc = List.of(
                ChatMessageDoc.builder().id(id3).sessionUuid(sessionUuid).role("assistant").content("c3").ts(now).build(),
                ChatMessageDoc.builder().id(id2).sessionUuid(sessionUuid).role("assistant").content("c2").ts(now.minusSeconds(1)).build(),
                ChatMessageDoc.builder().id(id1).sessionUuid(sessionUuid).role("assistant").content("c1").ts(now.minusSeconds(2)).build()
        );
        when(msgRepo.pageFirst(eq(sessionUuid), any())).thenReturn(docsDesc);

        HistoryCursorResponse res = chatService.history2(user.getUuid().toString(), sessionUuid, 2, null);

        assertThat(res.isHasMore()).isTrue();
        assertThat(res.getNextCursor()).isEqualTo(id2);
        assertThat(res.getItems()).hasSize(2);
        assertThat(res.getItems().get(0).getId()).isEqualTo(id2);
        assertThat(res.getItems().get(1).getId()).isEqualTo(id3);
    }

    @Test
    @DisplayName("Last-Event-ID가 주어지면 이후 메시지를 재전송한다")
    void streamAssistantReplaysMissedMessages() throws Exception {
        User user = createUser();
        when(userRepository.findByUuidAndDeletedAtIsNull(user.getUuid())).thenReturn(Optional.of(user));
        ChatSession session = newChatSession(user);
        UUID sessionId = session.getUuid();
        when(sessionRepo.findByUuidAndDeletedAtIsNull(sessionId)).thenReturn(Optional.of(session));

        String lastId = new ObjectId().toHexString();
        ChatMessageDoc doc1 = ChatMessageDoc.builder().id(new ObjectId().toHexString()).sessionUuid(sessionId).content("c1").ts(Instant.now()).build();
        ChatMessageDoc doc2 = ChatMessageDoc.builder().id(new ObjectId().toHexString()).sessionUuid(sessionId).content("c2").ts(Instant.now()).build();
        when(msgRepo.findAfterId(sessionId, new ObjectId(lastId))).thenReturn(List.of(doc1, doc2));

        CapturingEmitter emitter = new CapturingEmitter();
        when(emitterRegistry.create(eq(sessionId), any(), any())).thenReturn(emitter);
        when(gateway.stream(sessionId.toString())).thenReturn(Flux.never());

        chatService.streamAssistant(user.getUuid().toString(), sessionId, "dev-1", lastId);

        assertThat(emitter.sent).hasSize(2);
        assertThat(eventName(emitter.sent.get(0))).isEqualTo("message");
        assertThat(eventId(emitter.sent.get(0))).isEqualTo(doc1.getId());
        assertThat(eventId(emitter.sent.get(1))).isEqualTo(doc2.getId());
        assertThat(eventData(emitter.sent.get(0))).isEqualTo("c1");
    }

    @Test
    @DisplayName("ready 이벤트를 브리지한다")
    void streamAssistantBridgesReadyEvent() throws Exception {
        User user = createUser();
        when(userRepository.findByUuidAndDeletedAtIsNull(user.getUuid())).thenReturn(Optional.of(user));
        ChatSession session = newChatSession(user);
        UUID sessionId = session.getUuid();
        when(sessionRepo.findByUuidAndDeletedAtIsNull(sessionId)).thenReturn(Optional.of(session));

        CapturingEmitter emitter = new CapturingEmitter();
        when(emitterRegistry.create(eq(sessionId), any(), any())).thenReturn(emitter);
        var ready = org.springframework.http.codec.ServerSentEvent.<String>builder()
                .event("ready")
                .id("1")
                .data("ok")
                .build();
        when(gateway.stream(sessionId.toString())).thenReturn(Flux.just(ready));

        chatService.streamAssistant(user.getUuid().toString(), sessionId, "dev-1", null);

        assertThat(emitter.sent).isNotEmpty();
        assertThat(eventName(emitter.sent.get(0))).isEqualTo("ready");
        assertThat(eventId(emitter.sent.get(0))).isEqualTo("1");
    }

    private User createUser() {
        return User.builder()
                .id(1)
                .uuid(UUID.randomUUID())
                .email("user@example.com")
                .nickname("User")
                .status(UserStatus.ACTIVE)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
    }

    private ChatSession newChatSession(User user) {
        ChatSession session = ChatSession.create(user.getId(), ChatTopicType.CUSTOM, "title", null, null);
        ReflectionTestUtils.setField(session, "id", 10);
        ReflectionTestUtils.setField(session, "uuid", UUID.randomUUID());
        ReflectionTestUtils.setField(session, "createdAt", OffsetDateTime.now());
        return session;
    }

    private static String eventId(Object event) {
        return (String) ReflectionTestUtils.invokeMethod(event, "getId");
    }

    private static String eventName(Object event) {
        return (String) ReflectionTestUtils.invokeMethod(event, "getName");
    }

    private static Object eventData(Object event) {
        return ReflectionTestUtils.invokeMethod(event, "getData");
    }

    private static class CapturingEmitter extends SseEmitter {
        private final List<Object> sent = new CopyOnWriteArrayList<>();
        private final Method buildMethod;

        private CapturingEmitter() {
            try {
                buildMethod = SseEventBuilder.class.getDeclaredMethod("build");
                buildMethod.setAccessible(true);
            } catch (Exception e) {
                throw new IllegalStateException("SseEventBuilder.build() not accessible", e);
            }
        }

        @Override
        public void send(SseEventBuilder builder) throws IOException {
            try {
                Object event = buildMethod.invoke(builder);
                sent.add(event);
            } catch (Exception e) {
                throw new IOException("Failed to build SseEvent", e);
            }
        }
    }
}
