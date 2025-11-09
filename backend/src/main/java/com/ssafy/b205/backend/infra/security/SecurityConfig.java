package com.ssafy.b205.backend.infra.security;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@RequiredArgsConstructor
public class SecurityConfig {

    private final DeviceHeaderFilter deviceHeaderFilter;
    private final TokenFilter tokenFilter;

    @Bean
    SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                .csrf(csrf -> csrf.disable())
                .cors(Customizer.withDefaults())
                .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .exceptionHandling(ex -> ex
                        .authenticationEntryPoint(new JsonAuthenticationEntryPoint()) // 401
                        .accessDeniedHandler(new JsonAccessDeniedHandler())           // 403
                )
                .authorizeHttpRequests(reg -> reg
                        // 공개 API
                        .requestMatchers("/api/public/**").permitAll()
                        .requestMatchers("/api/auth/signup", "/api/auth/login", "/api/auth/refresh").permitAll()
                        .requestMatchers("/v3/api-docs/**", "/swagger-ui/**", "/swagger-ui.html").permitAll()
                        .requestMatchers("/actuator/**").permitAll()
                        // SSE 스트림(명시적으로 명기해 두면 디버깅 편함)
                        .requestMatchers(HttpMethod.GET, "/api/chat/sessions/*/stream").authenticated()
                        // 그 외 보호
                        .anyRequest().authenticated()
                );

        // 🔒 필터 순서: Device → Token → UsernamePasswordAuthenticationFilter
        http.addFilterBefore(deviceHeaderFilter, UsernamePasswordAuthenticationFilter.class);
        http.addFilterAfter(tokenFilter, DeviceHeaderFilter.class);

        return http.build();
    }
}
