package com.ssafy.b205.backend.infra.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;

import javax.crypto.SecretKey;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static com.ssafy.b205.backend.infra.security.DeviceIdResolver.normalize;

@Component
public class TokenProvider {

    // 1) Base64 우선 사용 (운영 권장)
    @Value("${app.jwt.secret-base64:}")
    private String secretBase64;

    // 2) 필요 시 raw 문자열로도 허용 (테스트/로컬 편의)
    @Value("${app.jwt.secret:}")
    private String secretRaw;

    @Value("${app.jwt.access-ttl-seconds:900}")
    private long accessTtlSec;

    private SecretKey key;

    @PostConstruct
    void init() {
        byte[] keyBytes = null;

        if (secretBase64 != null && !secretBase64.isBlank()) {
            // Base64 → bytes
            keyBytes = Decoders.BASE64.decode(secretBase64.trim());
        } else if (secretRaw != null && !secretRaw.isBlank()) {
            // 문자열 그대로 사용(UTF-8) — 길이 반드시 32바이트 이상
            keyBytes = secretRaw.getBytes(StandardCharsets.UTF_8);
        }

        if (keyBytes == null || keyBytes.length < 32) { // HS256 최소 32bytes = 256bits
            throw new IllegalStateException(
                    "Invalid JWT secret: provide app.jwt.secret-base64 (Base64) or app.jwt.secret (raw) with >= 32 bytes."
            );
        }

        this.key = Keys.hmacShaKeyFor(keyBytes);
    }

    public String createAccessToken(String userUuid, String deviceId) {
        String did = normalize(deviceId);
        Instant now = Instant.now();
        return Jwts.builder()
                .subject(userUuid)
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plusSeconds(accessTtlSec)))
                .claims(Map.of(
                        "did", did,
                        "aud", "mobile",
                        "roles", List.of("USER")
                ))
                // jjwt 0.12 스타일: 알고리즘은 key에서 유추됨. (명시하고 싶으면 .signWith(key, Jwts.SIG.HS256))
                .signWith(key)
                .compact();
    }

    // 1) refresh 토큰 발급
    public String createRefreshToken(String userUuid, String deviceId, int ttlDays) {
        String did = normalize(deviceId);
        Instant now = Instant.now();
        Map<String, Object> claims = new HashMap<>();
        claims.put("did", did);
        claims.put("typ", "refresh");
        return Jwts.builder()
                .subject(userUuid)
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plus(ttlDays, ChronoUnit.DAYS)))
                .claims(claims)
                .signWith(key)
                .compact();
    }

    // 2) typ(access/refresh) 읽기
    public static String readTyp(Claims c) {
        Object t = c.get("typ");
        return t == null ? null : String.valueOf(t);
    }

    public Jws<Claims> parse(String token) {
        return Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token);
    }
}
