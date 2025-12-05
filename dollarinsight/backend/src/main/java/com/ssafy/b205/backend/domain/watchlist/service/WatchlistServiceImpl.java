package com.ssafy.b205.backend.domain.watchlist.service;

import com.ssafy.b205.backend.domain.companyanalysis.model.AssetType;
import com.ssafy.b205.backend.domain.companyanalysis.repository.CompanyAnalysisQueryRepository;
import com.ssafy.b205.backend.domain.companyanalysis.repository.CompanyAnalysisQueryRepository.AssetMetadata;
import com.ssafy.b205.backend.domain.companyanalysis.repository.CompanyAnalysisQueryRepository.EtfMasterRow;
import com.ssafy.b205.backend.domain.companyanalysis.repository.CompanyAnalysisQueryRepository.LatestPriceRow;
import com.ssafy.b205.backend.domain.companyanalysis.repository.CompanyAnalysisQueryRepository.StockMasterRow;
import com.ssafy.b205.backend.domain.user.entity.User;
import com.ssafy.b205.backend.domain.user.repository.UserRepository;
import com.ssafy.b205.backend.domain.watchlist.dto.response.WatchlistItemResponse;
import com.ssafy.b205.backend.domain.watchlist.entity.UserWatchlist;
import com.ssafy.b205.backend.domain.watchlist.repository.UserWatchlistRepository;
import com.ssafy.b205.backend.support.error.AppException;
import com.ssafy.b205.backend.support.error.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class WatchlistServiceImpl implements WatchlistService {

    private final UserRepository userRepository;
    private final UserWatchlistRepository watchlistRepository;
    private final CompanyAnalysisQueryRepository companyRepository;

    @Override
    public List<WatchlistItemResponse> getMyWatchlist(String userUuid) {
        User user = getActiveUser(userUuid);
        List<UserWatchlist> entries = watchlistRepository.findByUserOrderByCreatedAtDesc(user);
        if (entries.isEmpty()) {
            return List.of();
        }

        List<String> tickers = entries.stream()
                .map(UserWatchlist::getTicker)
                .distinct()
                .toList();

        Map<String, AssetMetadata> metadataMap = companyRepository.findAssetMetadata(tickers);
        tickers.forEach(ticker -> {
            if (!metadataMap.containsKey(ticker)) {
                throw new AppException(ErrorCode.NOT_FOUND,
                        "[WatchSvc-E04] 존재하지 않는 티커입니다: " + ticker);
            }
        });

        List<String> stockTickers = tickers.stream()
                .filter(t -> metadataMap.get(t).getType() == AssetType.STOCK)
                .toList();
        List<String> etfTickers = tickers.stream()
                .filter(t -> metadataMap.get(t).getType() == AssetType.ETF)
                .toList();

        Map<String, StockMasterRow> stockMasters = companyRepository.findStockMasters(stockTickers);
        Map<String, EtfMasterRow> etfMasters = companyRepository.findEtfMasters(etfTickers);
        Map<String, LatestPriceRow> stockPrices = companyRepository.findLatestStockPrices(stockTickers);
        Map<String, LatestPriceRow> etfPrices = companyRepository.findLatestEtfPrices(etfTickers);

        return entries.stream()
                .map(entry -> {
                    String ticker = entry.getTicker();
                    AssetMetadata metadata = metadataMap.get(ticker);
                    AssetSnapshot snapshot = toSnapshot(metadata, stockMasters, etfMasters);
                    LatestPriceRow latestPrice = metadata.getType() == AssetType.STOCK
                            ? stockPrices.get(ticker)
                            : metadata.getType() == AssetType.ETF
                                ? etfPrices.get(ticker)
                                : null;
                    LocalDate priceDate = latestPrice == null ? null : latestPrice.getPriceDate();
                    return new WatchlistItemResponse(
                            ticker,
                            snapshot.type(),
                            snapshot.name(),
                            snapshot.nameEng(),
                            snapshot.exchange(),
                            entry.getCreatedAt(),
                            priceDate,
                            latestPrice == null ? null : latestPrice.getClose(),
                            latestPrice == null ? null : latestPrice.getChangePct()
                    );
                })
                .toList();
    }

    @Override
    @Transactional
    public void add(String userUuid, String rawTicker) {
        User user = getActiveUser(userUuid);
        String ticker = normalizeTicker(rawTicker);
        AssetSnapshot snapshot = loadSnapshot(ticker);

        if (watchlistRepository.existsByUserAndTicker(user, ticker)) {
            throw new AppException(ErrorCode.CONFLICT, "[WatchSvc-E02] 이미 관심종목에 등록된 티커입니다.");
        }

        watchlistRepository.save(UserWatchlist.builder()
                .user(user)
                .ticker(snapshot.ticker())
                .build());
        log.info("[WatchSvc-01] 관심종목 등록 userId={}, ticker={}", user.getId(), ticker);
    }

    @Override
    @Transactional
    public void remove(String userUuid, String rawTicker) {
        User user = getActiveUser(userUuid);
        String ticker = normalizeTicker(rawTicker);
        loadSnapshot(ticker); // 존재 여부 검증

        UserWatchlist entry = watchlistRepository.findByUserAndTicker(user, ticker)
                .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND, "[WatchSvc-E03] 관심종목에 해당 티커가 없습니다."));
        watchlistRepository.delete(entry);
        log.info("[WatchSvc-02] 관심종목 삭제 userId={}, ticker={}", user.getId(), ticker);
    }

    @Override
    public boolean isWatching(String userUuid, String rawTicker) {
        User user = getActiveUser(userUuid);
        String ticker = normalizeTicker(rawTicker);
        loadSnapshot(ticker); // 검증
        return watchlistRepository.existsByUserAndTicker(user, ticker);
    }

    private AssetSnapshot toSnapshot(AssetMetadata metadata,
                                     Map<String, StockMasterRow> stockMasters,
                                     Map<String, EtfMasterRow> etfMasters) {
        String ticker = metadata.getTicker();
        return switch (metadata.getType()) {
            case STOCK -> {
                StockMasterRow row = stockMasters.get(ticker);
                if (row == null) {
                    throw new AppException(ErrorCode.NOT_FOUND,
                            "[WatchSvc-E05] 종목 기본정보가 없습니다: " + ticker);
                }
                yield new AssetSnapshot(metadata.getTicker(), metadata.getType(),
                        row.getName(), row.getNameEng(), row.getExchange());
            }
            case ETF -> {
                EtfMasterRow row = etfMasters.get(ticker);
                if (row == null) {
                    throw new AppException(ErrorCode.NOT_FOUND,
                            "[WatchSvc-E06] ETF 기본정보가 없습니다: " + ticker);
                }
                yield new AssetSnapshot(metadata.getTicker(), metadata.getType(),
                        row.getName(), null, row.getExchange());
            }
            default -> throw new AppException(ErrorCode.BAD_REQUEST,
                    "[WatchSvc-E07] 지원하지 않는 자산 유형입니다: " + metadata.getType());
        };
    }

    private AssetSnapshot loadSnapshot(String ticker) {
        AssetMetadata metadata = companyRepository.findAssetMetadata(ticker)
                .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND,
                        "[WatchSvc-E04] 존재하지 않는 티커입니다: " + ticker));

        return switch (metadata.getType()) {
            case STOCK -> {
                StockMasterRow row = companyRepository.findStockMaster(ticker)
                        .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND,
                                "[WatchSvc-E05] 종목 기본정보가 없습니다: " + ticker));
                yield new AssetSnapshot(metadata.getTicker(), metadata.getType(),
                        row.getName(), row.getNameEng(), row.getExchange());
            }
            case ETF -> {
                EtfMasterRow row = companyRepository.findEtfMaster(ticker)
                        .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND,
                                "[WatchSvc-E06] ETF 기본정보가 없습니다: " + ticker));
                yield new AssetSnapshot(metadata.getTicker(), metadata.getType(),
                        row.getName(), null, row.getExchange());
            }
            default -> throw new AppException(ErrorCode.BAD_REQUEST,
                    "[WatchSvc-E07] 지원하지 않는 자산 유형입니다: " + metadata.getType());
        };
    }

    private User getActiveUser(String userUuid) {
        return userRepository.findByUuidAndDeletedAtIsNull(UUID.fromString(userUuid))
                .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND,
                        "[WatchSvc-E01] 사용자 정보를 찾을 수 없습니다."));
    }

    private String normalizeTicker(String rawTicker) {
        if (rawTicker == null) {
            throw new AppException(ErrorCode.BAD_REQUEST, "[WatchSvc-E08] ticker는 필수입니다.");
        }
        String normalized = rawTicker.trim().toUpperCase(Locale.ROOT);
        if (normalized.isEmpty()) {
            throw new AppException(ErrorCode.BAD_REQUEST, "[WatchSvc-E08] ticker는 필수입니다.");
        }
        return normalized;
    }

    private record AssetSnapshot(String ticker, AssetType type, String name, String nameEng, String exchange) {}
}
