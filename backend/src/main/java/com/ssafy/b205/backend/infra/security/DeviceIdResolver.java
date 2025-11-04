package com.ssafy.b205.backend.infra.security;

import jakarta.servlet.http.HttpServletRequest;
import java.util.regex.Pattern;

public final class DeviceIdResolver {
    private DeviceIdResolver() {}

    // UUID v4 정규식
    private static final Pattern UUID_V4 = Pattern.compile(
            "^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$"
    );

    public static String resolveValidOrNull(HttpServletRequest req) {
        String did = req.getHeader(SecurityConstants.HEADER_DEVICE);
        return (did != null && UUID_V4.matcher(did).matches()) ? did : null;
    }
}
