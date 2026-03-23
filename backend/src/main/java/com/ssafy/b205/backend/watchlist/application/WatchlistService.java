package com.ssafy.b205.backend.watchlist.application;

import com.ssafy.b205.backend.watchlist.adapter.web.dto.response.WatchlistItemResponse;

import java.util.List;

public interface WatchlistService {

    List<WatchlistItemResponse> getMyWatchlist(String userUuid);
    void add(String userUuid, String ticker);
    void remove(String userUuid, String ticker);
    boolean isWatching(String userUuid, String ticker);
}
