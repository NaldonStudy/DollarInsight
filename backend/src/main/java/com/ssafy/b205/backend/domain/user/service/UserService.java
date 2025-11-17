package com.ssafy.b205.backend.domain.user.service;

import com.ssafy.b205.backend.domain.user.entity.User;

import java.util.List;

public interface UserService {
    User signup(String email, String nickname, String rawPassword);
    String issueAccess(String email, String rawPassword, String deviceId); // 로그인 시 access 발급
    String createAccessFor(User user, String deviceId);
    User getByEmailActive(String email);
    User getByUuid(String userUuid);
    void changeNickname(String userUuid, String nickname);
    void changePassword(String userUuid, String oldPassword, String newPassword);
    void changePersonas(String userUuid, List<String> personaCodes);
    void softDelete(String userUuid);
}
