import 'package:flutter/foundation.dart';
import '../../data/datasources/remote/company_api.dart';
import '../../data/models/asset_model.dart';

/// 전체 종목 목록 화면의 상태와 비즈니스 로직을 관리하는 Provider
class AllStocksListProvider with ChangeNotifier {
  final CompanyApi _companyApi;

  AllStocksListProvider({CompanyApi? companyApi})
      : _companyApi = companyApi ?? CompanyApi() {
    loadAssets();
  }

  // ============= 상태 변수들 =============

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<Asset> _allAssets = [];
  List<Asset> get allAssets => _allAssets;

  // 필터링된 리스트
  List<Asset> get stocks => _allAssets.where((asset) => asset.isStock).toList();
  List<Asset> get etfs => _allAssets.where((asset) => asset.isETF).toList();

  // ============= 비즈니스 로직 =============

  /// 자산 목록 로드
  Future<void> loadAssets() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _companyApi.getAssets();

      _allAssets = response
          .map((item) => Asset.fromJson(item))
          .toList();

      // ticker 기준 알파벳 순 정렬
      _allAssets.sort((a, b) => a.ticker.compareTo(b.ticker));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = '자산 목록을 불러오는데 실패했습니다: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 새로고침
  Future<void> refresh() async {
    await loadAssets();
  }

  /// 에러 메시지 초기화
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _companyApi.dispose();
    super.dispose();
  }
}