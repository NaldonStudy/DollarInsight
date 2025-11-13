import 'api_client.dart';
import '../../models/company_model.dart';
import '../../models/company_detail_model.dart';

/// 기업 API 클라이언트
class CompanyApi {
  final ApiClient _apiClient;

  CompanyApi({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// 기업 정보 조회
  ///
  /// [companyId]: 기업 ID 또는 티커
  ///
  /// 반환: CompanyInfo 객체
  ///
  /// TODO: 실제 API 엔드포인트로 변경 필요
  /// 예시: GET /api/companies/{companyId}/info
  Future<CompanyInfo> getCompanyInfo(String companyId) async {
    try {
      // TODO: 실제 API 엔드포인트로 변경
      final response = await _apiClient.get(
        '/api/companies/$companyId/info',
      );

      return CompanyInfo.fromJson(response);
    } catch (e) {
      throw Exception('기업 정보 조회 실패: $e');
    }
  }

  /// 기업 상세 정보 조회
  ///
  /// [ticker]: 종목 티커 (예: NVDA)
  ///
  /// 반환: CompanyDetailResponse 객체
  ///
  /// API: GET /api/company-analysis/{ticker}
  /// Header: X-Device-Id
  /// 응답 구조: {ok: true, data: {...}}
  Future<CompanyDetailResponse> getCompanyDetail(String ticker) async {
    try {
      final response = await _apiClient.get(
        '/api/company-analysis/$ticker',
      );

      // API 응답이 {ok: true, data: {...}} 구조이므로 data 부분만 파싱
      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('API 응답에 data 필드가 없습니다.');
      }

      return CompanyDetailResponse.fromJson(data);
    } catch (e) {
      throw Exception('기업 상세 정보 조회 실패: $e');
    }
  }

  /// 기업 목록 조회 (검색)
  ///
  /// [query]: 검색어
  /// [limit]: 최대 결과 수 (기본: 10)
  ///
  /// 반환: CompanyInfo 리스트
  ///
  /// TODO: 실제 API 엔드포인트로 변경 필요
  /// 예시: GET /api/companies?query={query}&limit={limit}
  Future<List<CompanyInfo>> searchCompanies({
    required String query,
    int limit = 10,
  }) async {
    try {
      // TODO: 실제 API 엔드포인트로 변경
      final response = await _apiClient.get(
        '/api/companies',
        queryParameters: {
          'query': query,
          'limit': limit.toString(),
        },
      );

      // 응답 형식에 따라 처리
      if (response['data'] is List) {
        return (response['data'] as List)
            .map((json) => CompanyInfo.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      throw Exception('기업 검색 실패: $e');
    }
  }

  /// API 클라이언트 종료
  void dispose() {
    _apiClient.dispose();
  }
}
