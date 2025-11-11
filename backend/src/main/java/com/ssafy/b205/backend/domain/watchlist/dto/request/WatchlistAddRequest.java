package com.ssafy.b205.backend.domain.watchlist.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.Locale;

public class WatchlistAddRequest {

    @NotBlank
    @Size(max = 16)
    private String ticker;

    public String getTicker() {
        return ticker;
    }

    public String normalizedTicker() {
        return ticker == null ? null : ticker.trim().toUpperCase(Locale.ROOT);
    }
}
