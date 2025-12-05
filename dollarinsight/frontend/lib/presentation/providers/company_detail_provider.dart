import 'package:flutter/material.dart';
import '../../data/repositories/company_repository.dart';
import '../../data/models/company_detail_model.dart';
import '../../data/repositories/watchlist_repository.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/datasources/remote/watchlist_api.dart';
import 'package:intl/intl.dart';

/// 기업 상세 화면의 상태와 비즈니스 로직을 관리하는 Provider
class CompanyDetailProvider with ChangeNotifier {
  final String companyId;
  final CompanyRepository _companyRepository;
  final WatchlistRepository _watchlistRepository;

  CompanyDetailProvider({
    required this.companyId,
    CompanyRepository? companyRepository,
    WatchlistRepository? watchlistRepository,
  }) : _companyRepository = companyRepository ?? CompanyRepository(),
       _watchlistRepository = watchlistRepository ?? WatchlistRepository(WatchlistApi(ApiClient())) {
    _loadCompanyData();
  }

  // ============= 상태 변수들 =============

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isWatching = false;
  bool get isWatching => _isWatching;

  String? _companyName;
  String? get companyName => _companyName;

  String? _currentPrice;
  String? get currentPrice => _currentPrice;

  String? _currentPriceUsd;
  String? get currentPriceUsd => _currentPriceUsd;

  Map<String, String>? _indicators;
  Map<String, String>? get indicators => _indicators;

  Map<String, double>? _stockScores;
  Map<String, double>? get stockScores => _stockScores;

  // 주가예측 데이터 (1주, 1달)
  Map<String, double>? _weekPrediction;
  Map<String, double>? get weekPrediction => _weekPrediction;

  Map<String, double>? _monthPrediction;
  Map<String, double>? get monthPrediction => _monthPrediction;

  // 차트 데이터 (일봉, 주봉, 월봉)
  List<PriceDataPoint> _dailyPriceData = [];
  List<PriceDataPoint> get dailyPriceData => _dailyPriceData;

  List<PriceDataPoint> _weeklyPriceData = [];
  List<PriceDataPoint> get weeklyPriceData => _weeklyPriceData;

  List<PriceDataPoint> _monthlyPriceData = [];
  List<PriceDataPoint> get monthlyPriceData => _monthlyPriceData;

  List<Map<String, String>> _newsList = [];
  List<Map<String, String>> get newsList => _newsList;

  String? _error;
  String? get error => _error;

  // ============= 비즈니스 로직 =============

  /// 기업 데이터 로드 (API 연결 지점)
  Future<void> _loadCompanyData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // ============= 실제 API 호출 =============
      // 한 번의 API 호출로 모든 데이터를 가져옵니다
      final response = await _companyRepository.getCompanyDetail(companyId);

      // 응답 데이터를 각 상태 변수에 매핑
      _mapResponseToState(response);

