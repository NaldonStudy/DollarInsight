import 'api_client.dart';
import '../../models/company_model.dart';
import '../../models/company_detail_model.dart';

/// 기업분석 API 클라이언트
/// API 문서의 Company Analysis 태그 엔드포인트들을 구현
class CompanyApi {
  final ApiClient _apiClient;

  CompanyApi({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  // ---------------------------------------------------------------------------
  // ✅ 기업/ETF 상세 정보 조회
  // GET /api/company-analysis/{ticker}
  // ---------------------------------------------------------------------------

  /// 기업/ETF 상세 정보 조회
  ///
  /// [ticker]: 종목 티커 (예: AAPL, NVDA, QQQ)
  ///
  /// 반환: CompanyDetailResponse 객체
  /// 포함 데이터: 기본정보, 가격정보, 예측, 투자지표, 페르소나 코멘트, 뉴스
  ///
  /// API: GET /api/company-analysis/{ticker}
  /// 응답: {ok: true, data: CompanyDetailResponse}
  Future<CompanyDetailResponse> getCompanyDetail(String ticker) async {
    try {
      final response = await _apiClient.get(
        '/api/company-analysis/$ticker',
      );

      // ✅ API 응답이 {ok: true, data: {...}} 구조이므로 data 필드 추출
      final data = response['data'] as Map<String, dynamic>;
      return CompanyDetailResponse.fromJson(data);
    } catch (e) {
      if (e.toString().contains('404')) {
        throw Exception('해당 티커($ticker)를 찾을 수 없습니다');
      }
      throw Exception('기업 상세 정보 조회 실패: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // ✅ 티커 검색 (자동완성)
  // GET /api/company-analysis/search
  // ---------------------------------------------------------------------------

  /// 티커 검색 (주식/ETF 통합 자동완성)
  ///
  /// [keyword]: 검색어 (티커, 국문명, 영문명, ETF 이름에서 부분일치)
  /// [size]: 최대 결과 수 (1-30, 기본값: 10)
  ///
  /// 반환: 검색된 자산 목록 (ticker, assetType, name, nameEng, exchange 포함)
  ///
  /// API: GET /api/company-analysis/search
  /// 응답: {ok: true, data: [...]}
  Future<List<Map<String, dynamic>>> searchAssets({
    required String keyword,
    int size = 10,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/company-analysis/search',
        queryParameters: {
          'keyword': keyword,
          'size': size,
        },
      );

      // ✅ API 응답이 {ok: true, data: [...]} 구조이므로 data 필드 추출
      final data = response['data'];

      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map<String, dynamic>) {
        // 만약 단일 객체로 오는 경우, 리스트로 감싸서 반환
        return [data];
      }

      return [];
    } catch (e) {
      throw Exception('자산 검색 실패: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // ✅ 뉴스 목록 조회
  // GET /api/company-analysis/news
  // ---------------------------------------------------------------------------

  /// 뉴스 목록 조회 (Investing.com 기반)
  ///
  /// [ticker]: 특정 티커 뉴스만 조회 (선택사항)
  /// [page]: 페이지 번호 (0부터 시작, 기본값: 0)
  /// [size]: 페이지 크기 (1-100, 기본값: 20)
  ///
  /// 반환: 페이지네이션된 뉴스 목록 (items, totalElements, page, size)
  ///
  /// API: GET /api/company-analysis/news
  /// 응답: {ok: true, data: PagedNewsResponse}
  Future<Map<String, dynamic>> getNewsList({
    String? ticker,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };

      if (ticker != null && ticker.isNotEmpty) {
        queryParams['ticker'] = ticker;
      }

      final response = await _apiClient.get(
        '/api/company-analysis/news',
        queryParameters: queryParams,
      );

      // ✅ API 응답이 {ok: true, data: {...}} 구조이므로 data 필드 추출
      final data = response['data'] as Map<String, dynamic>;
      return data;
    } catch (e) {
      throw Exception('뉴스 목록 조회 실패: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // ✅ 뉴스 상세 조회
  // GET /api/company-analysis/news/{newsId}
  // ---------------------------------------------------------------------------

  /// 뉴스 상세 조회
  ///
  /// [newsId]: MongoDB 뉴스 문서 ID
  ///
  /// 반환: 뉴스 상세 정보 + 페르소나 코멘트
  /// 포함 데이터: id, ticker, title, summary, content, url, publishedAt, personaComments
  ///
  /// API: GET /api/company-analysis/news/{newsId}
  /// 응답: {ok: true, data: NewsDetailResponse}
  Future<Map<String, dynamic>> getNewsDetail(String newsId) async {
    try {
      final response = await _apiClient.get(
        '/api/company-analysis/news/$newsId',
      );

      // ✅ API 응답이 {ok: true, data: {...}} 구조이므로 data 필드 추출
      final data = response['data'] as Map<String, dynamic>;
      return data;
    } catch (e) {
      if (e.toString().contains('404')) {
        throw Exception('해당 뉴스를 찾을 수 없습니다');
      }
      throw Exception('뉴스 상세 조회 실패: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // ✅ 기업분석 대시보드
  // GET /api/company-analysis/dashboard
  // ---------------------------------------------------------------------------

  /// 기업분석 대시보드 데이터 조회
  ///
  /// 반환: 주요지수, 추천뉴스, 데일리픽을 포함한 대시보드 데이터
  /// 포함 데이터:
  /// - majorIndices: S&P500, 나스닥 등 6개 주요 지수
  /// - recommendedNews: 추천 뉴스 3건
  /// - dailyPick: 페르소나 데일리 픽 카드들
  ///
  /// API: GET /api/company-analysis/dashboard
  /// 응답: DashboardResponse (직접 객체)
  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final response = await _apiClient.get(
        '/api/company-analysis/dashboard',
      );

      // ✅ API 문서: 직접 DashboardResponse 객체 반환
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('대시보드 데이터 조회 실패: $e');
    }
  }

  /// 전체 자산(주식 + ETF) 목록 조회
  ///
  /// 반환: Asset 리스트 (주식 + ETF)
  ///
  /// API 엔드포인트: GET /api/company-analysis/assets
  Future<List<Map<String, dynamic>>> getAssets() async {
    try {
      final response = await _apiClient.get(
        '/api/company-analysis/assets',
      );

      // API 응답이 { ok, data, timestamp } 구조로 래핑되어 있음
      final data = response['data'] as List<dynamic>;
      return data.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('자산 목록 조회 실패: $e');
    }
  }

  /// 기업/ETF 검색 (자동완성용)
  ///
  /// [keyword]: 검색어 (티커, 한글명, 영문명)
  ///
  /// 반환: SearchResult 리스트
  ///
  /// API 엔드포인트: GET /api/company-analysis/search?keyword={keyword}
  Future<List<Map<String, dynamic>>> searchCompanies(String keyword) async {
    try {
      final response = await _apiClient.get(
        '/api/company-analysis/search',
        queryParameters: {
          'keyword': keyword,
        },
      );

      // API 응답이 { ok, data, timestamp } 구조로 래핑되어 있음
      final data = response['data'] as List<dynamic>;
      return data.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('기업 검색 실패: $e');
    }
  }


  /// API 클라이언트 종료
  void dispose() {
    _apiClient.dispose();
  }
}