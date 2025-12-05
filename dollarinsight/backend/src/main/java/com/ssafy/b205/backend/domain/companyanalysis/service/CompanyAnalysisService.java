package com.ssafy.b205.backend.domain.companyanalysis.service;

import com.ssafy.b205.backend.domain.companyanalysis.dto.response.AssetBasicInfoResponse;
import com.ssafy.b205.backend.domain.companyanalysis.dto.response.AssetMasterResponse;
import com.ssafy.b205.backend.domain.companyanalysis.dto.response.AssetSearchResponse;
import com.ssafy.b205.backend.domain.companyanalysis.dto.response.CompanyDetailResponse;
import com.ssafy.b205.backend.domain.companyanalysis.dto.response.DailyPickResponse;
import com.ssafy.b205.backend.domain.companyanalysis.dto.response.DashboardResponse;
import com.ssafy.b205.backend.domain.companyanalysis.dto.response.EtfInvestmentIndicatorResponse;
import com.ssafy.b205.backend.domain.companyanalysis.dto.response.MajorIndexResponse;
import com.ssafy.b205.backend.domain.companyanalysis.dto.response.NewsDetailResponse;
import com.ssafy.b205.backend.domain.companyanalysis.dto.response.NewsHeadlineResponse;
import com.ssafy.b205.backend.domain.companyanalysis.dto.response.PagedNewsResponse;
import com.ssafy.b205.backend.domain.companyanalysis.dto.response.PersonaCommentResponse;
import com.ssafy.b205.backend.domain.companyanalysis.dto.response.PredictionBlockResponse;
import com.ssafy.b205.backend.domain.companyanalysis.dto.response.PredictionPointResponse;
import com.ssafy.b205.backend.domain.companyanalysis.dto.response.PriceCandleResponse;
import com.ssafy.b205.backend.domain.companyanalysis.dto.response.PriceOverviewResponse;
import com.ssafy.b205.backend.domain.companyanalysis.dto.response.PriceSeriesResponse;
import com.ssafy.b205.backend.domain.companyanalysis.dto.response.StockInvestmentIndicatorResponse;
import com.ssafy.b205.backend.domain.companyanalysis.dto.response.StockScoreResponse;
import com.ssafy.b205.backend.domain.companyanalysis.model.AssetType;
import com.ssafy.b205.backend.domain.companyanalysis.model.PersonaCommentSource;
import com.ssafy.b205.backend.domain.companyanalysis.repository.CompanyAnalysisQueryRepository;
import com.ssafy.b205.backend.domain.companyanalysis.repository.CompanyAnalysisQueryRepository.AssetMetadata;
import com.ssafy.b205.backend.domain.companyanalysis.repository.CompanyAnalysisQueryRepository.EtfMasterRow;
import com.ssafy.b205.backend.domain.companyanalysis.repository.CompanyAnalysisQueryRepository.EtfMetricsRow;
import com.ssafy.b205.backend.domain.companyanalysis.repository.CompanyAnalysisQueryRepository.LatestPriceRow;
import com.ssafy.b205.backend.domain.companyanalysis.repository.CompanyAnalysisQueryRepository.StockMasterRow;
import com.ssafy.b205.backend.domain.companyanalysis.repository.CompanyAnalysisQueryRepository.StockPredictionRow;
import com.ssafy.b205.backend.domain.companyanalysis.repository.CompanyAnalysisQueryRepository.StockScoreRow;
import com.ssafy.b205.backend.infra.mongo.companyanalysis.CompanyAnalysisMongoDao;
import com.ssafy.b205.backend.infra.mongo.companyanalysis.doc.CompanyAnalysisDoc;
import com.ssafy.b205.backend.infra.mongo.companyanalysis.doc.InvestingNewsDoc;
import com.ssafy.b205.backend.support.error.AppException;
import com.ssafy.b205.backend.support.error.ErrorCode;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.security.SecureRandom;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Locale;
import java.util.Random;
import java.util.function.Function;

@Slf4j
@Service
@Transactional(readOnly = true)
public class CompanyAnalysisService {

    private static final List<String> MAJOR_INDEX_TICKERS = List.of(".SPX", ".IXIC", ".DJI", ".SOX", ".VIX", ".RUT");
    private static final int DAILY_RANGE_DAYS = 30;
    private static final int WEEKLY_RANGE_DAYS = 90;
    private static final int MONTHLY_RANGE_DAYS = 365;
    private static final int MAX_SEARCH_SIZE = 30;
    private static final int DASHBOARD_NEWS_SAMPLE = 3;
    private static final List<AssetType> DEFAULT_MASTER_TYPES = List.of(AssetType.STOCK, AssetType.ETF);

