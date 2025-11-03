package com.ssafy.b205.backend.support.error;

import com.ssafy.b205.backend.support.response.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.context.request.ServletWebRequest;

@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(AppException.class)
    public ResponseEntity<ApiResponse<?>> handleApp(AppException ex, ServletWebRequest req){
        var code = ex.getCode();
        return ResponseEntity.status(code.status)
                .body(ApiResponse.error(ApiError.of(code, ex.getMessage(), req.getRequest().getRequestURI())));
    }
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<?>> handleValid(MethodArgumentNotValidException ex, ServletWebRequest req){
        var msg = ex.getBindingResult().getFieldErrors().stream().findFirst()
                .map(e -> e.getField()+" "+e.getDefaultMessage()).orElse("validation error");
        return ResponseEntity.badRequest()
                .body(ApiResponse.error(ApiError.of(ErrorCode.BAD_REQUEST, msg, req.getRequest().getRequestURI())));
    }
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<?>> handleAny(Exception ex, ServletWebRequest req){
        return ResponseEntity.status(500)
                .body(ApiResponse.error(ApiError.of(ErrorCode.INTERNAL_ERROR, ex.getMessage(), req.getRequest().getRequestURI())));
    }
}
