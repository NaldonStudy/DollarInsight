import 'package:flutter/material.dart';

/// 기업별 뉴스 상세 화면의 상태와 비즈니스 로직을 관리하는 Provider
/// API 연결을 통해 뉴스 상세 데이터, AI 댓글 등을 불러옴
class CompanyNewsDetailProvider with ChangeNotifier {
  final String companyId;
  final String newsId;

  CompanyNewsDetailProvider({
    required this.companyId,
    required this.newsId,
  }) {
    _loadNewsDetail();
  }

  // ============= 상태 변수들 =============

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // 뉴스 상세 데이터
  String? _title;
  String? get title => _title;

  String? _content;
  String? get content => _content;

  String? _summary;
  String? get summary => _summary;

  String? _publishedAt;
  String? get publishedAt => _publishedAt;

  String? _source;
  String? get source => _source;

  String? _url;
  String? get url => _url;

  String? _companyName;
  String? get companyName => _companyName;

  // AI 댓글 데이터
  List<Map<String, String>> _aiComments = [];
  List<Map<String, String>> get aiComments => _aiComments;

  // ============= 비즈니스 로직 =============

  /// 뉴스 상세 데이터 로드 (API 연결 지점)
  Future<void> _loadNewsDetail() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: 백엔드 API 연결
      // final response = await newsRepository.getCompanyNewsDetail(
      //   companyId: companyId,
      //   newsId: newsId,
      // );
      //
      // _title = response.title;
      // _content = response.content;
      // _summary = response.summary;
      // _publishedAt = response.publishedAt;
      // _source = response.source;
      // _url = response.url;
      // _companyName = response.companyName;
      // _aiComments = response.aiComments;

      // 임시 더미 데이터 (API 연결 후 삭제)
      await Future.delayed(const Duration(seconds: 1));

      _title = "미국 빅테크 3분기 실적 희비…구글 분기 매출 첫 1000억 달러 돌파";
      _content = """3사 모두 사상 최대 매출
시장 평가는 크게 엇갈려
알파벳, 클라우드 부문 고성장 견인
MS, 과도한 설비 투자에 투자자 불안감 커져
메타, 현실성 떨어진 비용에 EPS 예상 쇼크

알파벳(구글)은 3분기 실적에서 사상 처음으로 분기 매출이 1000억 달러를 돌파하며 강력한 성장세를 보였습니다.
특히 클라우드 부문이 고성장을 견인하며 AI 시장에서의 입지를 확고히 했습니다.

반면 마이크로소프트는 데이터센터에 349억 달러를 투자하며 과도한 설비 투자로 인한 우려가 커지고 있으며,
메타는 일회성 법인세 비용으로 인해 주당순이익(EPS)이 예상을 하회하며 '어닝 쇼크'를 기록했습니다.

전문가들은 AI 시장의 성장세가 지속될 것으로 전망하지만, 과도한 투자에 대한 경계도 필요하다고 조언하고 있습니다.""";

      _summary = "3사 모두 사상 최대 매출을 기록했으나 시장 평가는 크게 엇갈렸습니다. 알파벳은 클라우드 부문 호조로 성장을 견인했고, MS는 과도한 설비 투자에 투자자 불안감이 커졌으며, 메타는 일회성 법인세 비용에 EPS '어닝 쇼크'를 겪었습니다.";
      _publishedAt = "2025년 10월 30일 15:15";
      _source = "한국경제";
      _url = "https://kr.investing.com/news/insider-trading-news/article-93CH-1703132";
      _companyName = "엔비디아";

      _aiComments = [
        {
          'text': "구글 미쳤다ㅋㅋ 드디어 분기 매출 1,000억 달러 돌파🔥 알파벳이 AI 시장 제대로 접수했네!",
          'imagePath': "assets/images/Heeyule.webp",
        },
        {
          'text': "MS는 투자 너무 과했어요. 데이터센터에 349억 달러라니 리스크 커보여요",
          'imagePath': "assets/images/Jiyule.webp",
        },
        {
          'text': "클라우드 잔액 1,550억 달러면 구조적으로 알파벳이 AI 인프라 경쟁서 유리한 포지션이야",
          'imagePath': "assets/images/Taeo.webp",
        },
        {
          'text': "메타 주가 8% 급락😨 이번엔 세금공제 때문에 커뮤니티 분위기도 싸늘해요.",
          'imagePath': "assets/images/Minji.webp",
        },
        {
          'text': "AI 붐이 끝없이 이어질 순 없지. 투자 과열 땐 항상 조정이 오더라고",
          'imagePath': "assets/images/Ducksu.webp",
        },
      ];

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = '뉴스 상세 정보를 불러오는데 실패했습니다: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 데이터 새로고침 (API 연결 지점)
  Future<void> refresh() async {
    await _loadNewsDetail();
  }

  /// 에러 메시지 초기화
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
