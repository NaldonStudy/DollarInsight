package com.ssafy.b205.backend.infra.security;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
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
                .authorizeHttpRequests(reg -> reg
                        .requestMatchers("/api/public/**").permitAll()
                        .requestMatchers("/api/auth/signup", "/api/auth/login", "/api/auth/refresh").permitAll()
                        .requestMatchers("/v3/api-docs/**", "/swagger-ui/**", "/swagger-ui.html").permitAll()
                        .requestMatchers("/actuator/**").permitAll()
                        .anyRequest().authenticated()
                )
                // 401/403를 ApiResponse.error 포맷으로 통일
                .exceptionHandling(ex -> ex
                        .authenticationEntryPoint(new JsonAuthenticationEntryPoint()) // 401
                        .accessDeniedHandler(new JsonAccessDeniedHandler())           // 403
                );

        // 🔒 필터 순서 보장
        // 1) TokenFilter 를 UsernamePasswordAuthenticationFilter 앞에 둔다
        http.addFilterBefore(tokenFilter, UsernamePasswordAuthenticationFilter.class);
        // 2) DeviceHeaderFilter 를 TokenFilter 앞에 둔다  (즉, Device → Token → UsernamePasswordAuthenticationFilter)
        http.addFilterBefore(deviceHeaderFilter, TokenFilter.class);

        return http.build();
    }
}
