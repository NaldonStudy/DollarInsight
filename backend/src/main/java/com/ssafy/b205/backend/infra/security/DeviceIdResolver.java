package com.ssafy.b205.backend.infra.security;

import jakarta.servlet.http.HttpServletRequest;
import java.util.Locale;

public final class DeviceIdResolver {
    private DeviceIdResolver() {}

    /** 옵션 C: 비어있지만 않으면 통과. trim + 소문자화 + 128자 제한만 적용 */
    public static String normalize(String raw) {
        if (raw == null) return "";
        String s = raw.trim().toLowerCase(Locale.ROOT);
        if (s.length() > 128) s = s.substring(0, 128);
        return s;
    }

    public static String resolveValidOrNull(HttpServletRequest req) {
        String did = normalize(req.getHeader(SecurityConstants.HEADER_DEVICE));
        return did.isEmpty() ? null : did;
    }
}
