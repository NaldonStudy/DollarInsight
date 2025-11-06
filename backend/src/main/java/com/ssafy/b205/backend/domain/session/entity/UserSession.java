package com.ssafy.b205.backend.domain.session.entity;

import com.ssafy.b205.backend.domain.device.entity.UserDevice;
import com.ssafy.b205.backend.domain.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@Builder
@Entity @Table(name = "user_session")
public class UserSession {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(nullable = false, columnDefinition = "uuid default gen_random_uuid()")
    private UUID uuid;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_device_id", nullable = false) // V2 반영
    private UserDevice userDevice;

    @Column(name = "refresh_token_hash", nullable = false, unique = true)
    private String refreshTokenHash;

    @Column(name = "issued_at", nullable = false)
    private LocalDateTime issuedAt;

    @Column(name = "expires_at")
    private LocalDateTime expiresAt;

    @Column(name = "revoked_at")
    private LocalDateTime revokedAt;

    @Column(name = "revoke_reason")
    private String revokeReason;

    @PrePersist
    void onCreate() {
        if (uuid == null) uuid = UUID.randomUUID();
        if (issuedAt == null) issuedAt = LocalDateTime.now();
    }

    public boolean isActive() {
        return revokedAt == null && (expiresAt == null || expiresAt.isAfter(LocalDateTime.now()));
    }

    public void revoke(String reason) {
        if (this.revokedAt == null) {              // 이미 취소된 세션이면 그대로 둠(멱등)
            this.revokedAt = java.time.LocalDateTime.now();
            this.revokeReason = reason;            // 컬럼이 있으면 사유 저장
        }
    }
}
