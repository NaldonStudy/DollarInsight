package com.ssafy.b205.backend.domain.companyanalysis.dto.response;

import com.ssafy.b205.backend.domain.companyanalysis.model.AssetType;
import lombok.Getter;

@Getter
public class AssetSearchResponse {

    private final String ticker;
    private final AssetType assetType;
    private final String name;
    private final String nameEng;
    private final String exchange;

    public AssetSearchResponse(String ticker, AssetType assetType,
                               String name, String nameEng, String exchange) {
        this.ticker = ticker;
        this.assetType = assetType;
        this.name = name;
        this.nameEng = nameEng;
        this.exchange = exchange;
    }
}
