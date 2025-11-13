/// 자산(주식/ETF) 모델
class Asset {
  final String ticker;
  final String assetType; // "STOCK" or "ETF"
  final String createdAt;
  final String updatedAt;

  Asset({
    required this.ticker,
    required this.assetType,
    required this.createdAt,
    required this.updatedAt,
  });

  /// JSON에서 Asset 객체 생성
  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      ticker: json['ticker']?.toString() ?? '',
      assetType: json['assetType']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }

  /// Asset 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'ticker': ticker,
      'assetType': assetType,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// STOCK인지 확인
  bool get isStock => assetType == 'STOCK';

  /// ETF인지 확인
  bool get isETF => assetType == 'ETF';

  /// 복사본 생성
  Asset copyWith({
    String? ticker,
    String? assetType,
    String? createdAt,
    String? updatedAt,
  }) {
    return Asset(
      ticker: ticker ?? this.ticker,
      assetType: assetType ?? this.assetType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
