import 'dart:async';
import 'dart:developer' as developer;

import '../datasources/remote/watchlist_api.dart';
import '../models/watchlist_model.dart';

/// 관심종목 Repository 예외 클래스들
abstract class WatchlistException implements Exception {
  final String message;
  const WatchlistException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends WatchlistException {
  const NetworkException(String message) : super(message);
}

class AuthenticationException extends WatchlistException {
  const AuthenticationException(String message) : super(message);
}

class DuplicateTickerException extends WatchlistException {
  const DuplicateTickerException(String message) : super(message);
}

class TickerNotFoundException extends WatchlistException {
  const TickerNotFoundException(String message) : super(message);
}

class ValidationException extends WatchlistException {
  const ValidationException(String message) : super(message);
}

class UnknownWatchlistException extends WatchlistException {
  const UnknownWatchlistException(String message) : super(message);
}

/// 관심종목 관리 Repository
///
/// 데이터 소스(API)를 추상화하고 비즈니스 로직을 처리합니다.
/// 캐싱, 에러 처리, 상태 관리를 담당합니다.
class WatchlistRepository {
  final WatchlistApi _api;

  // 메모리 캐시
  List<WatchlistItem>? _cachedWatchlist;
  DateTime? _lastFetchTime;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // 스트림 컨트롤러 (상태 변화 알림용)
  final StreamController<List<WatchlistItem>> _watchlistStreamController =
  StreamController<List<WatchlistItem>>.broadcast();

  final StreamController<WatchlistEvent> _eventStreamController =
  StreamController<WatchlistEvent>.broadcast();

  WatchlistRepository(this._api);

  /// 관심종목 목록 스트림
  Stream<List<WatchlistItem>> get watchlistStream => _watchlistStreamController.stream;

  /// 관심종목 이벤트 스트림 (추가/삭제 등)
  Stream<WatchlistEvent> get eventStream => _eventStreamController.stream;

  /// 캐시된 관심종목 목록 (즉시 반환, null 가능)
  List<WatchlistItem>? get cachedWatchlist => _cachedWatchlist;

  /// 관심종목 목록 조회
  ///
  /// [forceRefresh]: true면 캐시를 무시하고 서버에서 새로 가져옴
  /// [useCache]: false면 캐시를 사용하지 않음 (기본값: true)
  ///
  /// Returns: [List<WatchlistItem>] - 관심종목 목록
  /// Throws: [WatchlistException] - 비즈니스 에러
  Future<List<WatchlistItem>> getWatchlist({
    bool forceRefresh = false,
    bool useCache = true,
  }) async {
    try {
      // 캐시 확인 (조건: 캐시 사용 설정 + 강제 새로고침 아님 + 캐시 유효)
      if (useCache && !forceRefresh && _isCacheValid()) {
        developer.log('관심종목 캐시 사용', name: 'WatchlistRepository');
        return _cachedWatchlist!;
      }

      developer.log('관심종목 서버에서 조회 시작', name: 'WatchlistRepository');

      final watchlist = await _api.getWatchlist();

      // 캐시 업데이트
      _cachedWatchlist = watchlist;
      _lastFetchTime = DateTime.now();

      // 스트림에 새 데이터 전송
      _watchlistStreamController.add(watchlist);

      developer.log(
          '관심종목 조회 성공: ${watchlist.length}개',
          name: 'WatchlistRepository'
      );

      return watchlist;
    } catch (e) {
      developer.log('관심종목 조회 실패: $e', name: 'WatchlistRepository');
      throw _handleApiError(e, '관심종목 목록을 불러오는데 실패했습니다');
    }
  }

  /// 관심종목 추가
  ///
  /// [ticker]: 추가할 티커 심볼
  /// [checkDuplicate]: 중복 체크 여부 (기본값: true)
  ///
  /// Throws: [WatchlistException] - 비즈니스 에러
  Future<void> addToWatchlist(String ticker, {bool checkDuplicate = true}) async {
    // 입력값 검증
    _validateTicker(ticker);

    try {
      // 중복 체크 (옵션)
      if (checkDuplicate) {
        final isDuplicate = await _isDuplicateTicker(ticker);
        if (isDuplicate) {
          throw DuplicateTickerException('$ticker는 이미 관심종목에 등록되어 있습니다');
        }
      }

      developer.log('관심종목 추가 시작: $ticker', name: 'WatchlistRepository');

      await _api.addToWatchlist(ticker);

      // 캐시 무효화 및 새로 불러오기
      await _invalidateCacheAndRefresh();

      // 이벤트 발생
      _eventStreamController.add(
          WatchlistEvent.added(ticker: ticker, timestamp: DateTime.now())
      );

      developer.log('관심종목 추가 성공: $ticker', name: 'WatchlistRepository');

    } catch (e) {
      developer.log('관심종목 추가 실패: $ticker, $e', name: 'WatchlistRepository');
      throw _handleApiError(e, '$ticker 관심종목 추가에 실패했습니다');
    }
  }

