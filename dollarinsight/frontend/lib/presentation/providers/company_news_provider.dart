import 'package:flutter/material.dart';
import '../../data/datasources/remote/company_api.dart';

/// 기업별 뉴스 리스트 화면의 상태와 비즈니스 로직을 관리하는 Provider
/// 무한 스크롤, 새로고침, 페이지네이션 지원
class CompanyNewsProvider with ChangeNotifier {
  final String companyId;
  final CompanyApi _companyApi;

  CompanyNewsProvider({
    required this.companyId,
    CompanyApi? companyApi,
  }) : _companyApi = companyApi ?? CompanyApi() {
    _loadInitialNews();
  }

  // ============= 상태 변수들 =============

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false; // 무한 스크롤 로딩
  bool get isLoadingMore => _isLoadingMore;

  bool _hasMore = true; // 더 불러올 뉴스가 있는지
  bool get hasMore => _hasMore;

  List<Map<String, String>> _newsList = [];
  List<Map<String, String>> get newsList => _newsList;

  String? _companyName;
  String? get companyName => _companyName;

  String? _error;
  String? get error => _error;

  int _currentPage = 0; // API는 0부터 시작
  final int _pageSize = 20; // 한 번에 불러올 뉴스 개수
  int _totalElements = 0;

  // ============= 비즈니스 로직 =============

  /// 초기 뉴스 데이터 로드 (API 연결 지점)
  Future<void> _loadInitialNews() async {
    _isLoading = true;
    _error = null;
    _currentPage = 0;
    notifyListeners();

    try {
      // ✅ 백엔드 API 연결
      final response = await _companyApi.getNewsList(
        ticker: companyId,
        page: _currentPage,
        size: _pageSize,
      );

      // 응답 파싱
      final items = response['items'] as List<dynamic>? ?? [];
      _totalElements = response['totalElements'] as int? ?? 0;

      // 뉴스 리스트 변환
      _newsList = items.map((item) {
        return {
          'id': item['id']?.toString() ?? '',
          'ticker': item['ticker']?.toString() ?? '',
          'title': item['title']?.toString() ?? '',
          'summary': item['summary']?.toString() ?? '',
          'url': item['url']?.toString() ?? '',
          'publishedAt': item['publishedAt']?.toString() ?? '',
        };
      }).toList();

      // 더 불러올 뉴스가 있는지 확인
      _hasMore = _newsList.length < _totalElements;

      // 기업명 설정 (ticker를 기업명으로 임시 사용, 필요시 별도 API 호출)
      _companyName = companyId;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = '뉴스를 불러오는데 실패했습니다: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 추가 뉴스 로드 (무한 스크롤용, API 연결 지점)
  Future<void> loadMoreNews() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;

      // ✅ 백엔드 API 연결
      final response = await _companyApi.getNewsList(
        ticker: companyId,
        page: _currentPage,
        size: _pageSize,
      );

      // 응답 파싱
      final items = response['items'] as List<dynamic>? ?? [];
      _totalElements = response['totalElements'] as int? ?? 0;

      // 추가 뉴스 리스트 변환
      final moreNews = items.map((item) {
        return {
          'id': item['id']?.toString() ?? '',
          'ticker': item['ticker']?.toString() ?? '',
          'title': item['title']?.toString() ?? '',
          'summary': item['summary']?.toString() ?? '',
          'url': item['url']?.toString() ?? '',
          'publishedAt': item['publishedAt']?.toString() ?? '',
        };
      }).toList();

      _newsList.addAll(moreNews);

      // 더 불러올 뉴스가 있는지 확인
      _hasMore = _newsList.length < _totalElements;

      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _error = '추가 뉴스를 불러오는데 실패했습니다: $e';
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// 데이터 새로고침 (API 연결 지점)
  Future<void> refresh() async {
    await _loadInitialNews();
  }

  /// 에러 메시지 초기화
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Provider 종료
  @override
  void dispose() {
    _companyApi.dispose();
    super.dispose();
  }
}
