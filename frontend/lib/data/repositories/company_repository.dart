import '../datasources/remote/company_api.dart';
import '../models/company_detail_model.dart';

/// 기업 Repository
/// API 호출을 담당하는 레포지토리
class CompanyRepository {
  final CompanyApi _companyApi;

  CompanyRepository({CompanyApi? companyApi})
      : _companyApi = companyApi ?? CompanyApi();

  /// 기업 상세 정보 조회
  Future<CompanyDetailResponse> getCompanyDetail(String ticker) async {
    try {
      return await _companyApi.getCompanyDetail(ticker);
    } catch (e) {
      // 에러 처리는 상위에서 처리
      rethrow;
    }
  }

  /// 기업/ETF 검색 (자동완성)
  Future<List<Map<String, dynamic>>> searchCompanies(String keyword) async {
    try {
      return await _companyApi.searchCompanies(keyword);
    } catch (e) {
      // 에러 처리는 상위에서 처리
      rethrow;
    }
  }

  /// 전체 자산 목록 조회
  Future<List<Map<String, dynamic>>> getAssets() async {
    try {
      return await _companyApi.getAssets();
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
