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
import org.springframework.security.web.context.RequestAttributeSecurityContextRepository;

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
                .securityContext(ctx -> ctx
                        .securityContextRepository(new RequestAttributeSecurityContextRepository())
                )
                .exceptionHandling(ex -> ex
                        .authenticationEntryPoint(new JsonAuthenticationEntryPoint()) // 401
                        .accessDeniedHandler(new JsonAccessDeniedHandler())           // 403
                )
                .authorizeHttpRequests(reg -> reg
                        .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()

                        // 공개 API (접두 유무 모두 허용)
                        .requestMatchers("/api/public/**", "/public/**").permitAll()
                        .requestMatchers(
                                "/api/auth/signup", "/api/auth/login", "/api/auth/refresh",
                                "/auth/signup",     "/auth/login",     "/auth/refresh"
                        ).permitAll()

                        // kakao OAuth를 위한
                        .requestMatchers("/api/auth/oauth/**").permitAll()

                        // 문서/헬스 (접두 유무 모두 허용)
                        .requestMatchers(
                                "/v3/api-docs/**", "/swagger-ui/**", "/swagger-ui.html",
                                "/api/v3/api-docs/**", "/api/swagger-ui/**", "/api/swagger-ui.html"
                        ).permitAll()
                        .requestMatchers("/actuator/**", "/api/actuator/**").permitAll()

                        // 에러 디스패치 경로
                        .requestMatchers("/error", "/api/error").permitAll()

                        .anyRequest().authenticated()
                );

        // 필터 순서: 둘 다 UsernamePasswordAuthenticationFilter "앞"에 배치
        http.addFilterBefore(deviceHeaderFilter, UsernamePasswordAuthenticationFilter.class);
        http.addFilterBefore(tokenFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
