package com.ssafy.b205.backend.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

import java.util.Arrays;
import java.util.List;

@Configuration
public class CorsConfig {

    @Value("${app.cors.allowed-origins:*}")
    private String allowedOrigins;

    @Bean
    public CorsFilter corsFilter() {
        var cfg = new CorsConfiguration();

        List<String> origins = Arrays.stream(allowedOrigins.split(","))
                .map(String::trim)
                .filter(s -> !s.isBlank())
                .toList();

        // allowCredentials(true) 사용 시, 와일드카드(*)는 사용할 수 없음
        boolean wildcard = origins.size() == 1 && "*".equals(origins.get(0));
        if (wildcard) {
            cfg.setAllowedOriginPatterns(List.of("*"));
            cfg.setAllowCredentials(false); // ⭐ "*"와 함께는 false 여야 함
        } else {
            cfg.setAllowedOriginPatterns(origins);
            cfg.setAllowCredentials(true);
        }

        cfg.setAllowedMethods(List.of("GET","POST","PUT","PATCH","DELETE","OPTIONS"));
        cfg.setAllowedHeaders(List.of(
                "Authorization", "Content-Type", "X-Device-Id", "X-Client-Version",
                "X-Refresh-Token", "Last-Event-ID" // ✅ SSE 재연결 헤더
        ));
        // 필요 시 노출 헤더 보강
        // cfg.setExposedHeaders(List.of("Authorization", "X-Client-Version"));

        cfg.setMaxAge(3600L);

        var source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", cfg);
        return new CorsFilter(source);
    }
}
