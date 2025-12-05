import 'package:flutter/material.dart';
import '../../data/models/etf_model.dart';
import '../../data/repositories/etf_repository.dart';
import '../../core/constants/etf_data.dart';

/// ETF 설명 화면의 상태와 비즈니스 로직을 관리하는 Provider
class EtfInfoProvider with ChangeNotifier {
  final String etfId;
  final EtfRepository _repository;

  EtfInfoProvider({
    required this.etfId,
    EtfRepository? repository,
  })  : _repository = repository ?? EtfRepository() {
    _loadEtfInfo();
  }

  // ============= 상태 변수들 =============

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  EtfInfo? _etfInfo;
  EtfInfo? get etfInfo => _etfInfo;

  String? _error;
  String? get error => _error;

  // ============= 비즈니스 로직 =============

  /// ETF 정보 로드 (API 연결 지점)
  Future<void> _loadEtfInfo() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // ============= API 연결 지점 =============
      // Repository를 통해 ETF 정보 조회
      _etfInfo = await _repository.getEtfInfo(etfId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // API 연결 전에는 더미 데이터 사용
      _useDummyData();
      _isLoading = false;
      notifyListeners();

      // 실제 API 연결 후에는 에러 처리
      // _error = 'ETF 정보를 불러오는데 실패했습니다: $e';
      // _isLoading = false;
      // notifyListeners();
    }
  }

  /// etf_data.dart에서 가져오기
  void _useDummyData() {
    // etfId에 해당하는 데이터를 etf_data.dart에서 조회
    _etfInfo = getEtfData(etfId);

    // 데이터가 없으면 에러 설정
    if (_etfInfo == null) {
      _error = '해당 ETF($etfId) 정보를 찾을 수 없습니다.\netf_data.dart에 데이터를 추가해주세요.';
    }
  }

  /// 데이터 새로고침
  Future<void> refresh() async {
    await _loadEtfInfo();
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
