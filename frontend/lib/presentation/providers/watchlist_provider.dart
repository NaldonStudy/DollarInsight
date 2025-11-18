import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/repositories/watchlist_repository.dart';
import '../../data/models/watchlist_model.dart';
import '../../data/datasources/remote/watchlist_api.dart';
import '../../data/datasources/remote/api_client.dart';

/// 관심종목 화면의 상태와 비즈니스 로직을 관리하는 Provider
class WatchlistProvider with ChangeNotifier {
  final WatchlistRepository _repository;

  WatchlistProvider({WatchlistRepository? repository})
      : _repository = repository ?? WatchlistRepository(WatchlistApi(ApiClient())) {
    loadWatchlist();
  }

  // ============= 상태 변수들 =============

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<WatchlistItem> _watchlist = [];
  List<WatchlistItem> get watchlist => _watchlist;

  // ============= 비즈니스 로직 =============

  /// 관심종목 목록 로드
  Future<void> loadWatchlist({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _watchlist = await _repository.getWatchlist(forceRefresh: forceRefresh);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e is WatchlistException ? e.message : '관심종목을 불러오는데 실패했습니다: $e';
      _isLoading = false;
      notifyListeners();

      if (kDebugMode) {
        print('[WatchlistProvider] 관심종목 로드 실패: $e');
      }
    }
  }

  /// 관심종목 추가
  Future<bool> addToWatchlist(String ticker) async {
    try {
      await _repository.addToWatchlist(ticker);
      await loadWatchlist(forceRefresh: true);
      return true;
    } catch (e) {
      _error = e is WatchlistException ? e.message : '관심종목 추가에 실패했습니다: $e';
      notifyListeners();

      if (kDebugMode) {
        print('[WatchlistProvider] 관심종목 추가 실패: $e');
      }
      return false;
    }
  }

  /// 관심종목 삭제
  Future<bool> removeFromWatchlist(String ticker) async {
    try {
      await _repository.removeFromWatchlist(ticker);
      await loadWatchlist(forceRefresh: true);
      return true;
    } catch (e) {
      _error = e is WatchlistException ? e.message : '관심종목 삭제에 실패했습니다: $e';
      notifyListeners();

      if (kDebugMode) {
        print('[WatchlistProvider] 관심종목 삭제 실패: $e');
      }
      return false;
    }
  }

  /// 데이터 새로고침
  Future<void> refresh() async {
    await loadWatchlist(forceRefresh: true);
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