  /// 관심종목 삭제
  ///
  /// [ticker]: 삭제할 티커 심볼
  ///
  /// Throws: [WatchlistException] - 비즈니스 에러
  Future<void> removeFromWatchlist(String ticker) async {
    _validateTicker(ticker);

    try {
      developer.log('관심종목 삭제 시작: $ticker', name: 'WatchlistRepository');

      await _api.removeFromWatchlist(ticker);

      // 캐시 무효화 및 새로 불러오기
      await _invalidateCacheAndRefresh();

      // 이벤트 발생
      _eventStreamController.add(
          WatchlistEvent.removed(ticker: ticker, timestamp: DateTime.now())
      );

      developer.log('관심종목 삭제 성공: $ticker', name: 'WatchlistRepository');

    } catch (e) {
      developer.log('관심종목 삭제 실패: $ticker, $e', name: 'WatchlistRepository');
      throw _handleApiError(e, '$ticker 관심종목 삭제에 실패했습니다');
    }
  }

  /// 관심종목 토글 (추가/삭제)
  ///
  /// [ticker]: 토글할 티커 심볼
  ///
  /// Returns: [bool] - true: 추가됨, false: 삭제됨
  /// Throws: [WatchlistException] - 비즈니스 에러
  Future<bool> toggleWatchlist(String ticker) async {
    _validateTicker(ticker);

    try {
      developer.log('관심종목 토글 시작: $ticker', name: 'WatchlistRepository');

      final isAdded = await _api.toggleWatchlist(ticker);

      // 캐시 무효화 및 새로 불러오기
      await _invalidateCacheAndRefresh();

      // 이벤트 발생
      if (isAdded) {
        _eventStreamController.add(
            WatchlistEvent.added(ticker: ticker, timestamp: DateTime.now())
        );
      } else {
        _eventStreamController.add(
            WatchlistEvent.removed(ticker: ticker, timestamp: DateTime.now())
        );
      }

      developer.log(
          '관심종목 토글 성공: $ticker (${isAdded ? "추가" : "삭제"})',
          name: 'WatchlistRepository'
      );

      return isAdded;
    } catch (e) {
      developer.log('관심종목 토글 실패: $ticker, $e', name: 'WatchlistRepository');
      throw _handleApiError(e, '$ticker 관심종목 토글에 실패했습니다');
    }
  }

  /// 관심종목 여부 확인
  ///
  /// [ticker]: 확인할 티커 심볼
  /// [useCache]: 캐시 사용 여부 (기본값: true)
  ///
  /// Returns: [bool] - 관심종목 여부
  /// Throws: [WatchlistException] - 비즈니스 에러
  Future<bool> isWatching(String ticker, {bool useCache = true}) async {
    _validateTicker(ticker);

    // 캐시에서 먼저 확인 (더 빠름)
    if (useCache && _cachedWatchlist != null) {
      final found = _cachedWatchlist!.any((item) =>
      item.ticker.toUpperCase() == ticker.toUpperCase()
      );
      if (found) return true;
    }

    // 서버에서 정확한 상태 확인
    try {
      final status = await _api.getWatchlistStatus(ticker);
      return status.watching;
    } catch (e) {
      developer.log('관심종목 여부 확인 실패: $ticker, $e', name: 'WatchlistRepository');
      throw _handleApiError(e, '$ticker 관심종목 여부 확인에 실패했습니다');
    }
  }

  /// 여러 종목의 관심종목 여부를 한번에 확인
  ///
  /// [tickers]: 확인할 티커 목록
  ///
  /// Returns: [Map<String, bool>] - 티커별 관심종목 여부
  /// Throws: [WatchlistException] - 비즈니스 에러
  Future<Map<String, bool>> getWatchlistStatuses(List<String> tickers) async {
    if (tickers.isEmpty) return {};

    // 입력값 검증
    for (final ticker in tickers) {
      _validateTicker(ticker);
    }

    try {
      developer.log(
          '관심종목 상태 일괄 조회 시작: ${tickers.length}개',
          name: 'WatchlistRepository'
      );

      final statuses = await _api.getWatchlistStatuses(tickers);

      developer.log(
          '관심종목 상태 일괄 조회 성공: ${statuses.length}개',
          name: 'WatchlistRepository'
      );

      return statuses;
    } catch (e) {
      developer.log('관심종목 상태 일괄 조회 실패: $e', name: 'WatchlistRepository');
      throw _handleApiError(e, '관심종목 상태 일괄 조회에 실패했습니다');
    }
  }

