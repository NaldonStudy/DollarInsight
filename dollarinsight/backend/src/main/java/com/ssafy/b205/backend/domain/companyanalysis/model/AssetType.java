package com.ssafy.b205.backend.domain.companyanalysis.model;

import java.util.Locale;

public enum AssetType {
    STOCK,
    ETF,
    INDEX;

    public static AssetType fromDbValue(String value) {
        if (value == null) {
            throw new IllegalArgumentException("asset_type is required");
        }
        return switch (value.toLowerCase(Locale.ROOT)) {
            case "stock" -> STOCK;
            case "etf" -> ETF;
            case "index" -> INDEX;
            default -> throw new IllegalArgumentException("unsupported asset_type: " + value);
        };
    }
}
