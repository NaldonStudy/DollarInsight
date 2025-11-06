package com.ssafy.b205.backend.domain.user.service;

import com.ssafy.b205.backend.domain.user.entity.User;

public interface UserService {
    User signup(String email, String nickname, String rawPassword);
    String issueAccess(String email, String rawPassword, String deviceId); // 로그인 시 access 발급
    String createAccessFor(User user, String deviceId);
    User getByEmailActive(String email);
    User getByUuid(String userUuid);
}
