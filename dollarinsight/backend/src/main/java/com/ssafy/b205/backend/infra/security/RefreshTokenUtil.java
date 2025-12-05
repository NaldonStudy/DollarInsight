package com.ssafy.b205.backend.infra.security;

import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletResponse;
import lombok.experimental.UtilityClass;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Duration;
import java.util.Base64;

@UtilityClass
public class RefreshTokenUtil {

    public static String sha256Base64(String value, String pepper) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            md.update((value + ":" + pepper).getBytes(StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(md.digest());
        } catch (Exception e) {
            throw new IllegalStateException("SHA-256 not available", e);
        }
    }

    public static void setHttpOnlyCookie(HttpServletResponse res, String name, String value, Duration maxAge, boolean secure) {
        Cookie c = new Cookie(name, value);
        c.setHttpOnly(true);
        c.setSecure(secure);
        c.setPath("/");
        c.setMaxAge((int) maxAge.toSeconds());
        res.addCookie(c);
    }

    public static void deleteCookie(HttpServletResponse res, String name, boolean secure) {
        Cookie c = new Cookie(name, "");
        c.setHttpOnly(true);
        c.setSecure(secure);
        c.setPath("/");
        c.setMaxAge(0);
        res.addCookie(c);
    }
}
