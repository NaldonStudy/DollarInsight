package com.ssafy.b205.backend.auth.application;

import com.ssafy.b205.backend.user.adapter.web.dto.request.LoginRequest;
import com.ssafy.b205.backend.user.adapter.web.dto.request.SignupRequest;
import com.ssafy.b205.backend.user.adapter.web.dto.response.TokenPairResponse;

public interface AuthApplicationService {
    TokenPairResponse signupAndIssue(SignupRequest req, String deviceId);
    TokenPairResponse loginAndIssue(LoginRequest req, String deviceId);
}
