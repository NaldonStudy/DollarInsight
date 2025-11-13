package com.ssafy.b205.backend.domain.companyanalysis.dto.response;

import com.ssafy.b205.backend.domain.companyanalysis.model.AssetType;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;

import java.time.Instant;

@Getter
public class AssetMasterResponse {

    @Schema(description = "자산 티커(symbol)")
    private final String ticker;

    @Schema(description = "자산 유형 (STOCK / ETF)")
    private final AssetType assetType;

    @Schema(description = "생성 시각 (UTC)")
    private final Instant createdAt;

    @Schema(description = "수정 시각 (UTC)")
    private final Instant updatedAt;

    public AssetMasterResponse(String ticker, AssetType assetType,
                               Instant createdAt, Instant updatedAt) {
        this.ticker = ticker;
        this.assetType = assetType;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }
}
