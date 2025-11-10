package com.ssafy.b205.backend.infra.docs;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.examples.Example;
import io.swagger.v3.oas.models.media.BooleanSchema;
import io.swagger.v3.oas.models.media.Content;
import io.swagger.v3.oas.models.media.MediaType;
import io.swagger.v3.oas.models.media.ObjectSchema;
import io.swagger.v3.oas.models.media.Schema;
import io.swagger.v3.oas.models.media.StringSchema;
import io.swagger.v3.oas.models.responses.ApiResponse;
import org.springdoc.core.customizers.OpenApiCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiErrorCustomizer {

    @Bean
    public OpenApiCustomizer errorComponentsCustomizer() {
        return openApi -> {
            Components comps = openApi.getComponents();
            if (comps == null) {
                comps = new Components();
                openApi.setComponents(comps);
            }

            // 1) 스키마 등록 (ApiErrorEnvelope = { success:false, error:{...} })
            Schema<?> apiError = new ObjectSchema()
                    .addProperty("code", new StringSchema().example("UNAUTHORIZED"))
                    .addProperty("message", new StringSchema().example("invalid token"))
                    .addProperty("path", new StringSchema().example("/api/auth/refresh"))
                    .addProperty("timestamp", new StringSchema().example("2025-11-10T03:12:45.123Z"));

            Schema<?> apiErrorEnvelope = new ObjectSchema()
                    .addProperty("success", new BooleanSchema()._default(false).example(false))
                    .addProperty("error", apiError);

            comps.addSchemas("ApiErrorEnvelope", apiErrorEnvelope);

            // 2) 재사용 가능한 응답 등록
            comps.addResponses("BadRequestError",
                    jsonError("요청 형식 오류 / 검증 실패",
                            """
                            {
                              "success": false,
                              "error": {
                                "code": "BAD_REQUEST",
                                "message": "validation failed",
                                "path": "/api/auth/signup",
                                "timestamp": "2025-11-10T03:12:45.123Z"
                              }
                            }
                            """));

            comps.addResponses("UnauthorizedError",
                    jsonError("인증 실패(미인증/무효/만료 토큰)",
                            """
                            {
                              "success": false,
                              "error": {
                                "code": "UNAUTHORIZED",
                                "message": "invalid token",
                                "path": "/api/auth/refresh",
                                "timestamp": "2025-11-10T03:12:45.123Z"
                              }
                            }
                            """));

            comps.addResponses("ForbiddenError",
                    jsonError("권한 없음 / DID-토큰 불일치",
                            """
                            {
                              "success": false,
                              "error": {
                                "code": "FORBIDDEN",
                                "message": "forbidden",
                                "path": "/api/chat/sessions",
                                "timestamp": "2025-11-10T03:12:45.123Z"
                              }
                            }
                            """));

            comps.addResponses("NotFoundError",
                    jsonError("리소스 없음",
                            """
                            {
                              "success": false,
                              "error": {
                                "code": "NOT_FOUND",
                                "message": "resource not found",
                                "path": "/api/chat/sessions/uuid/xxxx",
                                "timestamp": "2025-11-10T03:12:45.123Z"
                              }
                            }
                            """));

            comps.addResponses("ConflictError",
                    jsonError("데이터 충돌 / 무결성 위반",
                            """
                            {
                              "success": false,
                              "error": {
                                "code": "CONFLICT",
                                "message": "data integrity violation",
                                "path": "/api/users",
                                "timestamp": "2025-11-10T03:12:45.123Z"
                              }
                            }
                            """));

            comps.addResponses("MethodNotAllowedError",
                    jsonError("허용되지 않은 HTTP 메서드",
                            """
                            {
                              "success": false,
                              "error": {
                                "code": "METHOD_NOT_ALLOWED",
                                "message": "Request method 'PUT' not supported",
                                "path": "/api/users/me",
                                "timestamp": "2025-11-10T03:12:45.123Z"
                              }
                            }
                            """));

            comps.addResponses("InternalServerError",
                    jsonError("서버 내부 오류",
                            """
                            {
                              "success": false,
                              "error": {
                                "code": "INTERNAL_ERROR",
                                "message": "unexpected error",
                                "path": "/api/users/me",
                                "timestamp": "2025-11-10T03:12:45.123Z"
                              }
                            }
                            """));
        };
    }

    // 공통 JSON 응답 빌더
    private static ApiResponse jsonError(String desc, String exampleJson) {
        Example ex = new Example().value(exampleJson);
        MediaType media = new MediaType()
                .schema(new Schema<>().$ref("#/components/schemas/ApiErrorEnvelope"))
                .addExamples("example", ex);
        return new ApiResponse()
                .description(desc)
                .content(new Content().addMediaType(org.springframework.http.MediaType.APPLICATION_JSON_VALUE, media));
    }
}
