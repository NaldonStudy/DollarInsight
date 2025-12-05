package com.ssafy.b205.backend.domain.persona.entity;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "user_personas",
        indexes = { @Index(name = "ux_user_persona", columnList = "user_id, persona_id", unique = true) })
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class UserPersona {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "user_id", nullable = false)
    private Integer userId;

    @Column(name = "persona_id", nullable = false)
    private Integer personaId;

    @Column(nullable = false)
    private boolean enabled = true;

    public void changeEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    public static UserPersona of(Integer userId, Integer personaId, boolean enabled) {
        UserPersona up = new UserPersona();
        up.userId = userId;
        up.personaId = personaId;
        up.enabled = enabled;
        return up;
    }
}
