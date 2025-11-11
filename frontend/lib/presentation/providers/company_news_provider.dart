import 'package:flutter/material.dart';

/// 기업별 뉴스 리스트 화면의 상태와 비즈니스 로직을 관리하는 Provider
/// 무한 스크롤, 새로고침, 페이지네이션 지원
class CompanyNewsProvider with ChangeNotifier {
  final String companyId;

  CompanyNewsProvider({required this.companyId}) {
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

  int _currentPage = 1;
  final int _pageSize = 15; // 한 번에 불러올 뉴스 개수

  // ============= 비즈니스 로직 =============

  /// 초기 뉴스 데이터 로드 (API 연결 지점)
  Future<void> _loadInitialNews() async {
    _isLoading = true;
    _error = null;
    _currentPage = 1;
    notifyListeners();

    try {
      // TODO: 백엔드 API 연결
      // final response = await newsRepository.getCompanyNews(
      //   companyId: companyId,
      //   page: _currentPage,
      //   pageSize: _pageSize,
      // );
      //
      // _companyName = response.companyName;
      // _newsList = response.newsList;
      // _hasMore = response.hasMore;

      // 임시 더미 데이터 (API 연결 후 삭제)
      await Future.delayed(const Duration(seconds: 1));

      _companyName = '엔비디아';
      _newsList = List.generate(
        _pageSize,
        (i) => {
          'id': '${i + 1}',
          'title': _getDummyTitle(i),
          'summary': '뉴스 요약 내용입니다. AI가 자동으로 요약한 내용이 여기에 표시됩니다.',
          'url': 'https://example.com/news/${i + 1}',
          'publishedAt': '2025-01-${(i % 30) + 1}',
          'source': '뉴스 출처 ${i % 3 + 1}',
        },
      );
      _hasMore = true;

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

      // TODO: 백엔드 API 연결
      // final response = await newsRepository.getCompanyNews(
      //   companyId: companyId,
      //   page: _currentPage,
      //   pageSize: _pageSize,
      // );
      //
      // _newsList.addAll(response.newsList);
      // _hasMore = response.hasMore;

      // 임시 더미 데이터 (API 연결 후 삭제)
      await Future.delayed(const Duration(milliseconds: 800));

      final moreNews = List.generate(
        10,
        (i) => {
          'id': '${_newsList.length + i + 1}',
          'title': '추가 기업 뉴스 ${_newsList.length + i + 1}',
          'summary': '추가 뉴스 요약 내용입니다.',
          'url': 'https://example.com/news/${_newsList.length + i + 1}',
          'publishedAt': '2025-01-${(_newsList.length + i) % 30 + 1}',
          'source': '뉴스 출처 ${(_newsList.length + i) % 3 + 1}',
        },
      );

      _newsList.addAll(moreNews);

      // 더미에서는 최대 50개까지만
      if (_newsList.length >= 50) {
        _hasMore = false;
      }

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

  // ============= Helper 메서드 =============

  String _getDummyTitle(int index) {
    final titles = [
      '[GAM]스텔란티스-엔비디아-우버-폭스콘, 로보택시 공동 개발',
      '투자자들, 연준·기술주 실적에 대비하면서 AI 낙관론에 주가 상승',
      '트럼프, 엔비디아 \'슈퍼-듀퍼\' 블랙웰 칩에 中 시진핑과 논의할 수도',
      '엔비디아, 美 에너지부에 AI 슈퍼컴 7대 구축… 6G 인프라 구축도 추진',
      '[오늘의 뉴욕증시 무버] 노키아, 엔비디아 10억 달러 투자 소식에 22.85%↑',
      '엔비디아 CEO 젠슨 황, CES 2025 기조연설 확정',
      '엔비디아, 새로운 AI 칩 발표 임박... 주가 상승 기대감',
      'AI 시장 성장세 속 엔비디아 실적 전망 밝아',
      '엔비디아, 클라우드 기업들과 대규모 계약 체결',
      '반도체 업계 1위 엔비디아, 경쟁사 AMD 제치고 독주',
      '엔비디아 GPU 수요 폭증, 공급 부족 우려',
      '데이터센터 시장 확대로 엔비디아 수혜 전망',
      '엔비디아 주가, 사상 최고치 경신',
      'AI 혁명의 선두주자 엔비디아, 미래 전망은?',
      '엔비디아 CFO, 실적 발표 앞두고 낙관적 전망',
    ];
    return titles[index % titles.length];
  }
}
