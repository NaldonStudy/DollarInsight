package com.ssafy.b205.backend.config;

import io.swagger.v3.core.converter.ModelConverters;
import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.media.Content;
import io.swagger.v3.oas.models.media.Schema;
import io.swagger.v3.oas.models.media.StringSchema;
import io.swagger.v3.oas.models.parameters.Parameter;
import io.swagger.v3.oas.models.responses.ApiResponses;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springdoc.core.customizers.OpenApiCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.MediaType;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI openAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("DollarIn$ight Backend API")
                        .version("v1")
                        .description("US Stock Assistant backend"))
                .components(new Components()
                        // X-Device-Id를 API Key 보안 스킴으로 등록 → Swagger의 Authorize에서 한 번 입력
                        .addSecuritySchemes("deviceId",
                                new SecurityScheme()
                                        .type(SecurityScheme.Type.APIKEY)
                                        .in(SecurityScheme.In.HEADER)
                                        .name("X-Device-Id")
                                        .description("Device-bound header"))
                        // JWT Bearer (보호 API에서만 @SecurityRequirement로 요구)
                        .addSecuritySchemes("bearerAuth",
                                new SecurityScheme()
                                        .type(SecurityScheme.Type.HTTP)
                                        .scheme("bearer")
                                        .bearerFormat("JWT")
                                        .description("JWT access token (Bearer <token>)"))
                );
        // bearerAuth 전역 SecurityRequirement는 걸지 않음 (보호 엔드포인트에서만 개별 요구)
    }

    @Bean
    public OpenApiCustomizer deviceIdSecurityAndErrorsCustomizer() {
        return openApi -> {
            // 0) ApiError 스키마 등록 (에러 응답 문서화에 사용)
            ModelConverters.getInstance()
                    .read(com.ssafy.b205.backend.support.error.ApiError.class)
                    .forEach((name, schema) -> openApi.getComponents().addSchemas(name, schema));

            if (openApi.getPaths() == null) return;

            // X-Refresh-Token 헤더 파라미터 정의 (refresh/logout 전용)
            Parameter refreshHeader = new Parameter()
                    .name("X-Refresh-Token")
                    .in("header")
                    .required(true)
                    .description("Refresh flow 전용 헤더")
                    .schema(new StringSchema());

            openApi.getPaths().forEach((path, item) ->
                    item.readOperations().forEach(op -> {
                        // a) 모든 /api/** 오퍼레이션에 deviceId 보안 요구 추가
                        //    → Swagger Authorize에서 deviceId 한 번 입력하면 자동으로 헤더 주입됨
                        if (path.startsWith("/api/")) {
                            op.addSecurityItem(new SecurityRequirement().addList("deviceId"));
                        }

                        // b) refresh & logout 은 X-Refresh-Token 헤더 추가 노출
                        if (path.equals("/api/auth/refresh") || path.equals("/api/auth/logout")) {
                            op.addParametersItem(refreshHeader);
                        }

                        // c) 공통 에러 응답
                        ApiResponses rs = op.getResponses();
                        addError(rs, "400", "Bad Request");
                        addError(rs, "401", "Unauthorized");
                        addError(rs, "403", "Forbidden");
                        addError(rs, "404", "Not Found");
                        addError(rs, "409", "Conflict");
                        addError(rs, "500", "Internal Server Error");
                    })
            );
        };
    }

    private static void addError(ApiResponses rs, String code, String desc) {
        Content content = new Content().addMediaType(
                MediaType.APPLICATION_JSON_VALUE,
                new io.swagger.v3.oas.models.media.MediaType()
                        .schema(new Schema<>().$ref("#/components/schemas/ApiError"))
        );
        rs.addApiResponse(code, new io.swagger.v3.oas.models.responses.ApiResponse()
                .description(desc)
                .content(content));
    }
}
