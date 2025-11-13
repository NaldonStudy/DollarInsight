package com.ssafy.b205.backend.domain.device.entity;

import com.ssafy.b205.backend.domain.user.entity.User;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcType;
import org.hibernate.dialect.PostgreSQLEnumJdbcType;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@Builder
@Entity
@Table(
        name = "user_device",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uq_user_device_user_and_device",
                        columnNames = {"user_id", "device_id"}
                )
        }
)
public class UserDevice {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(nullable = false, columnDefinition = "uuid default gen_random_uuid()")
    private UUID uuid;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "device_id", nullable = false, length = 128)
    private String deviceId;

    @Enumerated(EnumType.STRING)
    @JdbcType(PostgreSQLEnumJdbcType.class)
    @Column(name = "platform", nullable = false, columnDefinition = "platform_type")
    private PlatformType platform;

    @Column(name = "push_token")
    private String pushToken;

    @Column(name = "is_push_enabled", nullable = false)
    private boolean pushEnabled;

    @Column(name = "last_activate_at")
    private LocalDateTime lastActivateAt;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @PrePersist
    void onCreate() {
        if (uuid == null) uuid = UUID.randomUUID();
        if (createdAt == null) createdAt = LocalDateTime.now();
        if (lastActivateAt == null) lastActivateAt = LocalDateTime.now();
    }

    public UserDevice activateNow() {
        this.lastActivateAt = LocalDateTime.now();
        return this;
    }

    public UserDevice updatePush(String token, boolean enabled) {
        this.pushToken = token;
        this.pushEnabled = enabled;
        return this;
    }
}
