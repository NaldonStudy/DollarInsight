import 'package:flutter/material.dart';

/// ETF 상세 화면의 상태와 비즈니스 로직을 관리하는 Provider
class ETFDetailProvider with ChangeNotifier {
  final String etfId;

  ETFDetailProvider({required this.etfId}) {
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

  String? _logoUrl;
  String? get logoUrl => _logoUrl;

  // ETF 투자지표 (시가총액, 배당수익률, 운용자산, 순자산가치, 괴리율, 운용보수)
  Map<String, String>? _etfIndicators;
  Map<String, String>? get etfIndicators => _etfIndicators;

  // 주가예측 데이터 (1주, 1달)
  Map<String, double>? _weekPrediction;
  Map<String, double>? get weekPrediction => _weekPrediction;

  Map<String, double>? _monthPrediction;
  Map<String, double>? get monthPrediction => _monthPrediction;

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
      // ============= API 연결 지점 =============
      // 1. ETF 기본 정보 API 호출
      await _fetchETFInfo();

      // 2. ETF 투자지표 API 호출
      await _fetchETFIndicators();

      // 3. 주가예측 API 호출
      await _fetchPredictions();

      // 4. ETF 뉴스 API 호출 (최대 5개)
      await _fetchETFNews();

      // 5. 관심종목 상태 확인
      await _checkWatchlistStatus();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = '데이터를 불러오는데 실패했습니다: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ETF 기본 정보 API 호출
  Future<void> _fetchETFInfo() async {
    // TODO: API 연결
    // final response = await etfRepository.getETFInfo(etfId);
    // _etfName = response.name;
    // _currentPrice = response.currentPrice;
    // _currentPriceUsd = response.currentPriceUsd;
    // _logoUrl = response.logoUrl;

    // 임시 더미 데이터 (API 연결 후 삭제)
    await Future.delayed(const Duration(milliseconds: 300));
    _etfName = 'TIGER 미국S&P500';
    _currentPrice = '15,320원';
    _currentPriceUsd = '\$10.68';
    _logoUrl = null;
  }

  /// ETF 투자지표 API 호출
  Future<void> _fetchETFIndicators() async {
    // TODO: API 연결
    // final response = await etfRepository.getETFIndicators(etfId);
    // _etfIndicators = response.indicators;

    // 임시 더미 데이터 (API 연결 후 삭제)
    await Future.delayed(const Duration(milliseconds: 300));
    _etfIndicators = {
      '시가총액': '3조 2000억원',
      '배당수익률': '1.5%',
      '운용자산': '3조 1500억원',
      '순자산가치': '15,310원',
      '괴리율': '0.07%',
      '운용보수(연)': '0.07%',
    };
  }

  /// 주가예측 API 호출
  Future<void> _fetchPredictions() async {
    // TODO: API 연결
    // final response = await etfRepository.getPredictions(etfId);
    // _weekPrediction = {
    //   '최저': response.weekLow.toDouble(),
    //   '예측': response.weekExpected.toDouble(),
    //   '최고': response.weekHigh.toDouble(),
    // };
    // _monthPrediction = {
    //   '최저': response.monthLow.toDouble(),
    //   '예측': response.monthExpected.toDouble(),
    //   '최고': response.monthHigh.toDouble(),
    // };

    // 임시 더미 데이터 (API 연결 후 삭제)
    await Future.delayed(const Duration(milliseconds: 300));
    _weekPrediction = {
      '최저': 1.5, // %
      '예상': 2.5, // %
      '최고': 3.5, // %
    };
    _monthPrediction = {
      '최저': 2.0, // %
      '예상': 4.0, // %
      '최고': 5.5, // %
    };
  }

  /// ETF 뉴스 API 호출 (최대 5개)
  Future<void> _fetchETFNews() async {
    // TODO: API 연결
    // final response = await newsRepository.getETFNews(
    //   etfId: etfId,
    //   limit: 5,
    // );
    // _newsList = response.newsList.map((news) => {
    //   'id': news.id,
    //   'title': news.title,
    //   'url': news.url,
    // }).toList();

    // 임시 더미 데이터 (API 연결 후 삭제)
    await Future.delayed(const Duration(milliseconds: 300));
    _newsList = [
      {
        'id': '1',
        'title': 'S&P500 지수, 신기록 경신...미국 증시 강세 지속',
        'url': 'https://example.com/news/1'
      },
      {
        'id': '2',
        'title': 'TIGER 미국S&P500, 순자산 3조원 돌파',
        'url': 'https://example.com/news/2'
      },
      {
        'id': '3',
        'title': '해외 ETF 투자자 급증...S&P500 ETF 인기',
        'url': 'https://example.com/news/3'
      },
      {
        'id': '4',
        'title': '미국 증시 전망, 금리 인하 기대감에 상승세',
        'url': 'https://example.com/news/4'
      },
      {
        'id': '5',
        'title': 'ETF 시장 규모 10조원 돌파...S&P500 ETF가 주도',
        'url': 'https://example.com/news/5'
      },
    ];
  }

  /// 관심종목 상태 확인 API 호출
  Future<void> _checkWatchlistStatus() async {
    // TODO: API 연결
    // final response = await userRepository.checkWatchlist(etfId);
    // _isWatching = response.isWatching;

    // 임시 더미 데이터 (API 연결 후 삭제)
    await Future.delayed(const Duration(milliseconds: 300));
    _isWatching = false;
  }

  /// 데이터 새로고침
  Future<void> refresh() async {
    await _loadETFData();
  }

  /// 관심종목 추가/삭제 (API 연결 지점)
  Future<void> toggleWatchlist() async {
    try {
      // TODO: 백엔드 API 연결
      // if (_isWatching) {
      //   await userRepository.removeFromWatchlist(etfId);
      // } else {
      //   await userRepository.addToWatchlist(etfId);
      // }

      _isWatching = !_isWatching;
      notifyListeners();
    } catch (e) {
      _error = '관심종목 설정에 실패했습니다: $e';
      notifyListeners();
      rethrow; // UI에서 에러 처리를 위해 다시 throw
    }
  }

  /// 에러 메시지 초기화
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
