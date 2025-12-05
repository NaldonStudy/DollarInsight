package com.ssafy.b205.backend.support.response;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.OffsetDateTime;

@Schema(name = "ApiError", description = "표준 에러 객체")
public class ApiErrorDoc {

    @Schema(description = "에러 코드(enum 이름)", example = "UNAUTHORIZED")
    public String code;

    @Schema(description = "사람이 읽는 메시지", example = "invalid token")
    public String message;

    @Schema(description = "요청 경로", example = "/api/auth/refresh")
    public String path;

    @Schema(description = "ISO-8601 UTC 타임스탬프", example = "2025-11-10T03:12:45.123Z")
    public OffsetDateTime timestamp;
}