  /// 관심종목 통계 정보 생성
  ///
  /// Returns: [WatchlistSummary] - 통계 정보
  /// Throws: [WatchlistException] - 비즈니스 에러
  Future<WatchlistSummary> getWatchlistSummary() async {
    final watchlist = await getWatchlist();

    if (watchlist.isEmpty) {
      return WatchlistSummary.empty();
    }

    final priceItems = watchlist.where((item) =>
    item.lastPrice != null && item.changePct != null
    ).toList();

    final gainers = priceItems.where((item) => item.isPriceUp).toList();
    final losers = priceItems.where((item) => item.isPriceDown).toList();
    final unchanged = priceItems.where((item) => item.isPriceFlat).toList();

    // 최고 수익률과 최저 수익률 종목 찾기
    WatchlistItem? topGainer;
    WatchlistItem? topLoser;

    if (priceItems.isNotEmpty) {
      priceItems.sort((a, b) => (b.changePct ?? 0).compareTo(a.changePct ?? 0));
      topGainer = priceItems.first;
      topLoser = priceItems.last;
    }

    // 총 가치 계산 (USD)
    final totalValue = priceItems.fold<double>(
        0.0, (sum, item) => sum + (item.lastPrice ?? 0)
    );

    return WatchlistSummary(
      totalCount: watchlist.length,
      gainersCount: gainers.length,
      losersCount: losers.length,
      unchangedCount: unchanged.length,
      totalValueUSD: totalValue,
      topGainer: topGainer,
      topLoser: topLoser,
      averageChangePercent: priceItems.isEmpty
          ? 0.0
          : priceItems.fold<double>(0.0, (sum, item) => sum + (item.changePct ?? 0)) / priceItems.length,
      lastUpdated: DateTime.now(),
    );
  }

  /// 캐시 새로고침
  Future<List<WatchlistItem>> refreshWatchlist() async {
    return await getWatchlist(forceRefresh: true);
  }

  /// 캐시 클리어
  void clearCache() {
    _cachedWatchlist = null;
    _lastFetchTime = null;
    developer.log('관심종목 캐시 클리어', name: 'WatchlistRepository');
  }

  /// Repository 리소스 정리
  void dispose() {
    _watchlistStreamController.close();
    _eventStreamController.close();
    clearCache();
  }

  // === Private Methods ===

  /// 캐시가 유효한지 확인
  bool _isCacheValid() {
    return _cachedWatchlist != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheExpiry;
  }

  /// 중복 티커 확인
  Future<bool> _isDuplicateTicker(String ticker) async {
    if (_cachedWatchlist != null) {
      final found = _cachedWatchlist!.any((item) =>
      item.ticker.toUpperCase() == ticker.toUpperCase()
      );
      if (found) return true;
    }

    // 서버에서 정확한 상태 확인
    try {
      final status = await _api.getWatchlistStatus(ticker);
      return status.watching;
    } catch (e) {
      // 404 에러면 존재하지 않는 티커이므로 중복이 아님
      if (e.toString().contains('404')) {
        throw TickerNotFoundException('$ticker는 존재하지 않는 티커입니다');
      }
      rethrow;
    }
  }

  /// 캐시 무효화 및 새로고침
  Future<void> _invalidateCacheAndRefresh() async {
    clearCache();
    await getWatchlist(); // 새로 불러와서 캐시 갱신
  }

  /// 티커 유효성 검사
  void _validateTicker(String ticker) {
    if (ticker.trim().isEmpty) {
      throw ValidationException('티커가 입력되지 않았습니다');
    }

    if (ticker.trim().length > 16) {
      throw ValidationException('티커는 16자를 초과할 수 없습니다');
    }

    // 영문자와 숫자, 일부 특수문자만 허용
    final validPattern = RegExp(r'^[A-Za-z0-9.-]+$');
    if (!validPattern.hasMatch(ticker.trim())) {
      throw ValidationException('티커는 영문자, 숫자, 점(.), 하이픈(-)만 사용할 수 있습니다');
    }
  }

