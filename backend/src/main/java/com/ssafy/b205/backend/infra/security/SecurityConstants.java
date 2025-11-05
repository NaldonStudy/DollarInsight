package com.ssafy.b205.backend.infra.security;

public final class SecurityConstants {
    private SecurityConstants() {}
    public static final String HEADER_AUTH   = "Authorization";
    public static final String HEADER_DEVICE = "X-Device-Id";
    public static final String BEARER_PREFIX = "Bearer ";

    public static final String DEVICE_HEADER = HEADER_DEVICE;
}
