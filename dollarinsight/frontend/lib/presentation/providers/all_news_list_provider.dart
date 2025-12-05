import 'package:flutter/foundation.dart';
import '../../data/datasources/remote/news_api.dart';
import '../../data/models/news_model.dart';

/// 전체 뉴스 목록 화면의 상태와 비즈니스 로직을 관리하는 Provider
/// 페이지네이션을 지원하는 뉴스 목록 조회
class AllNewsListProvider with ChangeNotifier {
  final NewsApi _newsApi;

  AllNewsListProvider({NewsApi? newsApi})
      : _newsApi = newsApi ?? NewsApi() {
    loadNews();
  }

  // ============= 상태 변수들 =============

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  String? _error;
  String? get error => _error;

  List<NewsListItem> _newsList = [];
  List<NewsListItem> get newsList => _newsList;

  // 페이지네이션 관련
  int _currentPage = 0;
  int _totalElements = 0;
  int get totalElements => _totalElements;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  final int _pageSize = 10;

  // ============= 비즈니스 로직 =============

  /// 뉴스 목록 초기 로드
  Future<void> loadNews() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    _currentPage = 0;
    _newsList.clear();
    notifyListeners();

    try {
      final response = await _newsApi.getNewsList(
        page: _currentPage,
        size: _pageSize,
      );

      _totalElements = response['totalElements'] as int;
      final items = response['items'] as List<dynamic>;

      _newsList = items
          .map((item) => NewsListItem.fromJson(item as Map<String, dynamic>))
          .toList();

      _hasMore = _newsList.length < _totalElements;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = '뉴스 목록을 불러오는데 실패했습니다: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 다음 페이지 로드 (무한 스크롤)
  Future<void> loadMoreNews() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;

      final response = await _newsApi.getNewsList(
        page: _currentPage,
        size: _pageSize,
      );

      final items = response['items'] as List<dynamic>;
      final newItems = items
          .map((item) => NewsListItem.fromJson(item as Map<String, dynamic>))
          .toList();

      _newsList.addAll(newItems);
      _hasMore = _newsList.length < _totalElements;

      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('[AllNewsListProvider] 추가 뉴스 로드 실패: $e');
      }
      _currentPage--; // 실패 시 페이지 번호 되돌림
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// 새로고침
  Future<void> refresh() async {
    await loadNews();
  }

  /// 에러 메시지 초기화
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _newsApi.dispose();
    super.dispose();
  }
}
