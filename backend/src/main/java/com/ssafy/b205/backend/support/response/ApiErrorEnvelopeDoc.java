package com.ssafy.b205.backend.support.response;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(name = "ApiErrorEnvelope", description = "에러 응답 최상위 래퍼")
public class ApiErrorEnvelopeDoc {

    @Schema(description = "성공 여부(항상 false)", example = "false")
    public boolean success = false;

    @Schema(description = "에러 상세")
    public ApiErrorDoc error;
}
