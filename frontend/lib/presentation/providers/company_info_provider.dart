import 'package:flutter/material.dart';
import '../../data/models/company_model.dart';
import '../../data/repositories/company_repository.dart';

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

  /// 임시 더미 데이터 (API 연결 전)
  void _useDummyData() {
    _companyInfo = CompanyInfo(
      id: companyId,
      name: '엔비디아',
      description:
          '그래픽 프로세서 기술을 제공하는 세계적인 반도체 기업으로서, 컴퓨터, 게임기 등에 들어가는 GPU 개발 및 판매',
      logoUrl: null,
      homepage: 'http://www.nvidia.com',
      ceo: 'Jen Hsun Huang',
      foundedYear: '1993년',
      listingDate: '1999년 1월 22일',
    );
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
