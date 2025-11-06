package com.ssafy.b205.backend.support.error;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.ConstraintViolationException;
import org.slf4j.MDC;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
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

import io.jsonwebtoken.JwtException;

import java.net.URI;
import java.time.OffsetDateTime;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.stream.Collectors;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private ResponseEntity<ProblemDetail> pd(HttpStatus status, String detail, HttpServletRequest req, String code) {
        ProblemDetail body = ProblemDetail.forStatusAndDetail(status, detail);
        body.setTitle(status.getReasonPhrase());
        body.setType(URI.create("about:blank")); // 필요시 서비스 문서 URL로 변경
        body.setProperty("code", code);          // 시스템 코드 (e.g. BAD_REQUEST)
        body.setProperty("timestamp", OffsetDateTime.now().toString());
        body.setProperty("instance", req.getRequestURI());
        String traceId = MDC.get("traceId");
        if (traceId != null) body.setProperty("traceId", traceId);
        return ResponseEntity.status(status).body(body);
    }

    // === AppException ===
    @ExceptionHandler(AppException.class)
    public ResponseEntity<ProblemDetail> handleApp(AppException ex, HttpServletRequest req) {
        HttpStatus status = ex.getCode().status;
        return pd(status, ex.getMessage(), req, ex.getCode().name());
    }

    // === 400 계열 ===
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ProblemDetail> handleValidation(MethodArgumentNotValidException ex, HttpServletRequest req) {
        Map<String, String> errors = ex.getBindingResult().getFieldErrors()
                .stream()
                .collect(Collectors.toMap(
                        fe -> fe.getField(),
                        fe -> fe.getDefaultMessage(),
                        (a, b) -> a,
                        LinkedHashMap::new
                ));
        ProblemDetail body = ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, "Validation failed");
        body.setTitle("Bad Request");
        body.setType(URI.create("about:blank"));
        body.setProperty("errors", errors);
        body.setProperty("code", ErrorCode.BAD_REQUEST.name());
        body.setProperty("timestamp", OffsetDateTime.now().toString());
        body.setProperty("instance", req.getRequestURI());
        String traceId = MDC.get("traceId");
        if (traceId != null) body.setProperty("traceId", traceId);
        return ResponseEntity.badRequest().body(body);
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ProblemDetail> handleConstraint(ConstraintViolationException ex, HttpServletRequest req) {
        String msg = ex.getConstraintViolations().stream()
                .map(cv -> cv.getPropertyPath() + " " + cv.getMessage())
                .collect(Collectors.joining(", "));
        if (msg.isBlank()) msg = "constraint violation";
        return pd(HttpStatus.BAD_REQUEST, msg, req, ErrorCode.BAD_REQUEST.name());
    }

    @ExceptionHandler(MissingRequestHeaderException.class)
    public ResponseEntity<ProblemDetail> handleMissingHeader(MissingRequestHeaderException ex, HttpServletRequest req) {
        return pd(HttpStatus.BAD_REQUEST, "required header missing: " + ex.getHeaderName(), req, ErrorCode.BAD_REQUEST.name());
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ProblemDetail> handleNotReadable(HttpMessageNotReadableException ex, HttpServletRequest req) {
        return pd(HttpStatus.BAD_REQUEST, "malformed JSON body", req, ErrorCode.BAD_REQUEST.name());
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ProblemDetail> handleTypeMismatch(MethodArgumentTypeMismatchException ex, HttpServletRequest req) {
        return pd(HttpStatus.BAD_REQUEST, "parameter type mismatch: " + ex.getName(), req, ErrorCode.BAD_REQUEST.name());
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ProblemDetail> handleIllegalArg(IllegalArgumentException ex, HttpServletRequest req) {
        return pd(HttpStatus.BAD_REQUEST, ex.getMessage(), req, ErrorCode.BAD_REQUEST.name());
    }

    // === 401/403 ===
    @ExceptionHandler(BadCredentialsException.class)
    public ResponseEntity<ProblemDetail> handleBadCredentials(BadCredentialsException ex, HttpServletRequest req) {
        return pd(HttpStatus.UNAUTHORIZED, "invalid credentials", req, ErrorCode.UNAUTHORIZED.name());
    }

    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<ProblemDetail> handleAuth(AuthenticationException ex, HttpServletRequest req) {
        return pd(HttpStatus.UNAUTHORIZED, "authentication required", req, ErrorCode.UNAUTHORIZED.name());
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ProblemDetail> handleAccessDenied(AccessDeniedException ex, HttpServletRequest req) {
        return pd(HttpStatus.FORBIDDEN, "forbidden", req, ErrorCode.FORBIDDEN.name());
    }

    @ExceptionHandler(JwtException.class)
    public ResponseEntity<ProblemDetail> handleJwt(JwtException ex, HttpServletRequest req) {
        return pd(HttpStatus.UNAUTHORIZED, "invalid token", req, ErrorCode.UNAUTHORIZED.name());
    }

    // === 404/405/409 ===
    @ExceptionHandler(NoSuchElementException.class)
    public ResponseEntity<ProblemDetail> handleNotFound(NoSuchElementException ex, HttpServletRequest req) {
        return pd(HttpStatus.NOT_FOUND, ex.getMessage(), req, ErrorCode.NOT_FOUND.name());
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<ProblemDetail> handleMethodNotAllowed(HttpRequestMethodNotSupportedException ex, HttpServletRequest req) {
        return pd(HttpStatus.METHOD_NOT_ALLOWED, ex.getMessage(), req, ErrorCode.METHOD_NOT_ALLOWED.name());
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ProblemDetail> handleDataIntegrity(DataIntegrityViolationException ex, HttpServletRequest req) {
        return pd(HttpStatus.CONFLICT, "data integrity violation", req, ErrorCode.CONFLICT.name());
    }

    // === 500 ===
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ProblemDetail> handleAny(Exception ex, HttpServletRequest req) {
        return pd(HttpStatus.INTERNAL_SERVER_ERROR, "unexpected error", req, ErrorCode.INTERNAL_ERROR.name());
    }
}
