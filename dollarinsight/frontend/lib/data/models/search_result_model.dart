/// 검색 결과 모델
class SearchResult {
  final String ticker;
  final String assetType; // "STOCK" or "ETF"
  final String name; // 한글명
  final String nameEng; // 영문명
  final String exchange; // 거래소 (e.g., "NASD")

  SearchResult({
    required this.ticker,
    required this.assetType,
    required this.name,
    required this.nameEng,
    required this.exchange,
  });

  /// JSON에서 SearchResult 객체 생성
  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      ticker: json['ticker']?.toString() ?? '',
      assetType: json['assetType']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      nameEng: json['nameEng']?.toString() ?? '',
      exchange: json['exchange']?.toString() ?? '',
    );
  }

  /// SearchResult 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'ticker': ticker,
      'assetType': assetType,
      'name': name,
      'nameEng': nameEng,
      'exchange': exchange,
    };
  }

  /// STOCK인지 확인
  bool get isStock => assetType == 'STOCK';

  /// ETF인지 확인
  bool get isETF => assetType == 'ETF';

  /// 표시용 이름 (한글명 + 영문명)
  String get displayName => '$name ($nameEng)';
}
