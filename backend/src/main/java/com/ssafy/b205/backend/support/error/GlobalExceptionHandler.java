package com.ssafy.b205.backend.support.error;

import com.ssafy.b205.backend.support.response.ApiResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingRequestHeaderException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.ServletWebRequest;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

import jakarta.validation.ConstraintViolationException;
import java.util.NoSuchElementException;
import java.util.stream.Collectors;

import io.jsonwebtoken.JwtException;

@Slf4j
@Order(Ordered.HIGHEST_PRECEDENCE)
@RestControllerAdvice
public class GlobalExceptionHandler {

    private ResponseEntity<ApiResponse<?>> build(ErrorCode code, HttpStatus status, String message, ServletWebRequest req) {
        var path = req.getRequest().getRequestURI();
        return ResponseEntity.status(status)
                .body(ApiResponse.error(ApiError.of(code, message, path)));
    }

    // App 계층 공통
    @ExceptionHandler(AppException.class)
    public ResponseEntity<ApiResponse<?>> handleApp(AppException ex, ServletWebRequest req){
        var status = ex.getCode().status;
        log.warn("[APP] {} {} -> {} {}", req.getRequest().getMethod(), req.getRequest().getRequestURI(), status.value(), ex.getMessage());
        return build(ex.getCode(), status, ex.getMessage(), req);
    }

    // 요청/검증 (400)
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<?>> handleValid(MethodArgumentNotValidException ex, ServletWebRequest req){
        var msg = ex.getBindingResult().getFieldErrors().stream()
                .map(e -> e.getField() + " " + e.getDefaultMessage())
                .findFirst().orElse("validation error");
        return build(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, msg, req);
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ApiResponse<?>> handleConstraint(ConstraintViolationException ex, ServletWebRequest req){
        var msg = ex.getConstraintViolations().stream()
                .map(cv -> cv.getPropertyPath() + " " + cv.getMessage())
                .collect(Collectors.joining(", "));
        if (msg.isBlank()) msg = "constraint violation";
        return build(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, msg, req);
    }

    @ExceptionHandler(MissingRequestHeaderException.class)
    public ResponseEntity<ApiResponse<?>> handleMissingHeader(MissingRequestHeaderException ex, ServletWebRequest req){
        return build(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "required header missing: " + ex.getHeaderName(), req);
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ApiResponse<?>> handleNotReadable(HttpMessageNotReadableException ex, ServletWebRequest req){
        return build(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "malformed JSON body", req);
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ApiResponse<?>> handleTypeMismatch(MethodArgumentTypeMismatchException ex, ServletWebRequest req){
        return build(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "parameter type mismatch: " + ex.getName(), req);
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ApiResponse<?>> handleIllegalArg(IllegalArgumentException ex, ServletWebRequest req){
        return build(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, ex.getMessage(), req);
    }

    // 인증/인가 (401/403)
    @ExceptionHandler(BadCredentialsException.class)
    public ResponseEntity<ApiResponse<?>> handleBadCredentials(BadCredentialsException ex, ServletWebRequest req){
        return build(ErrorCode.UNAUTHORIZED, HttpStatus.UNAUTHORIZED, "이메일 또는 비밀번호가 올바르지 않습니다.", req);
    }

    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<ApiResponse<?>> handleAuth(AuthenticationException ex, ServletWebRequest req){
        return build(ErrorCode.UNAUTHORIZED, HttpStatus.UNAUTHORIZED, "인증이 필요합니다.", req);
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ApiResponse<?>> handleAccessDenied(AccessDeniedException ex, ServletWebRequest req){
        return build(ErrorCode.FORBIDDEN, HttpStatus.FORBIDDEN, "접근 권한이 없습니다.", req);
    }

    @ExceptionHandler(JwtException.class)
    public ResponseEntity<ApiResponse<?>> handleJwt(JwtException ex, ServletWebRequest req){
        return build(ErrorCode.UNAUTHORIZED, HttpStatus.UNAUTHORIZED, "유효하지 않은 토큰입니다.", req);
    }

    // 리소스/제약 (404/405/409)
    @ExceptionHandler(NoSuchElementException.class)
    public ResponseEntity<ApiResponse<?>> handleNotFound(NoSuchElementException ex, ServletWebRequest req){
        return build(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, ex.getMessage(), req);
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<ApiResponse<?>> handleMethodNotAllowed(HttpRequestMethodNotSupportedException ex, ServletWebRequest req){
        return build(ErrorCode.METHOD_NOT_ALLOWED, HttpStatus.METHOD_NOT_ALLOWED, ex.getMessage(), req);
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ApiResponse<?>> handleDataIntegrity(DataIntegrityViolationException ex, ServletWebRequest req){
        return build(ErrorCode.CONFLICT, HttpStatus.CONFLICT, "데이터 무결성 위반(중복 또는 제약 조건 위반)", req);
    }

    // 그 외 (500)
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<?>> handleAny(Exception ex, ServletWebRequest req){
        log.error("[UNHANDLED] {} {}", req.getRequest().getMethod(), req.getRequest().getRequestURI(), ex);
        return build(ErrorCode.INTERNAL_ERROR, HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류가 발생했습니다.", req);
    }
}
