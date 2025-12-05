package com.ssafy.b205.backend.domain.companyanalysis.dto.response;

import com.ssafy.b205.backend.domain.companyanalysis.model.AssetType;
import lombok.Getter;

import java.math.BigDecimal;
import java.time.LocalDate;

@Getter
public class AssetBasicInfoResponse {

    private final String ticker;
    private final String name;
    private final String nameEng;
    private final AssetType assetType;
    private final String exchange;
    private final String exchangeName;
    private final String currency;
    private final String country;
    private final String sector;
    private final String industry;
    private final LocalDate listedAt;
    private final String website;
    private final Boolean leverage;
    private final BigDecimal leverageFactor;

    public AssetBasicInfoResponse(String ticker, String name, String nameEng, AssetType assetType,
                                  String exchange, String exchangeName, String currency,
                                  String country, String sector, String industry,
                                  LocalDate listedAt, String website,
                                  Boolean leverage, BigDecimal leverageFactor) {
        this.ticker = ticker;
        this.name = name;
        this.nameEng = nameEng;
        this.assetType = assetType;
        this.exchange = exchange;
        this.exchangeName = exchangeName;
        this.currency = currency;
        this.country = country;
        this.sector = sector;
        this.industry = industry;
        this.listedAt = listedAt;
        this.website = website;
        this.leverage = leverage;
        this.leverageFactor = leverageFactor;
    }
}
