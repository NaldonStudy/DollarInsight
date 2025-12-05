package com.ssafy.b205.backend.support.error;

import java.util.NoSuchElementException;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.dao.DataIntegrityViolationException;
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
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

import com.ssafy.b205.backend.support.response.ApiResponse;

import io.jsonwebtoken.JwtException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.ConstraintViolationException;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    private ResponseEntity<ApiResponse<?>> err(ErrorCode code, String message, HttpServletRequest req) {
        var error = ApiError.of(code, message, req.getRequestURI());
        return ResponseEntity.status(code.status).body(ApiResponse.error(error));
    }

    // === AppException ===
    @ExceptionHandler(AppException.class)
    public ResponseEntity<ApiResponse<?>> handleApp(AppException ex, HttpServletRequest req) {
        if (ex.getCode().status.is5xxServerError()) {
            log.error("[AppException] {}", ex.getMessage(), ex);
        } else {
            log.warn("[AppException] {}", ex.getMessage());
        }
        return err(ex.getCode(), ex.getMessage(), req);
    }

    // === 400 계열 ===
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<?>> handleValidation(MethodArgumentNotValidException ex, HttpServletRequest req) {
        String joined = ex.getBindingResult().getFieldErrors().stream()
                .map(fe -> fe.getField() + " " + fe.getDefaultMessage())
                .collect(Collectors.joining(", "));
        if (joined == null || joined.isBlank()) joined = "validation failed";
        return err(ErrorCode.BAD_REQUEST, joined, req);
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ApiResponse<?>> handleConstraint(ConstraintViolationException ex, HttpServletRequest req) {
        String msg = ex.getConstraintViolations().stream()
                .map(cv -> cv.getPropertyPath() + " " + cv.getMessage())
                .collect(Collectors.joining(", "));
        if (msg == null || msg.isBlank()) msg = "constraint violation";
        return err(ErrorCode.BAD_REQUEST, msg, req);
    }

    @ExceptionHandler(MissingRequestHeaderException.class)
    public ResponseEntity<ApiResponse<?>> handleMissingHeader(MissingRequestHeaderException ex, HttpServletRequest req) {
        return err(ErrorCode.BAD_REQUEST, "required header missing: " + ex.getHeaderName(), req);
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ApiResponse<?>> handleNotReadable(HttpMessageNotReadableException ex, HttpServletRequest req) {
        return err(ErrorCode.BAD_REQUEST, "malformed JSON body", req);
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ApiResponse<?>> handleTypeMismatch(MethodArgumentTypeMismatchException ex, HttpServletRequest req) {
        return err(ErrorCode.BAD_REQUEST, "parameter type mismatch: " + ex.getName(), req);
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ApiResponse<?>> handleIllegalArg(IllegalArgumentException ex, HttpServletRequest req) {
        return err(ErrorCode.BAD_REQUEST, ex.getMessage(), req);
    }

    // === 401/403 ===
    @ExceptionHandler(BadCredentialsException.class)
    public ResponseEntity<ApiResponse<?>> handleBadCredentials(BadCredentialsException ex, HttpServletRequest req) {
        return err(ErrorCode.UNAUTHORIZED, "invalid credentials", req);
    }

    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<ApiResponse<?>> handleAuth(AuthenticationException ex, HttpServletRequest req) {
        return err(ErrorCode.UNAUTHORIZED, "authentication required", req);
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ApiResponse<?>> handleAccessDenied(AccessDeniedException ex, HttpServletRequest req) {
        return err(ErrorCode.FORBIDDEN, "forbidden", req);
    }

    @ExceptionHandler(JwtException.class)
    public ResponseEntity<ApiResponse<?>> handleJwt(JwtException ex, HttpServletRequest req) {
        return err(ErrorCode.UNAUTHORIZED, "invalid token", req);
    }

    // === 404/405/409 ===
    @ExceptionHandler(NoSuchElementException.class)
    public ResponseEntity<ApiResponse<?>> handleNotFound(NoSuchElementException ex, HttpServletRequest req) {
        String msg = ex.getMessage() == null ? "resource not found" : ex.getMessage();
        return err(ErrorCode.NOT_FOUND, msg, req);
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<ApiResponse<?>> handleMethodNotAllowed(HttpRequestMethodNotSupportedException ex, HttpServletRequest req) {
        return err(ErrorCode.METHOD_NOT_ALLOWED, ex.getMessage(), req);
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ApiResponse<?>> handleDataIntegrity(DataIntegrityViolationException ex, HttpServletRequest req) {
        return err(ErrorCode.CONFLICT, "data integrity violation", req);
    }

    // === 500 ===
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<?>> handleAny(Exception ex, HttpServletRequest req) {
        String traceId = MDC.get("traceId");
        if (traceId != null) log.error("[GlobalErr-E01] unexpected error traceId={}", traceId, ex);
        else log.error("[GlobalErr-E01] unexpected error", ex);
        return err(ErrorCode.INTERNAL_ERROR, "unexpected error", req);
    }
}
