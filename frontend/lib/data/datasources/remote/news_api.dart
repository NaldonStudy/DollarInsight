import 'api_client.dart';
import '../../models/news_model.dart';

/// 뉴스 API 클래스
class NewsApi {
  final ApiClient _apiClient;

  NewsApi({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

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
