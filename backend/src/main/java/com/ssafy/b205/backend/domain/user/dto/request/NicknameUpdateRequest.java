package com.ssafy.b205.backend.domain.user.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;

@Getter
public class NicknameUpdateRequest {
    @NotBlank @Size(min = 2, max = 20)
    private String nickname;

    public NicknameUpdateRequest() {} // for JSON
    public NicknameUpdateRequest(String nickname) { this.nickname = nickname; }
}
