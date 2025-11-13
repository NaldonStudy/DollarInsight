import 'api_client.dart';
import '../../models/news_model.dart';

/// 뉴스 API 클래스
class NewsApi {
  final ApiClient _apiClient;

  NewsApi({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// 뉴스 목록 조회 (ticker 없이 전체 뉴스)
  ///
  /// [page]: 페이지 번호 (0부터 시작)
  /// [size]: 페이지 크기
  ///
  /// 반환: 뉴스 목록 응답
  ///
  /// API 엔드포인트: GET /api/company-analysis/news
  Future<Map<String, dynamic>> getNewsList({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/company-analysis/news',
        queryParameters: {
          'page': page,
          'size': size,
        },
      );

      // API 응답이 { ok, data, timestamp } 구조로 래핑되어 있음
      return response['data'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('뉴스 목록 조회 실패: $e');
    }
  }

  /// 기업 뉴스 상세 조회
  ///
  /// [newsId]: 뉴스 ID
  ///
  /// 반환: NewsDetail 객체
  ///
  /// API 엔드포인트: GET /api/company-analysis/news/{newsId}
  Future<NewsDetail> getCompanyNewsDetail(String newsId) async {
    try {
      final response = await _apiClient.get(
        '/api/company-analysis/news/$newsId',
      );

      // API 응답이 { ok, data, timestamp } 구조로 래핑되어 있음
      final data = response['data'] as Map<String, dynamic>;
      return NewsDetail.fromJson(data);
    } catch (e) {
      throw Exception('뉴스 상세 조회 실패: $e');
    }
  }

  /// API 클라이언트 종료
  void dispose() {
    _apiClient.dispose();
  }
}
