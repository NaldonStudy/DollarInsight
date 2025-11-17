package com.ssafy.b205.backend.domain.watchlist.service;

import com.ssafy.b205.backend.domain.companyanalysis.model.AssetType;
import com.ssafy.b205.backend.domain.companyanalysis.repository.CompanyAnalysisQueryRepository;
import com.ssafy.b205.backend.domain.companyanalysis.repository.CompanyAnalysisQueryRepository.AssetMetadata;
import com.ssafy.b205.backend.domain.companyanalysis.repository.CompanyAnalysisQueryRepository.EtfMasterRow;
import com.ssafy.b205.backend.domain.companyanalysis.repository.CompanyAnalysisQueryRepository.LatestPriceRow;
import com.ssafy.b205.backend.domain.companyanalysis.repository.CompanyAnalysisQueryRepository.StockMasterRow;
import com.ssafy.b205.backend.domain.user.entity.User;
import com.ssafy.b205.backend.domain.user.entity.UserStatus;
import com.ssafy.b205.backend.domain.user.repository.UserRepository;
import com.ssafy.b205.backend.domain.watchlist.entity.UserWatchlist;
import com.ssafy.b205.backend.domain.watchlist.repository.UserWatchlistRepository;
import com.ssafy.b205.backend.support.error.AppException;
import com.ssafy.b205.backend.support.error.ErrorCode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class WatchlistServiceImplTest {

    @Mock
    private UserRepository userRepository;
    @Mock
    private UserWatchlistRepository watchlistRepository;
    @Mock
    private CompanyAnalysisQueryRepository companyRepository;

    private WatchlistServiceImpl service;

    @BeforeEach
    void setUp() {
        service = new WatchlistServiceImpl(userRepository, watchlistRepository, companyRepository);
    }

    @Test
    void getMyWatchlistAggregatesMetadataAndPrices() {
        User user = createUser();
        when(userRepository.findByUuidAndDeletedAtIsNull(user.getUuid())).thenReturn(Optional.of(user));
        UserWatchlist stockEntry = UserWatchlist.builder()
                .user(user)
                .ticker("AAA")
                .createdAt(LocalDateTime.now().minusDays(1))
                .build();
        UserWatchlist etfEntry = UserWatchlist.builder()
                .user(user)
                .ticker("BBB")
                .createdAt(LocalDateTime.now())
                .build();
        when(watchlistRepository.findByUserOrderByCreatedAtDesc(user)).thenReturn(List.of(stockEntry, etfEntry));
        when(companyRepository.findAssetMetadata(anyCollection())).thenReturn(Map.of(
                "AAA", new AssetMetadata("AAA", AssetType.STOCK),
                "BBB", new AssetMetadata("BBB", AssetType.ETF)
        ));
        StockMasterRow stockRow = mock(StockMasterRow.class);
        when(stockRow.getName()).thenReturn("Stock Co");
        when(stockRow.getNameEng()).thenReturn("Stock Co Eng");
        when(stockRow.getExchange()).thenReturn("NYSE");
        EtfMasterRow etfRow = mock(EtfMasterRow.class);
        when(etfRow.getName()).thenReturn("ETF Fund");
        when(etfRow.getExchange()).thenReturn("NASDAQ");
        when(companyRepository.findStockMasters(anyCollection())).thenReturn(Map.of("AAA", stockRow));
        when(companyRepository.findEtfMasters(anyCollection())).thenReturn(Map.of("BBB", etfRow));
        when(companyRepository.findLatestStockPrices(anyCollection())).thenReturn(Map.of(
                "AAA", new LatestPriceRow(LocalDate.of(2024, 1, 1), BigDecimal.TEN, BigDecimal.valueOf(1.5))
        ));
        when(companyRepository.findLatestEtfPrices(anyCollection())).thenReturn(Map.of(
                "BBB", new LatestPriceRow(LocalDate.of(2024, 1, 2), BigDecimal.ONE, BigDecimal.ZERO)
        ));

        var result = service.getMyWatchlist(user.getUuid().toString());

        assertThat(result).hasSize(2);
        assertThat(result.getFirst().getTicker()).isEqualTo("AAA");
        assertThat(result.getFirst().getName()).isEqualTo("Stock Co");
        assertThat(result.getFirst().getLastPrice()).isEqualTo(BigDecimal.TEN);
        assertThat(result.get(1).getTicker()).isEqualTo("BBB");
        assertThat(result.get(1).getName()).isEqualTo("ETF Fund");
        assertThat(result.get(1).getLastPriceDate()).isEqualTo(LocalDate.of(2024, 1, 2));
    }

    @Test
    void addSavesNormalizedTickerWhenNotExists() {
        User user = createUser();
        when(userRepository.findByUuidAndDeletedAtIsNull(user.getUuid())).thenReturn(Optional.of(user));
        when(watchlistRepository.existsByUserAndTicker(user, "AAA")).thenReturn(false);
        stubStockAsset("AAA");

        service.add(user.getUuid().toString(), "  aaa ");

        ArgumentCaptor<UserWatchlist> captor = ArgumentCaptor.forClass(UserWatchlist.class);
        verify(watchlistRepository).save(captor.capture());
        assertThat(captor.getValue().getTicker()).isEqualTo("AAA");
        assertThat(captor.getValue().getUser()).isEqualTo(user);
    }

    @Test
    void addThrowsWhenAlreadyExists() {
        User user = createUser();
        when(userRepository.findByUuidAndDeletedAtIsNull(user.getUuid())).thenReturn(Optional.of(user));
        stubStockAsset("AAA");
        when(watchlistRepository.existsByUserAndTicker(user, "AAA")).thenReturn(true);

        assertThatThrownBy(() -> service.add(user.getUuid().toString(), "AAA"))
                .isInstanceOf(AppException.class)
                .hasFieldOrPropertyWithValue("code", ErrorCode.CONFLICT);
    }

    @Test
    void removeDeletesEntry() {
        User user = createUser();
        when(userRepository.findByUuidAndDeletedAtIsNull(user.getUuid())).thenReturn(Optional.of(user));
        stubStockAsset("AAA");
        UserWatchlist entry = UserWatchlist.builder()
                .user(user)
                .ticker("AAA")
                .createdAt(LocalDateTime.now())
                .build();
        when(watchlistRepository.findByUserAndTicker(user, "AAA")).thenReturn(Optional.of(entry));

        service.remove(user.getUuid().toString(), "AAA");

        verify(watchlistRepository).delete(entry);
    }

    @Test
    void isWatchingReturnsTrueWhenExists() {
        User user = createUser();
        when(userRepository.findByUuidAndDeletedAtIsNull(user.getUuid())).thenReturn(Optional.of(user));
        stubStockAsset("AAA");
        when(watchlistRepository.existsByUserAndTicker(user, "AAA")).thenReturn(true);

        boolean watching = service.isWatching(user.getUuid().toString(), "AAA");

        assertThat(watching).isTrue();
    }

    @Test
    void getMyWatchlistThrowsWhenMetadataMissing() {
        User user = createUser();
        when(userRepository.findByUuidAndDeletedAtIsNull(user.getUuid())).thenReturn(Optional.of(user));
        UserWatchlist entry = UserWatchlist.builder()
                .user(user)
                .ticker("MISSING")
                .createdAt(LocalDateTime.now())
                .build();
        when(watchlistRepository.findByUserOrderByCreatedAtDesc(user)).thenReturn(List.of(entry));
        when(companyRepository.findAssetMetadata(anyCollection())).thenReturn(Map.of());

        assertThatThrownBy(() -> service.getMyWatchlist(user.getUuid().toString()))
                .isInstanceOf(AppException.class)
                .hasFieldOrPropertyWithValue("code", ErrorCode.NOT_FOUND);
    }

    private User createUser() {
        return User.builder()
                .id(1)
                .uuid(UUID.randomUUID())
                .email("user@example.com")
                .nickname("User")
                .status(UserStatus.ACTIVE)
                .build();
    }

    private void stubStockAsset(String ticker) {
        when(companyRepository.findAssetMetadata(ticker)).thenReturn(Optional.of(new AssetMetadata(ticker, AssetType.STOCK)));
        StockMasterRow row = mock(StockMasterRow.class);
        when(row.getName()).thenReturn("Name " + ticker);
        when(row.getNameEng()).thenReturn("NameEng " + ticker);
        when(row.getExchange()).thenReturn("NYSE");
        when(companyRepository.findStockMaster(ticker)).thenReturn(Optional.of(row));
    }
}
