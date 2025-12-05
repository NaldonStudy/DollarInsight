package com.ssafy.b205.backend.domain.chat.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;

@Getter
public class AppendMessageRequest {
    @Schema(example = "NVIDIA 전망 요약해줘")
    @NotBlank
    private String content;
}
