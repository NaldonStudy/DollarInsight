package com.ssafy.b205.backend.support.error;

import java.time.OffsetDateTime;

public record ApiError(
        String code,
        String message,
        String path,
        OffsetDateTime timestamp
) {
    public static ApiError of(ErrorCode code, String message, String path) {
        return new ApiError(code.name(), message, path, OffsetDateTime.now());
    }
}