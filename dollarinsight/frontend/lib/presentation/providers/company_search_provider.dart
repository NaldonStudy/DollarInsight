import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/datasources/remote/company_api.dart';
import '../../data/models/search_result_model.dart';
import '../../data/datasources/remote/watchlist_api.dart';
import '../../data/datasources/remote/api_client.dart';

/// 기업 검색 화면의 상태와 비즈니스 로직을 관리하는 Provider
/// Debounce 기능으로 API 호출 최적화
class CompanySearchProvider with ChangeNotifier {
  final CompanyApi _companyApi;
  final WatchlistApi _watchlistApi;

  CompanySearchProvider({
    CompanyApi? companyApi,
    WatchlistApi? watchlistApi,
  })  : _companyApi = companyApi ?? CompanyApi(),
        _watchlistApi = watchlistApi ?? WatchlistApi(ApiClient());

  // ============= 상태 변수들 =============

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  String? _error;
  String? get error => _error;

  List<SearchResult> _searchResults = [];
  List<SearchResult> get searchResults => _searchResults;

  String _currentQuery = '';
  String get currentQuery => _currentQuery;

  Timer? _debounceTimer;

  // 관심종목 상태 (ticker -> watching)
  Map<String, bool> _watchlistStatuses = {};
  Map<String, bool> get watchlistStatuses => _watchlistStatuses;

  // ============= 비즈니스 로직 =============

  /// 검색어 입력 (Debounce 적용)
  void search(String query) {
    _currentQuery = query.trim();

    // 이전 타이머 취소
    _debounceTimer?.cancel();

    // 검색어가 비어있으면 결과 초기화
    if (_currentQuery.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      _error = null;
      notifyListeners();
      return;
    }

    // 로딩 시작
    _isSearching = true;
    _error = null;
    notifyListeners();

    // 300ms 후 실제 검색 실행
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(_currentQuery);
    });
  }

  /// 실제 검색 수행
  Future<void> _performSearch(String query) async {
    try {
      final response = await _companyApi.searchCompanies(query);

      // query가 변경되었으면 결과 무시 (최신 검색어만 반영)
      if (_currentQuery != query) return;

      _searchResults = response
          .map((item) => SearchResult.fromJson(item))
          .toList();

      // 검색 결과의 관심종목 상태 확인
      await _loadWatchlistStatuses();

      _isSearching = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      // query가 변경되었으면 에러 무시
      if (_currentQuery != query) return;

      _error = '검색 중 오류가 발생했습니다: $e';
      _isSearching = false;
      notifyListeners();
    }
  }

  /// 검색 결과의 관심종목 상태 확인
  Future<void> _loadWatchlistStatuses() async {
    if (_searchResults.isEmpty) return;

    try {
      final tickers = _searchResults.map((r) => r.ticker).toList();
      _watchlistStatuses = await _watchlistApi.getWatchlistStatuses(tickers);
    } catch (e) {
      if (kDebugMode) {
        print('[CompanySearchProvider] 관심종목 상태 로드 실패: $e');
      }
      // 에러 발생 시 빈 맵 유지 (검색은 정상 동작)
      _watchlistStatuses = {};
    }
  }

  /// 관심종목 토글
  Future<void> toggleWatchlist(String ticker) async {
    try {
      final isWatching = await _watchlistApi.toggleWatchlist(ticker);
      _watchlistStatuses[ticker] = isWatching;
      notifyListeners();
    } catch (e) {
      _error = '관심종목 변경 실패: $e';
      notifyListeners();
      // 에러를 다시 던져서 UI에서 스낵바를 표시할 수 있도록 함
      rethrow;
    }
  }

  /// 특정 티커의 관심종목 여부 확인
  bool isWatching(String ticker) {
    return _watchlistStatuses[ticker] ?? false;
  }

  /// 검색 결과 초기화
  void clearSearch() {
    _debounceTimer?.cancel();
    _currentQuery = '';
    _searchResults = [];
    _isSearching = false;
    _error = null;
    notifyListeners();
  }

  /// 에러 메시지 초기화
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _companyApi.dispose();
    super.dispose();
  }
}
