package com.ssafy.b205.backend.support.util;

import java.util.regex.Pattern;

public final class Regexes {
    private Regexes() {}
    public static final Pattern UUID_V4 = Pattern.compile(
            "^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$"
    );
}
