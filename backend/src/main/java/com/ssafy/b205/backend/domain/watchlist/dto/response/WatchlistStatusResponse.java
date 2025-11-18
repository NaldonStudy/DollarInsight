package com.ssafy.b205.backend.domain.watchlist.dto.response;

import lombok.Getter;

@Getter
public class WatchlistStatusResponse {

    private final String ticker;
    private final boolean watching;

    public WatchlistStatusResponse(String ticker, boolean watching) {
        this.ticker = ticker;
        this.watching = watching;
    }
}
