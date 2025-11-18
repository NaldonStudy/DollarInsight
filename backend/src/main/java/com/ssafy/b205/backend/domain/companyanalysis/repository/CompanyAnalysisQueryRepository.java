package com.ssafy.b205.backend.domain.companyanalysis.repository;

import com.ssafy.b205.backend.domain.companyanalysis.dto.response.AssetMasterResponse;
import com.ssafy.b205.backend.domain.companyanalysis.dto.response.AssetSearchResponse;
import com.ssafy.b205.backend.domain.companyanalysis.dto.response.MajorIndexResponse;
import com.ssafy.b205.backend.domain.companyanalysis.dto.response.PersonaCommentResponse;
import com.ssafy.b205.backend.domain.companyanalysis.dto.response.PriceCandleResponse;
import com.ssafy.b205.backend.domain.companyanalysis.model.AssetType;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Instant;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;

@Repository
public class CompanyAnalysisQueryRepository {

    private final NamedParameterJdbcTemplate jdbc;

    public CompanyAnalysisQueryRepository(NamedParameterJdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public Optional<AssetMetadata> findAssetMetadata(String ticker) {
        var sql = "SELECT ticker, asset_type FROM assets_master WHERE ticker = :ticker";
        var params = Map.of("ticker", ticker);
        List<AssetMetadata> rows = jdbc.query(sql, params,
                (rs, rowNum) -> new AssetMetadata(
                        rs.getString("ticker"),
                        AssetType.fromDbValue(rs.getString("asset_type"))
                ));
        return rows.isEmpty() ? Optional.empty() : Optional.of(rows.getFirst());
    }

    public Map<String, AssetMetadata> findAssetMetadata(Collection<String> tickers) {
        if (tickers == null || tickers.isEmpty()) {
            return Collections.emptyMap();
        }
        String sql = "SELECT ticker, asset_type FROM assets_master WHERE ticker IN (:tickers)";
        var params = new MapSqlParameterSource().addValue("tickers", tickers);
        Map<String, AssetMetadata> result = new HashMap<>();
        jdbc.query(sql, params, (rs) -> {
            AssetMetadata metadata = new AssetMetadata(
                    rs.getString("ticker"),
                    AssetType.fromDbValue(rs.getString("asset_type"))
            );
            result.put(metadata.getTicker(), metadata);
        });
        return result;
    }

    public Optional<StockMasterRow> findStockMaster(String ticker) {
        String sql = """
            SELECT ticker, name, name_eng, exchange, exchange_name, currency,
                   country_name, sector_name, industry, listed_at, website,
                   shares_outstanding, market_cap, dividend_yield_annualized,
                   pbr, per, roe, psr
            FROM stocks_master
            WHERE ticker = :ticker
            """;
        List<StockMasterRow> rows = jdbc.query(sql, Map.of("ticker", ticker), (rs, rowNum) -> new StockMasterRow(
                rs.getString("ticker"),
                rs.getString("name"),
                rs.getString("name_eng"),
                rs.getString("exchange"),
                rs.getString("exchange_name"),
                rs.getString("currency"),
                rs.getString("country_name"),
                rs.getString("sector_name"),
                rs.getString("industry"),
                rs.getObject("listed_at", LocalDate.class),
                rs.getString("website"),
                getLong(rs, "shares_outstanding"),
                getBigDecimal(rs, "market_cap"),
                getBigDecimal(rs, "dividend_yield_annualized"),
                getBigDecimal(rs, "pbr"),
                getBigDecimal(rs, "per"),
                getBigDecimal(rs, "roe"),
                getBigDecimal(rs, "psr")
        ));
        return rows.isEmpty() ? Optional.empty() : Optional.of(rows.getFirst());
    }

    public Map<String, StockMasterRow> findStockMasters(Collection<String> tickers) {
        if (tickers == null || tickers.isEmpty()) {
            return Collections.emptyMap();
        }
        String sql = """
            SELECT ticker, name, name_eng, exchange, exchange_name, currency,
                   country_name, sector_name, industry, listed_at, website,
                   shares_outstanding, market_cap, dividend_yield_annualized,
                   pbr, per, roe, psr
            FROM stocks_master
            WHERE ticker IN (:tickers)
            """;
        var params = new MapSqlParameterSource().addValue("tickers", tickers);
        Map<String, StockMasterRow> result = new HashMap<>();
        jdbc.query(sql, params, (rs) -> {
            StockMasterRow row = new StockMasterRow(
                    rs.getString("ticker"),
                    rs.getString("name"),
                    rs.getString("name_eng"),
                    rs.getString("exchange"),
                    rs.getString("exchange_name"),
                    rs.getString("currency"),
                    rs.getString("country_name"),
                    rs.getString("sector_name"),
                    rs.getString("industry"),
                    rs.getObject("listed_at", LocalDate.class),
                    rs.getString("website"),
                    getLong(rs, "shares_outstanding"),
                    getBigDecimal(rs, "market_cap"),
                    getBigDecimal(rs, "dividend_yield_annualized"),
                    getBigDecimal(rs, "pbr"),
                    getBigDecimal(rs, "per"),
                    getBigDecimal(rs, "roe"),
                    getBigDecimal(rs, "psr")
            );
            result.put(row.getTicker(), row);
        });
        return result;
    }

    public Optional<EtfMasterRow> findEtfMaster(String ticker) {
        String sql = """
            SELECT ticker, name, exchange, exchange_name, currency, currency_name,
                   expense_ratio, is_leverage, leverage_factor
            FROM etf_master
            WHERE ticker = :ticker
            """;
        List<EtfMasterRow> rows = jdbc.query(sql, Map.of("ticker", ticker), (rs, rowNum) -> new EtfMasterRow(
                rs.getString("ticker"),
                rs.getString("name"),
                rs.getString("exchange"),
                rs.getString("exchange_name"),
                rs.getString("currency"),
                rs.getString("currency_name"),
                getBigDecimal(rs, "expense_ratio"),
                rs.getBoolean("is_leverage"),
                getBigDecimal(rs, "leverage_factor")
        ));
        return rows.isEmpty() ? Optional.empty() : Optional.of(rows.getFirst());
    }

    public Map<String, EtfMasterRow> findEtfMasters(Collection<String> tickers) {
        if (tickers == null || tickers.isEmpty()) {
            return Collections.emptyMap();
        }
        String sql = """
            SELECT ticker, name, exchange, exchange_name, currency, currency_name,
                   expense_ratio, is_leverage, leverage_factor
            FROM etf_master
            WHERE ticker IN (:tickers)
            """;
        var params = new MapSqlParameterSource().addValue("tickers", tickers);
        Map<String, EtfMasterRow> result = new HashMap<>();
        jdbc.query(sql, params, (rs) -> {
            EtfMasterRow row = new EtfMasterRow(
                    rs.getString("ticker"),
                    rs.getString("name"),
                    rs.getString("exchange"),
                    rs.getString("exchange_name"),
                    rs.getString("currency"),
                    rs.getString("currency_name"),
                    getBigDecimal(rs, "expense_ratio"),
                    rs.getBoolean("is_leverage"),
                    getBigDecimal(rs, "leverage_factor")
            );
            result.put(row.getTicker(), row);
        });
        return result;
    }

    public Optional<LatestPriceRow> findLatestStockPrice(String ticker) {
        return findLatestPrice("stock_price_daily", ticker, true);
    }

    public Optional<LatestPriceRow> findLatestEtfPrice(String ticker) {
        return findLatestPrice("etf_price_daily", ticker, false);
    }

    public Map<String, LatestPriceRow> findLatestStockPrices(Collection<String> tickers) {
        return findLatestPrices("stock_price_daily", tickers, true);
    }

    public Map<String, LatestPriceRow> findLatestEtfPrices(Collection<String> tickers) {
        return findLatestPrices("etf_price_daily", tickers, false);
    }

    public List<AssetMasterResponse> findAssetsByTypes(List<AssetType> types) {
        if (types == null || types.isEmpty()) {
            return List.of();
        }
        List<String> typeValues = types.stream()
                .map(type -> type.name().toLowerCase(Locale.ROOT))
                .toList();
        String sql = """
            SELECT ticker, asset_type, created_at, updated_at
            FROM assets_master
            WHERE asset_type IN (:assetTypes)
            ORDER BY ticker
            """;
        var params = new MapSqlParameterSource().addValue("assetTypes", typeValues);
        return jdbc.query(sql, params, (rs, rowNum) -> new AssetMasterResponse(
                rs.getString("ticker"),
                AssetType.fromDbValue(rs.getString("asset_type")),
                rs.getObject("created_at", OffsetDateTime.class).toInstant(),
                rs.getObject("updated_at", OffsetDateTime.class).toInstant()
        ));
    }

    public List<AssetSearchResponse> searchAssets(String keyword, int limit) {
        String sql = """
            WITH targets AS (
                SELECT s.ticker,
                       'STOCK' AS asset_type,
                       s.name,
                       s.name_eng,
                       s.exchange
                FROM stocks_master s
                WHERE s.is_delisted = false
                  AND (
                        s.ticker ILIKE :pattern
                        OR s.name ILIKE :pattern
                        OR COALESCE(s.name_eng, '') ILIKE :pattern
                      )
                UNION ALL
                SELECT e.ticker,
                       'ETF' AS asset_type,
                       e.name,
                       NULL AS name_eng,
                       e.exchange
                FROM etf_master e
                WHERE e.ticker ILIKE :pattern
                   OR e.name ILIKE :pattern
            )
            SELECT *
            FROM targets
            ORDER BY ticker
            LIMIT :limit
            """;
        var params = new MapSqlParameterSource()
                .addValue("pattern", "%" + keyword + "%")
                .addValue("limit", limit);
        return jdbc.query(sql, params, (rs, rowNum) -> new AssetSearchResponse(
                rs.getString("ticker"),
                AssetType.fromDbValue(rs.getString("asset_type")),
                rs.getString("name"),
                rs.getString("name_eng"),
                rs.getString("exchange")
        ));
    }

    private Optional<LatestPriceRow> findLatestPrice(String tableName, String ticker, boolean includeChangePct) {
        String selectColumns = includeChangePct ? "price_date, close, change_pct" : "price_date, close";
        String sql = """
            SELECT %s
            FROM %s
            WHERE ticker = :ticker
            ORDER BY price_date DESC
            LIMIT 1
            """.formatted(selectColumns, tableName);
        List<LatestPriceRow> rows = jdbc.query(sql, Map.of("ticker", ticker), (rs, rowNum) -> new LatestPriceRow(
                rs.getObject("price_date", LocalDate.class),
                getBigDecimal(rs, "close"),
                includeChangePct ? getBigDecimal(rs, "change_pct") : null
        ));
        return rows.isEmpty() ? Optional.empty() : Optional.of(rows.getFirst());
    }

    private Map<String, LatestPriceRow> findLatestPrices(String tableName, Collection<String> tickers,
                                                         boolean includeChangePct) {
        if (tickers == null || tickers.isEmpty()) {
            return Collections.emptyMap();
        }
        String selectColumns = includeChangePct
                ? "p.ticker, p.price_date, p.close, p.change_pct"
                : "p.ticker, p.price_date, p.close";
        String sql = """
            SELECT %s
            FROM %s p
            INNER JOIN (
                SELECT ticker, MAX(price_date) AS price_date
                FROM %s
                WHERE ticker IN (:tickers)
                GROUP BY ticker
            ) latest ON p.ticker = latest.ticker AND p.price_date = latest.price_date
            """.formatted(selectColumns, tableName, tableName);
        var params = new MapSqlParameterSource().addValue("tickers", tickers);
        Map<String, LatestPriceRow> result = new HashMap<>();
        jdbc.query(sql, params, (rs) -> {
            LatestPriceRow row = new LatestPriceRow(
                    rs.getObject("price_date", LocalDate.class),
                    getBigDecimal(rs, "close"),
                    includeChangePct ? getBigDecimal(rs, "change_pct") : null
            );
            result.put(rs.getString("ticker"), row);
        });
        return result;
    }

    public List<PriceCandleResponse> fetchStockPrices(String ticker, LocalDate start, LocalDate end) {
        return fetchPrices("stock_price_daily", ticker, start, end);
    }

    public List<PriceCandleResponse> fetchEtfPrices(String ticker, LocalDate start, LocalDate end) {
        return fetchPrices("etf_price_daily", ticker, start, end);
    }

    private List<PriceCandleResponse> fetchPrices(String table, String ticker, LocalDate start, LocalDate end) {
        String sql = """
            SELECT price_date, open, high, low, close
            FROM %s
            WHERE ticker = :ticker
              AND price_date BETWEEN :start AND :end
            ORDER BY price_date
            """.formatted(table);
        var params = new MapSqlParameterSource()
                .addValue("ticker", ticker)
                .addValue("start", start)
                .addValue("end", end);
        return jdbc.query(sql, params, (rs, rowNum) -> new PriceCandleResponse(
                rs.getObject("price_date", LocalDate.class),
                getBigDecimal(rs, "open"),
                getBigDecimal(rs, "high"),
                getBigDecimal(rs, "low"),
                getBigDecimal(rs, "close")
        ));
    }

    public Optional<StockPredictionRow> findStockPrediction(String ticker, int horizonDays) {
        String sql = """
            SELECT prediction_date, horizon_days, point_estimate, lower_bound, upper_bound, prob_up
            FROM stock_predictions_daily
            WHERE ticker = :ticker
              AND horizon_days = :horizon
            ORDER BY prediction_date DESC
            LIMIT 1
            """;
        var params = new MapSqlParameterSource()
                .addValue("ticker", ticker)
                .addValue("horizon", horizonDays);
        List<StockPredictionRow> rows = jdbc.query(sql, params, (rs, rowNum) -> new StockPredictionRow(
                rs.getObject("prediction_date", LocalDate.class),
                rs.getInt("horizon_days"),
                getBigDecimal(rs, "point_estimate"),
                getBigDecimal(rs, "lower_bound"),
                getBigDecimal(rs, "upper_bound"),
                getBigDecimal(rs, "prob_up")
        ));
        return rows.isEmpty() ? Optional.empty() : Optional.of(rows.getFirst());
    }

    public Optional<StockScoreRow> findLatestStockScore(String ticker) {
        String sql = """
            SELECT score_date, total_score, score_momentum, score_valuation,
                   score_growth, score_flow, score_risk
            FROM stock_scores_daily
            WHERE ticker = :ticker
            ORDER BY score_date DESC
            LIMIT 1
            """;
        List<StockScoreRow> rows = jdbc.query(sql, Map.of("ticker", ticker), (rs, rowNum) -> new StockScoreRow(
                rs.getObject("score_date", LocalDate.class),
                getBigDecimal(rs, "total_score"),
                getBigDecimal(rs, "score_momentum"),
                getBigDecimal(rs, "score_valuation"),
                getBigDecimal(rs, "score_growth"),
                getBigDecimal(rs, "score_flow"),
                getBigDecimal(rs, "score_risk")
        ));
        return rows.isEmpty() ? Optional.empty() : Optional.of(rows.getFirst());
    }

    public Optional<EtfMetricsRow> findLatestEtfMetrics(String ticker) {
        String sql = """
            SELECT as_of_date, market_cap, dividend_yield, total_assets,
                   nav, premium_discount, expense_ratio
            FROM etf_metrics_daily
            WHERE ticker = :ticker
            ORDER BY as_of_date DESC
            LIMIT 1
            """;
        List<EtfMetricsRow> rows = jdbc.query(sql, Map.of("ticker", ticker), (rs, rowNum) -> new EtfMetricsRow(
                rs.getObject("as_of_date", LocalDate.class),
                getBigDecimal(rs, "market_cap"),
                getBigDecimal(rs, "dividend_yield"),
                getBigDecimal(rs, "total_assets"),
                getBigDecimal(rs, "nav"),
                getBigDecimal(rs, "premium_discount"),
                getBigDecimal(rs, "expense_ratio")
        ));
        return rows.isEmpty() ? Optional.empty() : Optional.of(rows.getFirst());
    }

    public List<PersonaCommentResponse> fetchPersonaComments(String ticker, AssetType type) {
        String table = switch (type) {
            case STOCK -> "stocks_persona";
            case ETF -> "etf_persona";
            default -> null;
        };
        if (table == null) {
            return Collections.emptyList();
        }
        String sql = """
            SELECT p.code, p.name_ko, sp.comment
            FROM %s sp
            JOIN personas p ON p.id = sp.persona_id
            WHERE sp.ticker = :ticker
            ORDER BY p.id
            """.formatted(table);
        return jdbc.query(sql, Map.of("ticker", ticker), (rs, rowNum) -> new PersonaCommentResponse(
                rs.getString("code"),
                rs.getString("name_ko"),
                rs.getString("comment")
        ));
    }

    public List<MajorIndexResponse> fetchMajorIndices(List<String> tickers) {
        if (tickers == null || tickers.isEmpty()) {
            return List.of();
        }
        String sql = """
            SELECT im.ticker, im.name, ip.price_date, ip.close, ip.change_pct
            FROM index_master im
            JOIN LATERAL (
                SELECT price_date, close, change_pct
                FROM index_price_daily
                WHERE ticker = im.ticker
                ORDER BY price_date DESC
                LIMIT 1
            ) ip ON TRUE
            WHERE im.ticker IN (:tickers)
            """;
        var params = new MapSqlParameterSource().addValue("tickers", tickers);
        return jdbc.query(sql, params, (rs, rowNum) -> new MajorIndexResponse(
                rs.getString("ticker"),
                rs.getString("name"),
                getBigDecimal(rs, "close"),
                getBigDecimal(rs, "change_pct"),
                rs.getObject("price_date", LocalDate.class)
        ));
    }

    private static Instant toInstant(ResultSet rs, String column) throws SQLException {
        OffsetDateTime odt = rs.getObject(column, OffsetDateTime.class);
        return odt == null ? null : odt.toInstant();
    }

    private static BigDecimal getBigDecimal(ResultSet rs, String column) throws SQLException {
        String raw = rs.getString(column);
        if (raw == null) {
            return null;
        }
        String normalized = raw.trim();
        if (normalized.isEmpty()) {
            return null;
        }
        String lower = normalized.toLowerCase(Locale.ROOT);
        if ("nan".equals(lower) || "infinity".equals(lower) || "+infinity".equals(lower) || "-infinity".equals(lower)) {
            return null;
        }
        return new BigDecimal(normalized);
    }

    private static Long getLong(ResultSet rs, String column) throws SQLException {
        long value = rs.getLong(column);
        return rs.wasNull() ? null : value;
    }

    public static class AssetMetadata {
        private final String ticker;
        private final AssetType type;

        public AssetMetadata(String ticker, AssetType type) {
            this.ticker = ticker;
            this.type = type;
        }

        public String getTicker() {
            return ticker;
        }

        public AssetType getType() {
            return type;
        }
    }

    public static class StockMasterRow {
        private final String ticker;
        private final String name;
        private final String nameEng;
        private final String exchange;
        private final String exchangeName;
        private final String currency;
        private final String country;
        private final String sector;
        private final String industry;
        private final LocalDate listedAt;
        private final String website;
        private final Long sharesOutstanding;
        private final BigDecimal marketCap;
        private final BigDecimal dividendYield;
        private final BigDecimal pbr;
        private final BigDecimal per;
        private final BigDecimal roe;
        private final BigDecimal psr;

        public StockMasterRow(String ticker, String name, String nameEng,
                              String exchange, String exchangeName, String currency,
                              String country, String sector, String industry,
                              LocalDate listedAt, String website, Long sharesOutstanding,
                              BigDecimal marketCap, BigDecimal dividendYield,
                              BigDecimal pbr, BigDecimal per, BigDecimal roe, BigDecimal psr) {
            this.ticker = ticker;
            this.name = name;
            this.nameEng = nameEng;
            this.exchange = exchange;
            this.exchangeName = exchangeName;
            this.currency = currency;
            this.country = country;
            this.sector = sector;
            this.industry = industry;
            this.listedAt = listedAt;
            this.website = website;
            this.sharesOutstanding = sharesOutstanding;
            this.marketCap = marketCap;
            this.dividendYield = dividendYield;
            this.pbr = pbr;
            this.per = per;
            this.roe = roe;
            this.psr = psr;
        }

        public String getTicker() {
            return ticker;
        }

        public String getName() {
            return name;
        }

        public String getNameEng() {
            return nameEng;
        }

        public String getExchange() {
            return exchange;
        }

        public String getExchangeName() {
            return exchangeName;
        }

        public String getCurrency() {
            return currency;
        }

        public String getCountry() {
            return country;
        }

        public String getSector() {
            return sector;
        }

        public String getIndustry() {
            return industry;
        }

        public LocalDate getListedAt() {
            return listedAt;
        }

        public String getWebsite() {
            return website;
        }

        public Long getSharesOutstanding() {
            return sharesOutstanding;
        }

        public BigDecimal getMarketCap() {
            return marketCap;
        }

        public BigDecimal getDividendYield() {
            return dividendYield;
        }

        public BigDecimal getPbr() {
            return pbr;
        }

        public BigDecimal getPer() {
            return per;
        }

        public BigDecimal getRoe() {
            return roe;
        }

        public BigDecimal getPsr() {
            return psr;
        }
    }

    public static class EtfMasterRow {
        private final String ticker;
        private final String name;
        private final String exchange;
        private final String exchangeName;
        private final String currency;
        private final String currencyName;
        private final BigDecimal expenseRatio;
        private final boolean leverage;
        private final BigDecimal leverageFactor;

        public EtfMasterRow(String ticker, String name, String exchange,
                            String exchangeName, String currency, String currencyName,
                            BigDecimal expenseRatio, boolean leverage, BigDecimal leverageFactor) {
            this.ticker = ticker;
            this.name = name;
            this.exchange = exchange;
            this.exchangeName = exchangeName;
            this.currency = currency;
            this.currencyName = currencyName;
            this.expenseRatio = expenseRatio;
            this.leverage = leverage;
            this.leverageFactor = leverageFactor;
        }

        public String getTicker() {
            return ticker;
        }

        public String getName() {
            return name;
        }

        public String getExchange() {
            return exchange;
        }

        public String getExchangeName() {
            return exchangeName;
        }

        public String getCurrency() {
            return currency;
        }

        public String getCurrencyName() {
            return currencyName;
        }

        public BigDecimal getExpenseRatio() {
            return expenseRatio;
        }

        public boolean isLeverage() {
            return leverage;
        }

        public BigDecimal getLeverageFactor() {
            return leverageFactor;
        }
    }

    public static class LatestPriceRow {
        private final LocalDate priceDate;
        private final BigDecimal close;
        private final BigDecimal changePct;

        public LatestPriceRow(LocalDate priceDate, BigDecimal close, BigDecimal changePct) {
            this.priceDate = priceDate;
            this.close = close;
            this.changePct = changePct;
        }

        public LocalDate getPriceDate() {
            return priceDate;
        }

        public BigDecimal getClose() {
            return close;
        }

        public BigDecimal getChangePct() {
            return changePct;
        }
    }

    public static class StockPredictionRow {
        private final LocalDate predictionDate;
        private final int horizonDays;
        private final BigDecimal pointEstimate;
        private final BigDecimal lowerBound;
        private final BigDecimal upperBound;
        private final BigDecimal probabilityUp;

        public StockPredictionRow(LocalDate predictionDate, int horizonDays, BigDecimal pointEstimate,
                                  BigDecimal lowerBound, BigDecimal upperBound, BigDecimal probabilityUp) {
            this.predictionDate = predictionDate;
            this.horizonDays = horizonDays;
            this.pointEstimate = pointEstimate;
            this.lowerBound = lowerBound;
            this.upperBound = upperBound;
            this.probabilityUp = probabilityUp;
        }

        public LocalDate getPredictionDate() {
            return predictionDate;
        }

        public int getHorizonDays() {
            return horizonDays;
        }

        public BigDecimal getPointEstimate() {
            return pointEstimate;
        }

        public BigDecimal getLowerBound() {
            return lowerBound;
        }

        public BigDecimal getUpperBound() {
            return upperBound;
        }

        public BigDecimal getProbabilityUp() {
            return probabilityUp;
        }
    }

    public static class StockScoreRow {
        private final LocalDate scoreDate;
        private final BigDecimal total;
        private final BigDecimal momentum;
        private final BigDecimal valuation;
        private final BigDecimal growth;
        private final BigDecimal flow;
        private final BigDecimal risk;

        public StockScoreRow(LocalDate scoreDate, BigDecimal total, BigDecimal momentum,
                             BigDecimal valuation, BigDecimal growth, BigDecimal flow, BigDecimal risk) {
            this.scoreDate = scoreDate;
            this.total = total;
            this.momentum = momentum;
            this.valuation = valuation;
            this.growth = growth;
            this.flow = flow;
            this.risk = risk;
        }

        public LocalDate getScoreDate() {
            return scoreDate;
        }

        public BigDecimal getTotal() {
            return total;
        }

        public BigDecimal getMomentum() {
            return momentum;
        }

        public BigDecimal getValuation() {
            return valuation;
        }

        public BigDecimal getGrowth() {
            return growth;
        }

        public BigDecimal getFlow() {
            return flow;
        }

        public BigDecimal getRisk() {
            return risk;
        }
    }

    public static class EtfMetricsRow {
        private final LocalDate asOfDate;
        private final BigDecimal marketCap;
        private final BigDecimal dividendYield;
        private final BigDecimal totalAssets;
        private final BigDecimal nav;
        private final BigDecimal premiumDiscount;
        private final BigDecimal expenseRatio;

        public EtfMetricsRow(LocalDate asOfDate, BigDecimal marketCap, BigDecimal dividendYield,
                             BigDecimal totalAssets, BigDecimal nav, BigDecimal premiumDiscount,
                             BigDecimal expenseRatio) {
            this.asOfDate = asOfDate;
            this.marketCap = marketCap;
            this.dividendYield = dividendYield;
            this.totalAssets = totalAssets;
            this.nav = nav;
            this.premiumDiscount = premiumDiscount;
            this.expenseRatio = expenseRatio;
        }

        public LocalDate getAsOfDate() {
            return asOfDate;
        }

        public BigDecimal getMarketCap() {
            return marketCap;
        }

        public BigDecimal getDividendYield() {
            return dividendYield;
        }

        public BigDecimal getTotalAssets() {
            return totalAssets;
        }

        public BigDecimal getNav() {
            return nav;
        }

        public BigDecimal getPremiumDiscount() {
            return premiumDiscount;
        }

        public BigDecimal getExpenseRatio() {
            return expenseRatio;
        }
    }

}
