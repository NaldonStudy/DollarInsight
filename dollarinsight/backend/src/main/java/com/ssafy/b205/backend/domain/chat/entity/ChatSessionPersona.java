package com.ssafy.b205.backend.domain.chat.entity;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "chat_session_personas",
        uniqueConstraints = @UniqueConstraint(name="ux_csp_session_persona", columnNames={"session_id","persona_id"}))
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class ChatSessionPersona {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "session_id", nullable = false)
    private Integer sessionId;

    @Column(name = "persona_id", nullable = false)
    private Integer personaId;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    public static ChatSessionPersona of(Integer sessionId, Integer personaId) {
        ChatSessionPersona csp = new ChatSessionPersona();
        csp.sessionId = sessionId;
        csp.personaId = personaId;
        return csp;
    }
}
