package com.ssafy.b205.backend.domain.user.dto.response;

import com.ssafy.b205.backend.domain.user.entity.User;
import com.ssafy.b205.backend.domain.user.entity.UserStatus;
import lombok.Getter;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;   // ★ 추가
import java.util.UUID;

@Getter
public class UserResponse {
    private final UUID uuid;
    private final String email;
    private final String nickname;
    private final UserStatus status;
    private final Instant createdAt;   // Instant(UTC)
    private final Instant updatedAt;   // Instant(UTC)

    public UserResponse(User u) {
        this.uuid = u.getUuid();
        this.email = u.getEmail();
        this.nickname = u.getNickname();
        this.status = u.getStatus();
        this.createdAt = toUtc(u.getCreatedAt());
        this.updatedAt = toUtc(u.getUpdatedAt());
    }

    private static Instant toUtc(LocalDateTime ldt) {
        return (ldt == null) ? null : ldt.atOffset(ZoneOffset.UTC).toInstant();
    }
}
