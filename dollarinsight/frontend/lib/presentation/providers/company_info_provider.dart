import 'package:flutter/material.dart';
import '../../data/models/company_model.dart';
import '../../data/repositories/company_repository.dart';
import '../../core/constants/company_data.dart';

/// 기업 설명 화면의 상태와 비즈니스 로직을 관리하는 Provider
class CompanyInfoProvider with ChangeNotifier {
  final String companyId;
  final CompanyRepository _repository;

  CompanyInfoProvider({
    required this.companyId,
    CompanyRepository? repository,
  })  : _repository = repository ?? CompanyRepository() {
    _loadCompanyInfo();
  }

  // ============= 상태 변수들 =============

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  CompanyInfo? _companyInfo;
  CompanyInfo? get companyInfo => _companyInfo;

  String? _error;
  String? get error => _error;

  // ============= 비즈니스 로직 =============

  /// 기업 정보 로드 (API 연결 지점)
  Future<void> _loadCompanyInfo() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // ============= API 연결 지점 (TODO: 기업 설명 API 연동 필요) =============
      // Repository를 통해 기업 정보 조회
      // _companyInfo = await _repository.getCompanyInfo(companyId);

      // 임시로 더미 데이터 사용
      _useDummyData();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // API 연결 전에는 더미 데이터 사용
      _useDummyData();
      _isLoading = false;
      notifyListeners();

      // 실제 API 연결 후에는 에러 처리
      // _error = '기업 정보를 불러오는데 실패했습니다: $e';
      // _isLoading = false;
      // notifyListeners();
    }
  }

  /// 하드코딩 데이터 사용 (company_data.dart에서 가져오기)
  void _useDummyData() {
    // companyId에 해당하는 데이터를 company_data.dart에서 조회
    _companyInfo = getCompanyData(companyId);

    // 데이터가 없으면 에러 설정
    if (_companyInfo == null) {
      _error = '해당 기업($companyId) 정보를 찾을 수 없습니다.\ncompany_data.dart에 데이터를 추가해주세요.';
    }
  }

  /// 데이터 새로고침
  Future<void> refresh() async {
    await _loadCompanyInfo();
  }

  /// 에러 메시지 초기화
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}