      // 관심종목 상태 확인 (별도 API가 필요할 경우)
      await _checkWatchlistStatus();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = '데이터를 불러오는데 실패했습니다: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// API 응답을 Provider 상태로 매핑
  void _mapResponseToState(CompanyDetailResponse response) {
    // 기본 정보
    _companyName = response.basicInfo.name;

    // 가격 정보
    final priceFormatter = NumberFormat('#,###');
    _currentPrice = '${priceFormatter.format(response.priceOverview.latestCloseKrw)}원';
    _currentPriceUsd = '\$${response.priceOverview.latestCloseUsd.toStringAsFixed(2)}';

    // 투자지표 (STOCK 타입일 때)
    if (response.stockIndicators != null) {
      final marketCapInTrillions = response.stockIndicators!.marketCap / 1000000000000;
      _indicators = {
        '시가총액': '${marketCapInTrillions.toStringAsFixed(1)} 조원',
        '배당수익률': '${response.stockIndicators!.dividendYield.toStringAsFixed(2)}%',
        'PBR': response.stockIndicators!.pbr != null
            ? '${response.stockIndicators!.pbr!.toStringAsFixed(1)}배'
            : '–',
        'PER': response.stockIndicators!.per != null
            ? '${response.stockIndicators!.per!.toStringAsFixed(1)}배'
            : '–',
        'ROE': response.stockIndicators!.roe != null
            ? '${response.stockIndicators!.roe!.toStringAsFixed(1)}%'
            : '–',
        'PSR': response.stockIndicators!.psr != null
            ? '${response.stockIndicators!.psr!.toStringAsFixed(1)}배'
            : '–',
      };
    } else if (response.etfIndicators != null) {
      // ETF 지표
      final marketCapInTrillions = response.etfIndicators!.marketCap / 1000000000000;
      final totalAssetsInTrillions = response.etfIndicators!.totalAssets / 1000000000000;
      _indicators = {
        '시가총액': '${marketCapInTrillions.toStringAsFixed(1)} 조원',
        '배당수익률': '${response.etfIndicators!.dividendYield.toStringAsFixed(2)}%',
        '총자산': '${totalAssetsInTrillions.toStringAsFixed(1)} 조원',
        'NAV': '${response.etfIndicators!.nav.toStringAsFixed(2)}',
        '프리미엄': '${response.etfIndicators!.premiumDiscount.toStringAsFixed(2)}%',
        '운용비용': '${response.etfIndicators!.expenseRatio.toStringAsFixed(2)}%',
      };
    }

    // 주식 점수
    if (response.stockScores != null) {
      _stockScores = {
        '총점': response.stockScores!.totalScore,
        '모멘텀': response.stockScores!.momentum,
        '가치': response.stockScores!.valuation ?? -1, // null은 -1로 표시
        '성장': response.stockScores!.growth == 0 ? -1 : response.stockScores!.growth, // 0점은 -1로 표시
        '수급': response.stockScores!.flow,
        '위험': response.stockScores!.risk,
      };
    }

    // 주가 예측
    final oneWeek = response.predictions.oneWeek;
    final oneMonth = response.predictions.oneMonth;

    _weekPrediction = {
      '최저': oneWeek.lowerBound,
      '예상': oneWeek.probabilityUp,
      '최고': oneWeek.upperBound,
    };

    _monthPrediction = {
      '최저': oneMonth.lowerBound,
      '예상': oneMonth.probabilityUp,
      '최고': oneMonth.upperBound,
    };

    // 차트 데이터 (날짜 정렬 후 최신 30개)
    final dailyList = response.priceSeries.dailyRange.toList();
    dailyList.sort((a, b) => a.priceDate.compareTo(b.priceDate));
    _dailyPriceData = dailyList.length > 30
        ? dailyList.sublist(dailyList.length - 30)
        : dailyList;

    final weeklyList = response.priceSeries.weeklyRange.toList();
    weeklyList.sort((a, b) => a.priceDate.compareTo(b.priceDate));
    _weeklyPriceData = weeklyList.length > 30
        ? weeklyList.sublist(weeklyList.length - 30)
        : weeklyList;

    final monthlyList = response.priceSeries.monthlyRange.toList();
    monthlyList.sort((a, b) => a.priceDate.compareTo(b.priceDate));
    _monthlyPriceData = monthlyList.length > 30
        ? monthlyList.sublist(monthlyList.length - 30)
        : monthlyList;

    // 뉴스 (최대 5개)
    _newsList = response.latestNews.take(5).map((news) => {
      'id': news.id,
      'title': news.title,
      'url': news.url,
    }).toList();
  }


  /// 관심종목 상태 확인 API 호출
  Future<void> _checkWatchlistStatus() async {
    try {
      final status = await _watchlistRepository.isWatching(companyId);
      _isWatching = status;
    } catch (e) {
      _isWatching = false;
    }
  }

  /// 관심종목 추가/삭제 (API 연결)
  Future<void> toggleWatchlist() async {
    try {
      await _watchlistRepository.toggleWatchlist(companyId);
      _isWatching = !_isWatching;
      notifyListeners();
    } catch (e) {
      _error = '관심종목 설정에 실패했습니다: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// 에러 메시지 초기화
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
