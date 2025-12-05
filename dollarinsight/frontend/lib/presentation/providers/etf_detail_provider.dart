import 'package:flutter/material.dart';
import '../../data/repositories/company_repository.dart';
import '../../data/repositories/watchlist_repository.dart';
import '../../data/models/company_detail_model.dart';
import '../../data/datasources/remote/watchlist_api.dart';
import '../../data/datasources/remote/api_client.dart';
import 'package:intl/intl.dart';

/// ETF 상세 화면의 상태와 비즈니스 로직을 관리하는 Provider
/// Company API를 재사용 (백엔드에서 ticker 기반으로 STOCK/ETF 구분)
class ETFDetailProvider with ChangeNotifier {
  final String etfId;
  final CompanyRepository _companyRepository;
  final WatchlistRepository _watchlistRepository;

  ETFDetailProvider({
    required this.etfId,
    CompanyRepository? companyRepository,
    WatchlistRepository? watchlistRepository,
  }) : _companyRepository = companyRepository ?? CompanyRepository(),
       _watchlistRepository = watchlistRepository ?? WatchlistRepository(WatchlistApi(ApiClient())) {
    _loadETFData();
  }

  // ============= 상태 변수들 =============

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isWatching = false;
  bool get isWatching => _isWatching;

  String? _etfName;
  String? get etfName => _etfName;

  String? _currentPrice;
  String? get currentPrice => _currentPrice;

  String? _currentPriceUsd;
  String? get currentPriceUsd => _currentPriceUsd;

  // ETF 투자지표 (시가총액, 배당수익률, 운용자산, 순자산가치, 괴리율, 운용보수)
  Map<String, String>? _etfIndicators;
  Map<String, String>? get etfIndicators => _etfIndicators;

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

  /// ETF 데이터 로드 (API 연결 지점)
  Future<void> _loadETFData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // ============= 실제 API 호출 =============
      // Company API를 재사용 (백엔드에서 assetType으로 ETF 구분)
      final response = await _companyRepository.getCompanyDetail(etfId);

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
    _etfName = response.basicInfo.name;

    // 가격 정보
    final priceFormatter = NumberFormat('#,###');
    _currentPrice = '${priceFormatter.format(response.priceOverview.latestCloseKrw)}원';
    _currentPriceUsd = '\$${response.priceOverview.latestCloseUsd.toStringAsFixed(2)}';

    // ETF 투자지표
    if (response.etfIndicators != null) {
      final marketCapInTrillions = response.etfIndicators!.marketCap / 1000000000000;
      final totalAssetsInTrillions = response.etfIndicators!.totalAssets / 1000000000000;
      _etfIndicators = {
        '시가총액': '${marketCapInTrillions.toStringAsFixed(1)} 조 달러',
        '배당수익률': '${response.etfIndicators!.dividendYield.toStringAsFixed(2)}%',
        '운용자산': '${totalAssetsInTrillions.toStringAsFixed(1)} 조 달러',
        '순자산가치': '${response.etfIndicators!.nav.toStringAsFixed(2)}원',
        '괴리율': '${response.etfIndicators!.premiumDiscount.toStringAsFixed(2)}%',
        '운용보수(연)': '${response.etfIndicators!.expenseRatio.toStringAsFixed(2)}%',
      };
    }

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
      final status = await _watchlistRepository.isWatching(etfId);
      _isWatching = status;
    } catch (e) {
      _isWatching = false;
    }
  }

  /// 데이터 새로고침
  Future<void> refresh() async {
    await _loadETFData();
  }

  /// 관심종목 추가/삭제 (API 연결)
  Future<void> toggleWatchlist() async {
    try {
      await _watchlistRepository.toggleWatchlist(etfId);
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
