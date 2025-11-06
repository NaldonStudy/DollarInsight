package com.ssafy.b205.backend.domain.user.dto.response;

import com.ssafy.b205.backend.domain.user.entity.User;
import com.ssafy.b205.backend.domain.user.entity.UserStatus;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
public class UserResponse {
    private final UUID uuid;
    private final String email;
    private final String nickname;
    private final UserStatus status;
    private final LocalDateTime createdAt;
    private final LocalDateTime updatedAt;

    public UserResponse(User u) {
        this.uuid = u.getUuid();
        this.email = u.getEmail();
        this.nickname = u.getNickname();
        this.status = u.getStatus();
        this.createdAt = u.getCreatedAt();
        this.updatedAt = u.getUpdatedAt();
    }
}
