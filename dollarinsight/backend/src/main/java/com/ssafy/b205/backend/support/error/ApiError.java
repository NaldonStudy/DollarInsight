package com.ssafy.b205.backend.support.error;

import java.time.OffsetDateTime;

public final class ApiError {
    private final String code;
    private final String message;
    private final String path;
    private final OffsetDateTime timestamp;

    private ApiError(String code, String message, String path, OffsetDateTime timestamp) {
        this.code = code;
        this.message = message;
        this.path = path;
        this.timestamp = timestamp;
    }

    public static ApiError of(ErrorCode code, String message, String path) {
        return new ApiError(code.name(), message, path, OffsetDateTime.now());
    }

    public String getCode() { return code; }
    public String getMessage() { return message; }
    public String getPath() { return path; }
    public OffsetDateTime getTimestamp() { return timestamp; }
}