    private final CompanyAnalysisQueryRepository repository;
    private final CompanyAnalysisMongoDao mongoDao;
    private final Random random = new SecureRandom();
    private static final List<PersonaMeta> PERSONAS = List.of(
            new PersonaMeta("DEOKSU", "덕수", "persona_deoksu", PersonaCommentSource::getPersonaDeoksu),
            new PersonaMeta("HEUYEOL", "희열", "persona_heuyeol", PersonaCommentSource::getPersonaHeuyeol),
            new PersonaMeta("JIYUL", "지율", "persona_jiyul", PersonaCommentSource::getPersonaJiyul),
            new PersonaMeta("MINJI", "민지", "persona_minji", PersonaCommentSource::getPersonaMinji),
            new PersonaMeta("TEO", "테오", "persona_teo", PersonaCommentSource::getPersonaTeo)
    );

    @Value("${app.market.fx.usd-krw:1350.0}")
    private BigDecimal usdKrwRate;

    public CompanyAnalysisService(CompanyAnalysisQueryRepository repository,
                                  CompanyAnalysisMongoDao mongoDao) {
        this.repository = repository;
        this.mongoDao = mongoDao;
    }

    public DashboardResponse getDashboard() {
        log.info("[CompanySvc-01] 기업분석 대시보드 조회");
        List<MajorIndexResponse> indices = repository.fetchMajorIndices(MAJOR_INDEX_TICKERS);
        List<NewsHeadlineResponse> recommended = mongoDao.sampleInvestingNews(DASHBOARD_NEWS_SAMPLE).stream()
                .map(this::toNewsHeadline)
                .toList();
        List<DailyPickResponse> dailyPicks = buildDailyPickCards();
        return new DashboardResponse(indices, recommended, dailyPicks);
    }

    public List<AssetSearchResponse> searchAssets(String keyword, int size) {
        String normalizedKeyword = normalizeKeyword(keyword);
        int limit = Math.min(Math.max(size, 1), MAX_SEARCH_SIZE);
        log.info("[CompanySvc-00] 티커 검색 keyword={}, size={}", normalizedKeyword, limit);
        return repository.searchAssets(normalizedKeyword, limit);
    }

    public List<AssetMasterResponse> listAssets(List<String> typeFilters) {
        List<AssetType> targetTypes = normalizeAssetTypes(typeFilters);
        log.info("[CompanySvc-08] 자산 마스터 전체 조회 types={}", targetTypes);
        return repository.findAssetsByTypes(targetTypes);
    }

