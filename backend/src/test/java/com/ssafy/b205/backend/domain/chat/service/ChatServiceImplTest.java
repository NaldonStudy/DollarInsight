package com.ssafy.b205.backend.domain.chat.service;

import com.ssafy.b205.backend.domain.chat.dto.request.AppendMessageRequest;
import com.ssafy.b205.backend.domain.chat.dto.request.CreateSessionRequest;
import com.ssafy.b205.backend.domain.chat.dto.response.AppendMessageResponse;
import com.ssafy.b205.backend.domain.chat.dto.response.ChatSessionSummaryResponse;
import com.ssafy.b205.backend.domain.chat.dto.response.CreateSessionResponse;
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
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.transaction.PlatformTransactionManager;

import java.time.Instant;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ChatServiceImplTest {

    @Mock
    private ChatSessionRepository sessionRepository;
    @Mock
    private ChatSessionPersonaRepository sessionPersonaRepository;
    @Mock
    private ChatMessageRepository messageRepository;
    @Mock
    private PersonaRepository personaRepository;
    @Mock
    private UserRepository userRepository;
    @Mock
    private FastAiGateway fastAiGateway;
    @Mock
    private SseEmitterRegistry emitterRegistry;
    @Mock
    private PlatformTransactionManager transactionManager;

    private ChatServiceImpl chatService;

    @BeforeEach
    void setUp() {
        chatService = new ChatServiceImpl(
                sessionRepository,
                sessionPersonaRepository,
                messageRepository,
                personaRepository,
                userRepository,
                fastAiGateway,
                emitterRegistry,
                transactionManager
        );
    }

    @Test
    void createSessionPersistsSessionAndPersonas() {
        User user = createUser();
        when(userRepository.findByUuidAndDeletedAtIsNull(user.getUuid())).thenReturn(Optional.of(user));
        Persona persona = mock(Persona.class);
        when(persona.getCode()).thenReturn("Alpha");
        when(persona.getId()).thenReturn(10);
        when(personaRepository.findEnabledByUserId(user.getId())).thenReturn(List.of(persona));
        ChatSession session = newChatSession(user);
        when(sessionRepository.save(any(ChatSession.class))).thenReturn(session);

        CreateSessionRequest req = new CreateSessionRequest();
        ReflectionTestUtils.setField(req, "topicType", ChatTopicType.CUSTOM);
        ReflectionTestUtils.setField(req, "title", "title");
        CreateSessionResponse response = chatService.createSession(user.getUuid().toString(), req);

        assertThat(response.getPersonas()).containsExactly("Alpha");
        verify(sessionPersonaRepository).saveAll(anyList());
    }

    @Test
    void listSessionsReturnsPagedResponse() {
        User user = createUser();
        when(userRepository.findByUuidAndDeletedAtIsNull(user.getUuid())).thenReturn(Optional.of(user));
        ChatSession session = newChatSession(user);
        Page<ChatSession> page = new PageImpl<>(List.of(session));
        when(sessionRepository.findByUserIdAndDeletedAtIsNull(eq(user.getId()), any(PageRequest.class)))
                .thenReturn(page);

        PageResponse<ChatSessionSummaryResponse> response = chatService.listSessions(user.getUuid().toString(), 0, 10);

        assertThat(response.getItems()).hasSize(1);
        assertThat(response.getItems().getFirst().getTitle()).isEqualTo("title");
    }

    @Test
    void appendUserMessageStartsGatewayOnFirstMessage() {
        User user = createUser();
        when(userRepository.findByUuidAndDeletedAtIsNull(user.getUuid())).thenReturn(Optional.of(user));
        ChatSession session = newChatSession(user);
        UUID sessionUuid = session.getUuid();
        when(sessionRepository.findByUuidAndDeletedAtIsNull(sessionUuid)).thenReturn(Optional.of(session));
        when(messageRepository.save(any(ChatMessageDoc.class))).thenAnswer(invocation -> {
            ChatMessageDoc doc = invocation.getArgument(0);
            ReflectionTestUtils.setField(doc, "id", "msg-1");
            return doc;
        });
        when(messageRepository.countBySessionUuidAndRole(sessionUuid, "user")).thenReturn(1L);
        when(sessionPersonaRepository.findPersonaIdsBySessionId(session.getId())).thenReturn(List.of(1));
        Persona persona = mock(Persona.class);
        when(persona.getCode()).thenReturn("Alpha");
        when(personaRepository.findAllById(List.of(1))).thenReturn(List.of(persona));
        AppendMessageRequest req = new AppendMessageRequest();
        ReflectionTestUtils.setField(req, "content", "hello");

        AppendMessageResponse response = chatService.appendUserMessage(user.getUuid().toString(), sessionUuid, req);

        assertThat(response.getMessageId()).isNotBlank();
        verify(fastAiGateway).start(eq(sessionUuid.toString()), eq("hello"), anyInt(), eq(List.of("Alpha")));
    }

    @Test
    void appendUserMessageSendsInputWhenNotFirst() {
        User user = createUser();
        when(userRepository.findByUuidAndDeletedAtIsNull(user.getUuid())).thenReturn(Optional.of(user));
        ChatSession session = newChatSession(user);
        UUID sessionUuid = session.getUuid();
        when(sessionRepository.findByUuidAndDeletedAtIsNull(sessionUuid)).thenReturn(Optional.of(session));
        when(messageRepository.save(any(ChatMessageDoc.class))).thenAnswer(invocation -> {
            ChatMessageDoc doc = invocation.getArgument(0);
            ReflectionTestUtils.setField(doc, "id", "msg-2");
            return doc;
        });
        when(messageRepository.countBySessionUuidAndRole(sessionUuid, "user")).thenReturn(2L);
        AppendMessageRequest req = new AppendMessageRequest();
        ReflectionTestUtils.setField(req, "content", "follow up");

        chatService.appendUserMessage(user.getUuid().toString(), sessionUuid, req);

        verify(fastAiGateway).sendUserInput(sessionUuid.toString(), "follow up");
    }

    @Test
    void interruptDelegatesToGateway() {
        User user = createUser();
        when(userRepository.findByUuidAndDeletedAtIsNull(user.getUuid())).thenReturn(Optional.of(user));
        ChatSession session = newChatSession(user);
        UUID sessionUuid = session.getUuid();
        when(sessionRepository.findByUuidAndDeletedAtIsNull(sessionUuid)).thenReturn(Optional.of(session));

        chatService.interrupt(user.getUuid().toString(), sessionUuid);

        verify(fastAiGateway).control(sessionUuid.toString(), "STOP", null);
    }

    @Test
    void interruptWrapsGatewayErrors() {
        User user = createUser();
        when(userRepository.findByUuidAndDeletedAtIsNull(user.getUuid())).thenReturn(Optional.of(user));
        ChatSession session = newChatSession(user);
        UUID sessionUuid = session.getUuid();
        when(sessionRepository.findByUuidAndDeletedAtIsNull(sessionUuid)).thenReturn(Optional.of(session));
        doThrow(new RuntimeException("fail")).when(fastAiGateway).control(anyString(), anyString(), any());

        assertThatThrownBy(() -> chatService.interrupt(user.getUuid().toString(), sessionUuid))
                .isInstanceOf(AppException.class)
                .hasFieldOrPropertyWithValue("code", ErrorCode.BAD_REQUEST);
    }

    @Test
    void historyReturnsMessagesOrderedAscending() {
        User user = createUser();
        when(userRepository.findByUuidAndDeletedAtIsNull(user.getUuid())).thenReturn(Optional.of(user));
        ChatSession session = newChatSession(user);
        UUID sessionUuid = session.getUuid();
        when(sessionRepository.findByUuidAndDeletedAtIsNull(sessionUuid)).thenReturn(Optional.of(session));
        ChatMessageDoc doc1 = ChatMessageDoc.builder().id("1").content("z").ts(Instant.now()).build();
        ChatMessageDoc doc2 = ChatMessageDoc.builder().id("2").content("a").ts(Instant.now()).build();
        when(messageRepository.findBySessionUuidOrderByTsDesc(eq(sessionUuid), any(PageRequest.class)))
                .thenReturn(new PageImpl<>(List.of(doc1, doc2)));

        var history = chatService.history(user.getUuid().toString(), sessionUuid, 10);

        assertThat(history.getItems()).hasSize(2);
        assertThat(history.getItems().getFirst().getContent()).isEqualTo("a");
    }

    private User createUser() {
        return User.builder()
                .id(1)
                .uuid(UUID.randomUUID())
                .email("user@example.com")
                .nickname("User")
                .status(UserStatus.ACTIVE)
                .build();
    }

    private ChatSession newChatSession(User user) {
        ChatSession session = ChatSession.create(user.getId(), ChatTopicType.CUSTOM, "title", null, null);
        ReflectionTestUtils.setField(session, "id", 10);
        ReflectionTestUtils.setField(session, "uuid", UUID.randomUUID());
        ReflectionTestUtils.setField(session, "createdAt", OffsetDateTime.now());
        return session;
    }
}
