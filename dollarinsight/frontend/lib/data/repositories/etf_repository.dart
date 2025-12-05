import '../datasources/remote/etf_api.dart';
import '../models/etf_model.dart';

/// ETF 정보 Repository
/// API 계층과 비즈니스 로직 계층 사이의 중간 계층
class EtfRepository {
  final EtfApi _etfApi;

  EtfRepository({EtfApi? etfApi})
      : _etfApi = etfApi ?? EtfApi();

  /// ETF 정보 조회
  Future<EtfInfo> getEtfInfo(String etfId) async {
    try {
      return await _etfApi.getEtfInfo(etfId);
    } catch (e) {
      // 에러 로깅 또는 추가 처리
      rethrow;
    }
  }

  /// ETF 검색
  Future<List<EtfInfo>> searchEtfs({
    required String query,
    int limit = 10,
  }) async {
    try {
      return await _etfApi.searchEtfs(
        query: query,
        limit: limit,
      );
    } catch (e) {
      // 에러 로깅 또는 추가 처리
      rethrow;
    }
  }

  /// Repository 종료
  void dispose() {
    _etfApi.dispose();
  }
}
