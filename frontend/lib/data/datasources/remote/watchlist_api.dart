import '../../models/watchlist_model.dart';
import 'api_client.dart';

/// 관심종목 관리 API 클래스
class WatchlistApi {
  final ApiClient _apiClient;

  WatchlistApi(this._apiClient);

  /// 내 관심종목 목록 조회
  ///
  /// 로그인한 사용자의 관심종목을 최신 등록순으로 반환합니다.
  /// 서버가 ticker를 대문자로 정규화하고, 존재하지 않는 자산은 거르므로
  /// 안전하게 가격/거래소 정보를 함께 내려줍니다.
  ///
  /// Returns: [List<WatchlistItem>] - 관심종목 목록
  /// Throws: [Exception] - API 호출 실패 시
  Future<List<WatchlistItem>> getWatchlist() async {
    try {
      final dynamic response = await _apiClient.get('/api/watchlist');

      // API 응답이 { ok, data, timestamp } 구조로 래핑되어 있음
      final data = response['data'];

      if (data is List) {
        return data
            .map((item) => WatchlistItem.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('예상치 못한 응답 구조: ${data.runtimeType}');
      }
    } catch (e) {
      throw Exception('관심종목 목록 조회 실패: $e');
    }
  }

  /// 관심종목 등록
  ///
  /// ticker를 관심종목에 추가합니다.
  /// 서버가 공백 제거 + 대문자 변환 후 존재 여부와 자산 타입을 검증합니다.
  /// 이미 등록된 티커는 409 CONFLICT로 응답합니다.
  ///
  /// [ticker]: 등록할 티커 (최대 16자)
  ///
  /// Throws: [Exception] - API 호출 실패 시
  /// - 400: 잘못된 요청
  /// - 404: 존재하지 않는 티커
  /// - 409: 이미 등록된 티커
  Future<void> addToWatchlist(String ticker) async {
    try {
      final requestData = WatchlistAddRequest(ticker: ticker);

      await _apiClient.post(
        '/api/watchlist',
        body: requestData.toJson(),
      );
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();
      
      if (errorMessage.contains('409') || errorMessage.contains('conflict')) {
        throw Exception('$ticker는 이미 관심종목에 등록되어 있습니다');
      } else if (errorMessage.contains('404') || errorMessage.contains('not found')) {
        throw Exception('$ticker는 존재하지 않는 종목입니다');
      } else if (errorMessage.contains('400') || errorMessage.contains('bad request')) {
        throw Exception('잘못된 티커 형식입니다');
      }
      
      throw Exception('관심종목 추가 실패: $e');
    }
  }

  /// 관심종목 여부 확인
  ///
  /// 단일 ticker가 내 관심종목에 포함되어 있는지 Boolean으로 알려줍니다.
  /// Path ticker는 서버가 대문자로 정규화합니다.
  ///
  /// [ticker]: 확인할 티커
  ///
  /// Returns: [WatchlistStatus] - 관심종목 여부 정보
  /// Throws: [Exception] - API 호출 실패 시
  /// - 404: 존재하지 않는 자산
  Future<WatchlistStatus> getWatchlistStatus(String ticker) async {
    try {
      final response = await _apiClient.get('/api/watchlist/$ticker/status');

      // response가 직접 데이터인 경우와 'data' 키에 있는 경우 모두 처리
      final data = response['data'] ?? response;
      return WatchlistStatus.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('관심종목 상태 조회 실패: $e');
    }
  }

  /// 관심종목 삭제
  ///
  /// 관심종목에서 특정 ticker를 제거합니다.
  /// Path 변수는 대소문자 구분 없이 처리되며 서버가 존재 여부를 확인합니다.
  ///
  /// [ticker]: 삭제할 티커
  ///
  /// Throws: [Exception] - API 호출 실패 시
  /// - 404: 목록에 없는 티커
  Future<void> removeFromWatchlist(String ticker) async {
    try {
      await _apiClient.delete('/api/watchlist/$ticker');
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();
      
      if (errorMessage.contains('404') || errorMessage.contains('not found')) {
        throw Exception('$ticker는 관심종목에 등록되어 있지 않습니다');
      }
      
      throw Exception('관심종목 삭제 실패: $e');
    }
  }

  /// 관심종목 토글 (추가/삭제)
  ///
  /// 관심종목 여부를 확인한 후 추가 또는 삭제합니다.
  ///
  /// [ticker]: 토글할 티커
  ///
  /// Returns: [bool] - true: 추가됨, false: 삭제됨
  /// Throws: [Exception] - API 호출 실패 시
  Future<bool> toggleWatchlist(String ticker) async {
    try {
      final status = await getWatchlistStatus(ticker);

      if (status.watching) {
        await removeFromWatchlist(ticker);
        return false;
      } else {
        await addToWatchlist(ticker);
        return true;
      }
    } catch (e) {
      throw Exception('관심종목 토글 실패: $e');
    }
  }

  /// 여러 종목의 관심종목 여부를 한번에 확인
  ///
  /// [tickers]: 확인할 티커 목록
  ///
  /// Returns: [Map<String, bool>] - 티커별 관심종목 여부
  /// Throws: [Exception] - API 호출 실패 시
  Future<Map<String, bool>> getWatchlistStatuses(List<String> tickers) async {
    final results = <String, bool>{};

    try {
      // 병렬로 처리하여 성능 향상
      final futures = tickers.map((ticker) =>
          getWatchlistStatus(ticker).then((status) =>
              MapEntry(ticker, status.watching)
          ).catchError((e) => MapEntry(ticker, false))
      );

      final entries = await Future.wait(futures);

      for (final entry in entries) {
        results[entry.key] = entry.value;
      }

      return results;
    } catch (e) {
      throw Exception('관심종목 상태 일괄 조회 실패: $e');
    }
  }
}