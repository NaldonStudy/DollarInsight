package com.ssafy.b205.backend.domain.user.dto.request;

import com.ssafy.b205.backend.support.validation.StrongPassword;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter @NoArgsConstructor
public class SignupRequest {
    @Email @NotBlank private String email;
    @NotBlank private String nickname;
    @StrongPassword private String password;
    private Boolean pushEnabled = Boolean.FALSE;
}
