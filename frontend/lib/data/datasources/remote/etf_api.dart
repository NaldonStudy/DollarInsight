import 'api_client.dart';
import '../../models/etf_model.dart';

/// ETF 정보 API 클래스
class EtfApi {
  final ApiClient _apiClient;

  EtfApi({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// ETF 정보 조회
  ///
  /// [etfId]: ETF ID 또는 코드 (예: QQQ)
  ///
  /// 반환: EtfInfo 객체
  ///
  /// TODO: 실제 API 엔드포인트로 변경 필요
  /// 예시: GET /api/etf/{etfId}/info
  Future<EtfInfo> getEtfInfo(String etfId) async {
    try {
      // TODO: 실제 API 엔드포인트로 변경
      final response = await _apiClient.get(
        '/api/etf/$etfId/info',
      );

      return EtfInfo.fromJson(response);
    } catch (e) {
      throw Exception('ETF 정보 조회 실패: $e');
    }
  }

  /// ETF 목록 조회 (검색)
  ///
  /// [query]: 검색어
  /// [limit]: 결과 개수 제한 (기본값: 10)
  ///
  /// 반환: EtfInfo 리스트
  ///
  /// TODO: 실제 API 엔드포인트로 변경 필요
  /// 예시: GET /api/etf?query={query}&limit={limit}
  Future<List<EtfInfo>> searchEtfs({
    required String query,
    int limit = 10,
  }) async {
    try {
      // TODO: 실제 API 엔드포인트로 변경
      final response = await _apiClient.get(
        '/api/etf',
        queryParameters: {
          'query': query,
          'limit': limit.toString(),
        },
      );

      // 응답이 리스트 형태인 경우
      if (response['data'] is List) {
        return (response['data'] as List)
            .map((json) => EtfInfo.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      throw Exception('ETF 검색 실패: $e');
    }
  }

  /// API 클라이언트 종료
  void dispose() {
    _apiClient.dispose();
  }
}
