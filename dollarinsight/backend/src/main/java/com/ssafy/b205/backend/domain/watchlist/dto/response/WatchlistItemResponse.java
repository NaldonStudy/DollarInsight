package com.ssafy.b205.backend.domain.watchlist.dto.response;

import com.ssafy.b205.backend.domain.companyanalysis.model.AssetType;
import lombok.Getter;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Getter
public class WatchlistItemResponse {

    private final String ticker;
    private final AssetType assetType;
    private final String name;
    private final String nameEng;
    private final String exchange;
    private final LocalDateTime addedAt;
    private final LocalDate lastPriceDate;
    private final BigDecimal lastPrice;
    private final BigDecimal changePct;

    public WatchlistItemResponse(String ticker,
                                 AssetType assetType,
                                 String name,
                                 String nameEng,
                                 String exchange,
                                 LocalDateTime addedAt,
                                 LocalDate lastPriceDate,
                                 BigDecimal lastPrice,
                                 BigDecimal changePct) {
        this.ticker = ticker;
        this.assetType = assetType;
        this.name = name;
        this.nameEng = nameEng;
        this.exchange = exchange;
        this.addedAt = addedAt;
        this.lastPriceDate = lastPriceDate;
        this.lastPrice = lastPrice;
        this.changePct = changePct;
    }
}
