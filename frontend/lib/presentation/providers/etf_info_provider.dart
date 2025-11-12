import 'package:flutter/material.dart';
import '../../data/models/etf_model.dart';
import '../../data/repositories/etf_repository.dart';

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

  /// 임시 더미 데이터 (API 연결 전)
  void _useDummyData() {
    _etfInfo = EtfInfo(
      id: etfId,
      name: 'QQQ',
      description:
          'AI와 테크 산업의 흐름을 반영하는 대표 ETF. 클라우드·반도체·플랫폼 등 혁신 성장주 중심으로 구성됩니다.',
      logoUrl: null,
      lastUpdateDate: '2025-10-31',
      top10HoldingsRatio: '45.2%',
      othersRatio: '54.8%',
      totalStocks: '102개',
      topHoldings: [
        EtfHolding(companyName: 'NVIDIA Corporation', ratio: '7.94%'),
        EtfHolding(companyName: 'Apple Inc.', ratio: '7.50%'),
        EtfHolding(companyName: 'Microsoft Corporation', ratio: '7.20%'),
        EtfHolding(companyName: 'Amazon.com Inc.', ratio: '6.80%'),
        EtfHolding(companyName: 'Meta Platforms Inc.', ratio: '5.10%'),
      ],
    );
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
