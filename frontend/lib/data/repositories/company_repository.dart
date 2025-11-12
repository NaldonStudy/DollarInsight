import '../datasources/remote/company_api.dart';
import '../models/company_model.dart';

/// 기업 Repository
/// API 호출을 담당하는 레포지토리
class CompanyRepository {
  final CompanyApi _companyApi;

  CompanyRepository({CompanyApi? companyApi})
      : _companyApi = companyApi ?? CompanyApi();

  /// 기업 정보 조회
  Future<CompanyInfo> getCompanyInfo(String companyId) async {
    try {
      return await _companyApi.getCompanyInfo(companyId);
    } catch (e) {
      // 에러 처리는 상위에서 처리
      rethrow;
    }
  }

  /// 기업 검색
  Future<List<CompanyInfo>> searchCompanies({
    required String query,
    int limit = 10,
  }) async {
    try {
      return await _companyApi.searchCompanies(
        query: query,
        limit: limit,
      );
    } catch (e) {
      // 에러 처리는 상위에서 처리
      rethrow;
    }
  }

  /// Repository 종료
  void dispose() {
    _companyApi.dispose();
  }
}
