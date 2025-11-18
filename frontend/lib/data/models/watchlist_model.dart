/// 자산 타입 열거형
enum AssetType {
  stock('STOCK'),
  etf('ETF'),
  marketIndex('INDEX');

  const AssetType(this.value);
  final String value;

  static AssetType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'STOCK':
        return AssetType.stock;
      case 'ETF':
        return AssetType.etf;
      case 'INDEX':
        return AssetType.marketIndex;
      default:
        throw ArgumentError('Unknown asset type: $value');
    }
  }
}

/// 관심종목 아이템 모델
class WatchlistItem {
  final String ticker;
  final AssetType assetType;
  final String name;
  final String? nameEng;
  final String exchange;
  final DateTime addedAt;
  final DateTime? lastPriceDate;
  final double? lastPrice;
  final double? changePct;

  const WatchlistItem({
    required this.ticker,
    required this.assetType,
    required this.name,
    this.nameEng,
    required this.exchange,
    required this.addedAt,
    this.lastPriceDate,
    this.lastPrice,
    this.changePct,
  });

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      ticker: json['ticker'] as String,
      assetType: AssetType.fromString(json['assetType'] as String),
      name: json['name'] as String,
      nameEng: json['nameEng'] as String?,
      exchange: json['exchange'] as String,
      addedAt: DateTime.parse(json['addedAt'] as String),
      lastPriceDate: json['lastPriceDate'] != null
          ? DateTime.parse(json['lastPriceDate'] as String)
          : null,
      lastPrice: json['lastPrice']?.toDouble(),
      changePct: json['changePct']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticker': ticker,
      'assetType': assetType.value,
      'name': name,
      'nameEng': nameEng,
      'exchange': exchange,
      'addedAt': addedAt.toIso8601String(),
      'lastPriceDate': lastPriceDate?.toIso8601String(),
      'lastPrice': lastPrice,
      'changePct': changePct,
    };
  }

  /// 변화율이 양수인지 확인
  bool get isPriceUp => changePct != null && changePct! > 0;

  /// 변화율이 음수인지 확인
  bool get isPriceDown => changePct != null && changePct! < 0;

  /// 가격 변화가 없는지 확인
  bool get isPriceFlat => changePct != null && changePct! == 0;

  /// 한국 원화로 변환된 가격 (임시 환율 적용)
  double? get priceInKRW {
    if (lastPrice == null) return null;
    // 임시로 1300원 환율 적용 (실제로는 실시간 환율 API 사용 필요)
    return lastPrice! * 1300;
  }

  @override
  String toString() {
    return 'WatchlistItem{ticker: $ticker, name: $name, assetType: $assetType, lastPrice: $lastPrice, changePct: $changePct}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WatchlistItem && other.ticker == ticker;
  }

  @override
  int get hashCode => ticker.hashCode;

  /// 복사본 생성
  WatchlistItem copyWith({
    String? ticker,
    AssetType? assetType,
    String? name,
    String? nameEng,
    String? exchange,
    DateTime? addedAt,
    DateTime? lastPriceDate,
    double? lastPrice,
    double? changePct,
  }) {
    return WatchlistItem(
      ticker: ticker ?? this.ticker,
      assetType: assetType ?? this.assetType,
      name: name ?? this.name,
      nameEng: nameEng ?? this.nameEng,
      exchange: exchange ?? this.exchange,
      addedAt: addedAt ?? this.addedAt,
      lastPriceDate: lastPriceDate ?? this.lastPriceDate,
      lastPrice: lastPrice ?? this.lastPrice,
      changePct: changePct ?? this.changePct,
    );
  }
}

/// 관심종목 추가 요청 모델
class WatchlistAddRequest {
  final String ticker;

  const WatchlistAddRequest({
    required this.ticker,
  });

  Map<String, dynamic> toJson() {
    return {
      'ticker': ticker.trim().toUpperCase(), // 공백 제거 및 대문자 변환
    };
  }

  factory WatchlistAddRequest.fromJson(Map<String, dynamic> json) {
    return WatchlistAddRequest(
      ticker: json['ticker'] as String,
    );
  }

  @override
  String toString() {
    return 'WatchlistAddRequest{ticker: $ticker}';
  }
}

/// 관심종목 상태 응답 모델
class WatchlistStatus {
  final String ticker;
  final bool watching;

  const WatchlistStatus({
    required this.ticker,
    required this.watching,
  });

  factory WatchlistStatus.fromJson(Map<String, dynamic> json) {
    return WatchlistStatus(
      ticker: json['ticker'] as String,
      watching: json['watching'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticker': ticker,
      'watching': watching,
    };
  }

  @override
  String toString() {
    return 'WatchlistStatus{ticker: $ticker, watching: $watching}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WatchlistStatus &&
        other.ticker == ticker &&
        other.watching == watching;
  }

  @override
  int get hashCode => ticker.hashCode ^ watching.hashCode;
}

/// API 에러 응답 모델
class ApiError {
  final String? code;
  final String? message;
  final String? path;
  final DateTime? timestamp;

  const ApiError({
    this.code,
    this.message,
    this.path,
    this.timestamp,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] as String?,
      message: json['message'] as String?,
      path: json['path'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      'path': path,
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'ApiError{code: $code, message: $message, path: $path}';
  }
}