    public CompanyDetailResponse getCompanyDetail(String rawTicker) {
        String ticker = normalizeTicker(rawTicker);
        log.info("[CompanySvc-02] 기업 상세 조회 ticker={}", ticker);
        AssetMetadata asset = repository.findAssetMetadata(ticker)
                .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND, "[CompanySvc-E01] 티커를 찾을 수 없습니다: " + ticker));

        AssetType assetType = asset.getType();
        return switch (assetType) {
            case STOCK -> buildStockDetail(ticker);
            case ETF -> buildEtfDetail(ticker);
            default -> throw new AppException(ErrorCode.BAD_REQUEST, "[CompanySvc-E02] 지원하지 않는 자산 타입: " + assetType);
        };
    }

    public PagedNewsResponse getNewsFeed(String ticker, int page, int size) {
        String normalized = hasText(ticker) ? normalizeTicker(ticker) : null;
        int safePage = Math.max(page, 0);
        int safeSize = Math.min(Math.max(size, 1), 100);
        log.info("[CompanySvc-03] 뉴스 피드 조회 ticker={}, page={}, size={}", normalized, safePage, safeSize);

        List<NewsHeadlineResponse> items = mongoDao.findInvestingNews(normalized, safePage, safeSize).stream()
                .map(this::toNewsHeadline)
                .toList();
        long total = mongoDao.countInvestingNews(normalized);
        return new PagedNewsResponse(items, total, safePage, safeSize);
    }

    public NewsDetailResponse getNewsDetail(String newsId) {
        log.info("[CompanySvc-04] 뉴스 상세 조회 newsId={}", newsId);
        InvestingNewsDoc doc = mongoDao.findInvestingNewsById(newsId)
                .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND, "[CompanySvc-E03] 뉴스 기사를 찾을 수 없습니다: " + newsId));

        List<PersonaCommentResponse> personaComments = mongoDao.findNewsPersonaByNewsId(newsId)
                .map(this::buildPersonaComments)
                .orElse(List.of());

        return new NewsDetailResponse(
                doc.getId(),
                doc.getTicker(),
                doc.getTitle(),
                doc.getSummary(),
                doc.getContent(),
                doc.getUrl(),
                doc.getPublishedAt(),
                personaComments
        );
    }

    private CompanyDetailResponse buildStockDetail(String ticker) {
        StockMasterRow master = repository.findStockMaster(ticker)
                .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND, "[CompanySvc-E04] 주식 마스터 데이터가 없습니다: " + ticker));
        LatestPriceRow latestPrice = repository.findLatestStockPrice(ticker)
                .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND, "[CompanySvc-E05] 주가 데이터가 없습니다: " + ticker));

        PriceSeriesResponse priceSeries = buildPriceSeries(ticker, true);
        PriceOverviewResponse overview = buildPriceOverview(latestPrice, priceSeries);

        PredictionBlockResponse predictions = new PredictionBlockResponse(
                repository.findStockPrediction(ticker, 5).map(this::toPredictionPoint).orElse(null),
                repository.findStockPrediction(ticker, 20).map(this::toPredictionPoint).orElse(null)
        );

        StockInvestmentIndicatorResponse stockIndicators = new StockInvestmentIndicatorResponse(
                prefer(master.getMarketCap(), master.getSharesOutstanding(), latestPrice.getClose()),
                master.getDividendYield(),
                master.getPbr(),
                master.getPer(),
                master.getRoe(),
                master.getPsr()
        );

        StockScoreResponse scores = repository.findLatestStockScore(ticker)
                .map(this::toStockScore)
                .orElse(null);

        List<PersonaCommentResponse> personaComments = repository.fetchPersonaComments(ticker, AssetType.STOCK);
        List<NewsHeadlineResponse> latestNews = fetchTickerNews(ticker, 5);

        return new CompanyDetailResponse(
                toStockBasicInfo(master),
                overview,
                priceSeries,
                predictions,
                stockIndicators,
                null,
                scores,
                personaComments,
                latestNews
        );
    }

    private CompanyDetailResponse buildEtfDetail(String ticker) {
        EtfMasterRow master = repository.findEtfMaster(ticker)
                .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND, "[CompanySvc-E06] ETF 마스터 데이터가 없습니다: " + ticker));
        LatestPriceRow latestPrice = repository.findLatestEtfPrice(ticker)
                .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND, "[CompanySvc-E07] ETF 가격 데이터가 없습니다: " + ticker));

        PriceSeriesResponse priceSeries = buildPriceSeries(ticker, false);
        PriceOverviewResponse overview = buildPriceOverview(latestPrice, priceSeries);

        EtfInvestmentIndicatorResponse etfIndicators = repository.findLatestEtfMetrics(ticker)
                .map(this::toEtfIndicators)
                .orElseGet(() -> new EtfInvestmentIndicatorResponse(
                        null, null, null, null, null, null, master.getExpenseRatio()
                ));

        List<PersonaCommentResponse> personaComments = repository.fetchPersonaComments(ticker, AssetType.ETF);
        List<NewsHeadlineResponse> latestNews = fetchTickerNews(ticker, 5);

        return new CompanyDetailResponse(
                toEtfBasicInfo(master),
                overview,
                priceSeries,
                null,
                null,
                etfIndicators,
                null,
                personaComments,
                latestNews
        );
    }

    private List<DailyPickResponse> buildDailyPickCards() {
        List<PersonaMeta> personaOrder = new ArrayList<>(PERSONAS);
        Collections.shuffle(personaOrder, random);

        List<DailyPickResponse> picks = new ArrayList<>();
        for (PersonaMeta persona : personaOrder) {
            DailyPickResponse pick = mongoDao.sampleCompanyAnalysisWithPersonaComment(persona.commentField())
                    .map(doc -> buildDailyPickCard(doc, persona))
                    .orElseGet(() -> fallbackDailyPickCard(persona));
            if (pick != null) {
                picks.add(pick);
            }
        }
        return picks;
    }

    private DailyPickResponse buildDailyPickCard(CompanyAnalysisDoc doc, PersonaMeta persona) {
        if (doc == null || !hasText(doc.getTicker())) {
            return null;
        }
        PersonaCommentResponse comment = toPersonaComment(doc, persona);
        if (comment == null) {
            return null;
        }
        return new DailyPickResponse(
                doc.getTicker(),
                doc.getCompanyName(),
                doc.getCompanyInfo(),
                doc.getAnalyzedDate(),
                comment
        );
    }

    private DailyPickResponse fallbackDailyPickCard(PersonaMeta persona) {
        List<CompanyAnalysisDoc> candidates = mongoDao.sampleCompanyAnalyses(1);
        if (candidates.isEmpty()) {
            return null;
        }
        CompanyAnalysisDoc doc = candidates.get(0);
        if (doc == null || !hasText(doc.getTicker())) {
            return null;
        }
        PersonaCommentResponse placeholder = new PersonaCommentResponse(
                persona.code(),
                persona.displayName(),
                buildPlaceholderComment(persona)
        );
        return new DailyPickResponse(
                doc.getTicker(),
                doc.getCompanyName(),
                doc.getCompanyInfo(),
                doc.getAnalyzedDate(),
                placeholder
        );
    }

    private String buildPlaceholderComment(PersonaMeta persona) {
        return persona.displayName() + "의 코멘트는 준비 중입니다.";
    }

    private PriceSeriesResponse buildPriceSeries(String ticker, boolean isStock) {
        LocalDate today = LocalDate.now(ZoneOffset.UTC);
        List<PriceCandleResponse> daily = isStock
                ? repository.fetchStockPrices(ticker, rangeStart(today, DAILY_RANGE_DAYS), today)
                : repository.fetchEtfPrices(ticker, rangeStart(today, DAILY_RANGE_DAYS), today);
        List<PriceCandleResponse> weekly = isStock
                ? repository.fetchStockPrices(ticker, rangeStart(today, WEEKLY_RANGE_DAYS), today)
                : repository.fetchEtfPrices(ticker, rangeStart(today, WEEKLY_RANGE_DAYS), today);
        List<PriceCandleResponse> monthly = isStock
                ? repository.fetchStockPrices(ticker, rangeStart(today, MONTHLY_RANGE_DAYS), today)
                : repository.fetchEtfPrices(ticker, rangeStart(today, MONTHLY_RANGE_DAYS), today);
        return new PriceSeriesResponse(daily, weekly, monthly);
    }

    private PriceOverviewResponse buildPriceOverview(LatestPriceRow latest, PriceSeriesResponse series) {
        BigDecimal periodLow = series.getDailyRange().stream()
                .map(PriceCandleResponse::getLow)
                .filter(v -> v != null)
                .min(BigDecimal::compareTo)
                .orElse(null);
        BigDecimal periodHigh = series.getDailyRange().stream()
                .map(PriceCandleResponse::getHigh)
                .filter(v -> v != null)
                .max(BigDecimal::compareTo)
                .orElse(null);

        return new PriceOverviewResponse(
                latest.getClose(),
                convertUsdToKrw(latest.getClose()),
                latest.getPriceDate(),
                latest.getChangePct(),
                periodLow,
                periodHigh
        );
    }

    private PredictionPointResponse toPredictionPoint(StockPredictionRow row) {
        return new PredictionPointResponse(
                row.getHorizonDays(),
                row.getPredictionDate(),
                row.getPointEstimate(),
                row.getLowerBound(),
                row.getUpperBound(),
                row.getProbabilityUp()
        );
    }

    private StockScoreResponse toStockScore(StockScoreRow row) {
        return new StockScoreResponse(
                row.getScoreDate(),
                row.getTotal(),
                row.getMomentum(),
                row.getValuation(),
                row.getGrowth(),
                row.getFlow(),
                row.getRisk()
        );
    }

    private EtfInvestmentIndicatorResponse toEtfIndicators(EtfMetricsRow row) {
        return new EtfInvestmentIndicatorResponse(
                row.getAsOfDate(),
                row.getMarketCap(),
                row.getDividendYield(),
                row.getTotalAssets(),
                row.getNav(),
                row.getPremiumDiscount(),
                row.getExpenseRatio()
        );
    }

    private AssetBasicInfoResponse toStockBasicInfo(StockMasterRow row) {
        return new AssetBasicInfoResponse(
                row.getTicker(),
                row.getName(),
                row.getNameEng(),
                AssetType.STOCK,
                row.getExchange(),
                row.getExchangeName(),
                row.getCurrency(),
                row.getCountry(),
                row.getSector(),
                row.getIndustry(),
                row.getListedAt(),
                row.getWebsite(),
                null,
                null
        );
    }

    private AssetBasicInfoResponse toEtfBasicInfo(EtfMasterRow row) {
        return new AssetBasicInfoResponse(
                row.getTicker(),
                row.getName(),
                null,
                AssetType.ETF,
                row.getExchange(),
                row.getExchangeName(),
                row.getCurrency(),
                row.getCurrencyName(),
                null,
                null,
                null,
                null,
                row.isLeverage(),
                row.getLeverageFactor()
        );
    }

    private List<PersonaCommentResponse> buildPersonaComments(PersonaCommentSource source) {
        if (source == null) {
            return List.of();
        }
        List<PersonaCommentResponse> comments = new ArrayList<>();
        for (PersonaMeta persona : PERSONAS) {
            PersonaCommentResponse comment = toPersonaComment(source, persona);
            if (comment != null) {
                comments.add(comment);
            }
        }
        return comments;
    }

    private PersonaCommentResponse toPersonaComment(PersonaCommentSource source, PersonaMeta persona) {
        if (source == null || persona == null) {
            return null;
        }
        String text = persona.extractor().apply(source);
        if (!StringUtils.hasText(text)) {
            return null;
        }
        return new PersonaCommentResponse(persona.code(), persona.displayName(), text);
    }

    private List<NewsHeadlineResponse> fetchTickerNews(String ticker, int size) {
        if (!hasText(ticker)) {
            return List.of();
        }
        String normalized = normalizeTicker(ticker);
        return mongoDao.findInvestingNewsByTicker(normalized, size).stream()
                .map(this::toNewsHeadline)
                .toList();
    }

    private NewsHeadlineResponse toNewsHeadline(InvestingNewsDoc doc) {
        return new NewsHeadlineResponse(
                doc.getId(),
                doc.getTicker(),
                doc.getTitle(),
                doc.getSummary(),
                doc.getUrl(),
                doc.getPublishedAt()
        );
    }

    private BigDecimal convertUsdToKrw(BigDecimal usd) {
        if (usd == null || usdKrwRate == null) return null;
        return usd.multiply(usdKrwRate).setScale(2, RoundingMode.HALF_UP);
    }

    private BigDecimal prefer(BigDecimal marketCap, Long sharesOutstanding, BigDecimal price) {
        if (marketCap != null) return marketCap;
        if (sharesOutstanding == null || price == null) return null;
        return price.multiply(BigDecimal.valueOf(sharesOutstanding));
    }

    private static LocalDate rangeStart(LocalDate end, int days) {
        return end.minusDays(Math.max(days - 1L, 0));
    }

    private List<AssetType> normalizeAssetTypes(List<String> rawTypes) {
        if (rawTypes == null || rawTypes.isEmpty()) {
            return DEFAULT_MASTER_TYPES;
        }
        List<AssetType> normalized = rawTypes.stream()
                .filter(CompanyAnalysisService::hasText)
                .map(String::trim)
                .map(type -> {
                    try {
                        return AssetType.fromDbValue(type);
                    } catch (IllegalArgumentException ex) {
                        throw new AppException(ErrorCode.BAD_REQUEST,
                                "[CompanySvc-E10] 지원하지 않는 자산 타입: " + type, ex);
                    }
                })
                .distinct()
                .toList();
        return normalized.isEmpty() ? DEFAULT_MASTER_TYPES : normalized;
    }

    private static String normalizeTicker(String ticker) {
        if (ticker == null) {
            throw new AppException(ErrorCode.BAD_REQUEST, "[CompanySvc-E08] ticker 파라미터는 필수입니다.");
        }
        String trimmed = ticker.trim();
        if (trimmed.isEmpty()) {
            throw new AppException(ErrorCode.BAD_REQUEST, "[CompanySvc-E08] ticker 파라미터는 필수입니다.");
        }
        return trimmed.toUpperCase(Locale.ROOT);
    }

    private static String normalizeKeyword(String keyword) {
        if (keyword == null) {
            throw new AppException(ErrorCode.BAD_REQUEST, "[CompanySvc-E09] 검색어는 필수입니다.");
        }
        String trimmed = keyword.trim();
        if (trimmed.isEmpty()) {
            throw new AppException(ErrorCode.BAD_REQUEST, "[CompanySvc-E09] 검색어는 필수입니다.");
        }
        return trimmed;
    }

    private static boolean hasText(String value) {
        return value != null && !value.trim().isEmpty();
    }

    private record PersonaMeta(String code, String displayName, String commentField,
                               Function<PersonaCommentSource, String> extractor) {
    }
}
