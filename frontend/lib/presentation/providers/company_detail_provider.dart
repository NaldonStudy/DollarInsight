import 'package:flutter/material.dart';

/// 기업 상세 화면의 상태와 비즈니스 로직을 관리하는 Provider
class CompanyDetailProvider with ChangeNotifier {
  final String companyId;

  CompanyDetailProvider({required this.companyId}) {
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

  String? _logoUrl;
  String? get logoUrl => _logoUrl;

  Map<String, String>? _indicators;
  Map<String, String>? get indicators => _indicators;

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
      // ============= API 연결 지점 =============
      // 1. 기업 기본 정보 API 호출
      await _fetchCompanyInfo();

      // 2. 투자지표 API 호출
      await _fetchIndicators();

      // 3. 기업 뉴스 API 호출 (최대 5개)
      await _fetchCompanyNews();

      // 4. 관심종목 상태 확인
      await _checkWatchlistStatus();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = '데이터를 불러오는데 실패했습니다: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 기업 기본 정보 API 호출
  Future<void> _fetchCompanyInfo() async {
    // TODO: API 연결
    // final response = await companyRepository.getCompanyInfo(companyId);
    // _companyName = response.name;
    // _currentPrice = response.currentPrice;
    // _currentPriceUsd = response.currentPriceUsd;
    // _logoUrl = response.logoUrl;

    // 임시 더미 데이터 (API 연결 후 삭제)
    await Future.delayed(const Duration(milliseconds: 300));
    _companyName = '엔비디아';
    _currentPrice = '293,027원';
    _currentPriceUsd = '\$204.32';
    _logoUrl = null;
  }

  /// 투자지표 API 호출
  Future<void> _fetchIndicators() async {
    // TODO: API 연결
    // final response = await companyRepository.getIndicators(companyId);
    // _indicators = response.indicators;

    // 임시 더미 데이터 (API 연결 후 삭제)
    await Future.delayed(const Duration(milliseconds: 300));
    _indicators = {
      '시가총액': '7000억원',
      '배당수익률': '0.02%',
      'PBR': '48.8배',
      'PER': '56.4배',
      'ROE': '109.4%',
      'PSR': '29.6배',
    };
  }

  /// 기업 뉴스 API 호출 (최대 5개)
  Future<void> _fetchCompanyNews() async {
    // TODO: API 연결
    // final response = await newsRepository.getCompanyNews(
    //   companyId: companyId,
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
        'title': '[GAM]스텔란티스-엔비디아-우버-폭스콘, 로보택시 공동 개발',
        'url': 'https://example.com/news/1'
      },
      {
        'id': '2',
        'title': '투자자들, 연준·기술주 실적에 대비하면서 AI 낙관론에 주가 상승',
        'url': 'https://example.com/news/2'
      },
      {
        'id': '3',
        'title': '트럼프, 엔비디아 \'슈퍼-듀퍼\' 블랙웰 칩에 中 시진핑과 논의할 수도',
        'url': 'https://example.com/news/3'
      },
      {
        'id': '4',
        'title': '엔비디아, 美 에너지부에 AI 슈퍼컴 7대 구축… 6G 인프라 구축도 추진',
        'url': 'https://example.com/news/4'
      },
      {
        'id': '5',
        'title': '[오늘의 뉴욕증시 무버] 노키아, 엔비디아 10억 달러 투자 소식에 22.85%↑',
        'url': 'https://example.com/news/5'
      },
    ];
  }

  /// 관심종목 상태 확인 API 호출
  Future<void> _checkWatchlistStatus() async {
    // TODO: API 연결
    // final response = await userRepository.checkWatchlist(companyId);
    // _isWatching = response.isWatching;

    // 임시 더미 데이터 (API 연결 후 삭제)
    await Future.delayed(const Duration(milliseconds: 300));
    _isWatching = false;
  }

  /// 데이터 새로고침
  Future<void> refresh() async {
    await _loadCompanyData();
  }

  /// 관심종목 추가/삭제 (API 연결 지점)
  Future<void> toggleWatchlist() async {
    try {
      // TODO: 백엔드 API 연결
      // if (_isWatching) {
      //   await userRepository.removeFromWatchlist(companyId);
      // } else {
      //   await userRepository.addToWatchlist(companyId);
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
