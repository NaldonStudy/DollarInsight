package com.ssafy.b205.backend.support.error;

public class AppException extends RuntimeException {
    private final ErrorCode code;

    // ✅ 추가: ErrorCode만 (기본 메시지는 enum 이름)
    public AppException(ErrorCode code) {
        super(code.name());
        this.code = code;
    }

    // ✅ 추가: ErrorCode + cause (기본 메시지는 enum 이름)
    public AppException(ErrorCode code, Throwable cause) {
        super(code.name(), cause);
        this.code = code;
    }

    // ✅ 기존 유지: ErrorCode + 커스텀 메시지
    public AppException(ErrorCode code, String message) {
        super(message);
        this.code = code;
    }

    // ✅ 기존 유지: ErrorCode + 커스텀 메시지 + cause
    public AppException(ErrorCode code, String message, Throwable cause) {
        super(message, cause);
        this.code = code;
    }

    public ErrorCode getCode() {
        return code;
    }
}
