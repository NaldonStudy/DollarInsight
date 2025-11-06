package com.ssafy.b205.backend.domain.user.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;

@Getter
public class PasswordChangeRequest {
    @NotBlank private String oldPassword;
    @NotBlank @Size(min = 8, max = 64)
    private String newPassword;

    public PasswordChangeRequest() {}
    public PasswordChangeRequest(String oldPassword, String newPassword) {
        this.oldPassword = oldPassword;
        this.newPassword = newPassword;
    }
}
