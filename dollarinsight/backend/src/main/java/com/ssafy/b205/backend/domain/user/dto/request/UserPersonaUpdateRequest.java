package com.ssafy.b205.backend.domain.user.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import lombok.Getter;

import java.util.List;

@Getter
public class UserPersonaUpdateRequest {

    @NotEmpty
    private List<@NotBlank String> personaCodes;

    public UserPersonaUpdateRequest() {}

    public UserPersonaUpdateRequest(List<String> personaCodes) {
        this.personaCodes = personaCodes;
    }
}
