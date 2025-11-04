package com.ssafy.b205.backend.infra.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import javax.crypto.SecretKey;                 // 0.12.x에서는 SecretKey 권장
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;
import java.util.List;
import java.util.Map;

@Component
public class TokenProvider {

    @Value("${app.jwt.secret:please-change-min-32bytes}")
    private String secret;

    @Value("${app.jwt.access-ttl-seconds:900}")
    private long accessTtlSec;

    private SecretKey key;

    @PostConstruct
    void init() {
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }

    public String createAccessToken(String userUuid, String deviceId) {
        Instant now = Instant.now();
        return Jwts.builder()
                .subject(userUuid)
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plusSeconds(accessTtlSec)))
                .claims(Map.of(
                        "did", deviceId,
                        "aud", "mobile",
                        "roles", List.of("USER")
                ))
                .signWith(key, Jwts.SIG.HS256)
                .compact();
    }

    public Jws<Claims> parse(String token) {
        // parserBuilder() → parser().verifyWith(key).build().parseSignedClaims(...)
        return Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token);
    }
}
