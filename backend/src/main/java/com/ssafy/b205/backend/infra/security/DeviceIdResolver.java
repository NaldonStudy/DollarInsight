package com.ssafy.b205.backend.infra.security;

import jakarta.servlet.http.HttpServletRequest;

/**
 * X-Device-Id 허용 정책 (형식 미정 → 사실상 전체 허용):
 * - 앞뒤 공백만 제거(trim)
 * - 빈 값이면 null
 * - 대소문자/문자구성/패턴 제한 없음
 * - 안전상 과도한 길이 방지: 기본 256자로 컷
 *
 * 컨트롤러/서비스에서 문자열을 다룰 때는 normalize(String),
 * 필터/인터셉터 등 HttpServletRequest에서 읽을 때는 resolveValidOrNull(HttpServletRequest)을 사용.
 */
public final class DeviceIdResolver {

    private static final int MAX_LEN = 256;

    private DeviceIdResolver() {}

    /** HttpServletRequest 헤더에서 읽어 트림/길이 제한 적용, 빈 값이면 null */
    public static String resolveValidOrNull(HttpServletRequest req) {
        String v = req.getHeader("X-Device-Id");
        if (v == null) return null;
        v = v.trim();
        if (v.isEmpty()) return null;
        if (v.length() > MAX_LEN) v = v.substring(0, MAX_LEN);
        // 소문자 변환/UUID 검사 없음 — 원문 유지
        return v;
    }

    /** 임의 문자열 normalize (트림/길이 제한, 빈 값은 IllegalArgumentException) */
    public static String normalize(String deviceId) {
        if (deviceId == null) throw new IllegalArgumentException("deviceId is null");
        String v = deviceId.trim();
        if (v.isEmpty()) throw new IllegalArgumentException("deviceId is empty");
        if (v.length() > MAX_LEN) v = v.substring(0, MAX_LEN);
        return v;
    }
}
