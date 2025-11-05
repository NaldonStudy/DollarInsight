package com.ssafy.b205.backend.infra.security;

import jakarta.servlet.http.HttpServletRequest;
import java.util.regex.Pattern;

public final class DeviceIdResolver {
    private DeviceIdResolver() {}

    // UUID v4 (대/소문자 허용)
    private static final Pattern UUID_V4 = Pattern.compile(
            "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$"
    );

    // 로컬/개발 편의를 위한 완화 패턴: 영문/숫자/._- , 길이 3~64
    private static final Pattern RELAXED = Pattern.compile(
            "^[A-Za-z0-9._-]{3,64}$"
    );

    public static String resolveValidOrNull(HttpServletRequest req) {
        String did = req.getHeader(SecurityConstants.HEADER_DEVICE);
        if (did == null) return null;

        did = did.trim();
        if (did.isEmpty()) return null;

        if (UUID_V4.matcher(did).matches()) {
            // UUID는 정규화(선택 사항)
            return did.toLowerCase();
        }
        if (RELAXED.matcher(did).matches()) {
            return did;
        }
        return null;
    }
}
