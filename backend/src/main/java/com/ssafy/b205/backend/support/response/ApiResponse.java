package com.ssafy.b205.backend.support.response;

import com.ssafy.b205.backend.support.error.ApiError;
import java.time.OffsetDateTime;

public class ApiResponse<T> {
    private final boolean ok;
    private final T data;
    private final ApiError error;
    private final OffsetDateTime timestamp = OffsetDateTime.now();

    private ApiResponse(boolean ok, T data, ApiError error){
        this.ok=ok; this.data=data; this.error=error;
    }
    public static <T> ApiResponse<T> ok(T data){ return new ApiResponse<>(true, data, null); }
    public static ApiResponse<?> error(ApiError err){ return new ApiResponse<>(false, null, err); }

    public boolean isOk(){ return ok; }
    public T getData(){ return data; }
    public ApiError getError(){ return error; }
    public OffsetDateTime getTimestamp(){ return timestamp; }
}
