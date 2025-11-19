import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/datasources/remote/news_api.dart';
import '../../data/models/news_model.dart';
import '../../core/utils/date_formatter.dart';

/// 기업별 뉴스 상세 화면의 상태와 비즈니스 로직을 관리하는 Provider
/// API 연결을 통해 뉴스 상세 데이터, AI 댓글 등을 불러옴
class CompanyNewsDetailProvider with ChangeNotifier {
  final NewsApi _newsApi;
  final String companyId;
  final String newsId;

  CompanyNewsDetailProvider({
    required this.companyId,
    required this.newsId,
    NewsApi? newsApi,
  }) : _newsApi = newsApi ?? NewsApi() {
    _loadNewsDetail();
  }

  // ============= 상태 변수들 =============

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // 뉴스 상세 데이터
  String? _title;
  String? get title => _title;

  String? _content;
  String? get content => _content;

  String? _summary;
  String? get summary => _summary;

  String? _publishedAt;
  String? get publishedAt => _publishedAt;

  String? _source;
  String? get source => _source;

  String? _url;
  String? get url => _url;

  String? _companyName;
  String? get companyName => _companyName;

  // AI 댓글 데이터
  List<Map<String, String>> _aiComments = [];
  List<Map<String, String>> get aiComments => _aiComments;

  // ============= 비즈니스 로직 =============

  /// 뉴스 상세 데이터 로드 (API 연결)
  Future<void> _loadNewsDetail() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // API 호출
      final newsDetail = await _newsApi.getCompanyNewsDetail(newsId);

      // 데이터 매핑
      _title = newsDetail.title;
      _content = newsDetail.content;
      _summary = newsDetail.summary;
      _publishedAt = DateFormatter.formatToKorean(newsDetail.publishedAt);
      _url = newsDetail.url;
      _companyName = newsDetail.ticker; // ticker를 회사명으로 사용

      // AI 댓글 매핑 (페르소나 이미지 경로는 personaCode로 매핑)
      _aiComments = newsDetail.personaComments.map((comment) {
        return {
          'text': comment.comment,
          'imagePath': _getPersonaImagePath(comment.personaCode),
        };
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = '뉴스 상세 정보를 불러오는데 실패했습니다: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 페르소나 코드에서 이미지 경로 매핑
  ///
  /// 백엔드 API의 personaCode와 매칭되는 이미지 경로 반환
  String _getPersonaImagePath(String personaCode) {
    // 대소문자 구분 없이 매칭
    final code = personaCode.toLowerCase().trim();

    switch (code) {
      case 'heuyeol':
        return 'assets/images/heuyeol.webp';
      case 'jiyul':
        return 'assets/images/jiyul.webp';
      case 'teo':
        return 'assets/images/teo.webp';
      case 'minji':
        return 'assets/images/minji.webp';
      case 'deoksu':
        return 'assets/images/deoksu.webp';
      default:
        // 매칭되지 않는 경우 디버그 로그 출력 및 기본 이미지 반환
        if (kDebugMode) {
          print('[CompanyNewsDetailProvider] 알 수 없는 personaCode: $personaCode');
        }
        return 'assets/images/heuyeol.webp'; // 기본 이미지
    }
  }

  /// 데이터 새로고침 (API 연결 지점)
  Future<void> refresh() async {
    await _loadNewsDetail();
  }

  /// 에러 메시지 초기화
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
