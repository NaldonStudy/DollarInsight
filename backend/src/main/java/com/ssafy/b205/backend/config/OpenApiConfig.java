package com.ssafy.b205.backend.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI openAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("DollarIn$ight Backend API")
                        .version("v1")
                        .description("US Stock Assistant backend"))
                // ⬇️ Swagger Authorize에 뜨는 보안 스킴 2개
                .components(new Components()
                        // X-Device-Id 헤더 (apiKey in header)
                        .addSecuritySchemes("deviceId",
                                new SecurityScheme()
                                        .type(SecurityScheme.Type.APIKEY)
                                        .in(SecurityScheme.In.HEADER)
                                        .name("X-Device-Id")
                                        .description("Device-bound header"))
                        // JWT Bearer
                        .addSecuritySchemes("bearerAuth",
                                new SecurityScheme()
                                        .type(SecurityScheme.Type.HTTP)
                                        .scheme("bearer")
                                        .bearerFormat("JWT")
                                        .description("JWT access token (Bearer <token>)"))
                );
        // 전역 SecurityRequirement는 걸지 말자.
        // 보호 API에만 @SecurityRequirement를 붙여서 요구하도록 운영.
    }
}
