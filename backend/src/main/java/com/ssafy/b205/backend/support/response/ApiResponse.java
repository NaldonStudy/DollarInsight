package com.ssafy.b205.backend.support.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.ssafy.b205.backend.support.error.ApiError;
import java.time.Instant;

@JsonInclude(JsonInclude.Include.NON_NULL)
public class ApiResponse<T> {
    private final boolean ok;
    private final T data;
    private final ApiError error;
    private final Instant timestamp = Instant.now();

    private ApiResponse(boolean ok, T data, ApiError error) {
        this.ok = ok; this.data = data; this.error = error;
    }
    public static <T> ApiResponse<T> ok(T data){ return new ApiResponse<>(true, data, null); }
    public static ApiResponse<Void> ok(){ return new ApiResponse<>(true, null, null); } // 필요시
    public static ApiResponse<?> error(ApiError err){ return new ApiResponse<>(false, null, err); }

    public boolean isOk(){ return ok; }
    public T getData(){ return data; }
    public ApiError getError(){ return error; }
    public Instant getTimestamp(){ return timestamp; }
}
