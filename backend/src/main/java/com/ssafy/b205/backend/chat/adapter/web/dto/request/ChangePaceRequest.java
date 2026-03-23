package com.ssafy.b205.backend.chat.adapter.web.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Min;
import lombok.Getter;

@Getter
public class ChangePaceRequest {

    @Schema(description = "AI 발언 간 간격(ms)", example = "2000")
    @Min(0)
    private int paceMs;
}