  /// API 에러를 사용자 친화적인 예외로 변환
  WatchlistException _handleApiError(dynamic error, String defaultMessage) {
    final errorMessage = error.toString().toLowerCase();

    if (errorMessage.contains('401') || errorMessage.contains('unauthorized')) {
      return const AuthenticationException('로그인이 필요합니다. 다시 로그인해 주세요');
    }

    if (errorMessage.contains('403') || errorMessage.contains('forbidden')) {
      return const AuthenticationException('접근 권한이 없습니다');
    }

    if (errorMessage.contains('404') || errorMessage.contains('not found')) {
      return TickerNotFoundException('요청하신 종목을 찾을 수 없습니다');
    }

    if (errorMessage.contains('409') || errorMessage.contains('conflict')) {
      return const DuplicateTickerException('이미 등록된 종목입니다');
    }

    if (errorMessage.contains('400') || errorMessage.contains('bad request')) {
      return ValidationException('잘못된 요청입니다. 입력값을 확인해 주세요');
    }

    if (errorMessage.contains('network') ||
        errorMessage.contains('connection') ||
        errorMessage.contains('timeout')) {
      return NetworkException('네트워크 연결을 확인해 주세요');
    }

    if (errorMessage.contains('500') || errorMessage.contains('internal')) {
      return NetworkException('서버에 일시적인 문제가 발생했습니다. 잠시 후 다시 시도해 주세요');
    }

    // 기본 에러 메시지
    return UnknownWatchlistException(defaultMessage);
  }
}

/// 관심종목 이벤트 클래스
class WatchlistEvent {
  final String type;
  final String ticker;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  const WatchlistEvent._({
    required this.type,
    required this.ticker,
    required this.timestamp,
    this.data = const {},
  });

  factory WatchlistEvent.added({
    required String ticker,
    required DateTime timestamp,
  }) {
    return WatchlistEvent._(
      type: 'added',
      ticker: ticker,
      timestamp: timestamp,
      data: {'action': 'add'},
    );
  }

  factory WatchlistEvent.removed({
    required String ticker,
    required DateTime timestamp,
  }) {
    return WatchlistEvent._(
      type: 'removed',
      ticker: ticker,
      timestamp: timestamp,
      data: {'action': 'remove'},
    );
  }

  @override
  String toString() {
    return 'WatchlistEvent{type: $type, ticker: $ticker, timestamp: $timestamp}';
  }
}

/// 관심종목 통계 정보
class WatchlistSummary {
  final int totalCount;
  final int gainersCount;
  final int losersCount;
  final int unchangedCount;
  final double totalValueUSD;
  final WatchlistItem? topGainer;
  final WatchlistItem? topLoser;
  final double averageChangePercent;
  final DateTime lastUpdated;

  const WatchlistSummary({
    required this.totalCount,
    required this.gainersCount,
    required this.losersCount,
    required this.unchangedCount,
    required this.totalValueUSD,
    this.topGainer,
    this.topLoser,
    required this.averageChangePercent,
    required this.lastUpdated,
  });

  factory WatchlistSummary.empty() {
    return WatchlistSummary(
      totalCount: 0,
      gainersCount: 0,
      losersCount: 0,
      unchangedCount: 0,
      totalValueUSD: 0.0,
      topGainer: null,
      topLoser: null,
      averageChangePercent: 0.0,
      lastUpdated: DateTime.now(),
    );
  }

  /// 수익률이 양수인 종목의 비율
  double get gainersRatio => totalCount > 0 ? gainersCount / totalCount : 0.0;

  /// 수익률이 음수인 종목의 비율
  double get losersRatio => totalCount > 0 ? losersCount / totalCount : 0.0;

  /// 변화가 없는 종목의 비율
  double get unchangedRatio => totalCount > 0 ? unchangedCount / totalCount : 0.0;

  /// 원화 환산 총 가치 (임시 환율 1300원 적용)
  double get totalValueKRW => totalValueUSD * 1300;

  /// 전체적인 시장 동향 ('bullish', 'bearish', 'neutral')
  String get marketTrend {
    if (gainersCount > losersCount) return 'bullish';
    if (losersCount > gainersCount) return 'bearish';
    return 'neutral';
  }

  @override
  String toString() {
    return 'WatchlistSummary{'
        'totalCount: $totalCount, '
        'gainers: $gainersCount, '
        'losers: $losersCount, '
        'totalValue: \$${totalValueUSD.toStringAsFixed(2)}'
        '}';
  }
}
