package com.ssafy.b205.backend.domain.auth.service;

import com.ssafy.b205.backend.domain.user.dto.request.LoginRequest;
import com.ssafy.b205.backend.domain.user.dto.request.SignupRequest;
import com.ssafy.b205.backend.domain.user.dto.response.TokenPairResponse;

public interface AuthApplicationService {
    TokenPairResponse signupAndIssue(SignupRequest req, String deviceId);
    TokenPairResponse loginAndIssue(LoginRequest req, String deviceId);
}
