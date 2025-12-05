/// ETF 정보 모델
class EtfInfo {
  final String id;
  final String name;
  final String description;
  final String? logoUrl;
  final String? lastUpdateDate;
  final String? top10HoldingsRatio;
  final String? othersRatio;
  final String? totalStocks;
  final List<EtfHolding> topHoldings;

  EtfInfo({
    required this.id,
    required this.name,
    required this.description,
    this.logoUrl,
    this.lastUpdateDate,
    this.top10HoldingsRatio,
    this.othersRatio,
    this.totalStocks,
    this.topHoldings = const [],
  });

  /// JSON에서 EtfInfo 객체 생성
  factory EtfInfo.fromJson(Map<String, dynamic> json) {
    return EtfInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      logoUrl: json['logoUrl']?.toString(),
      lastUpdateDate: json['lastUpdateDate']?.toString(),
      top10HoldingsRatio: json['top10HoldingsRatio']?.toString(),
      othersRatio: json['othersRatio']?.toString(),
      totalStocks: json['totalStocks']?.toString(),
      topHoldings: json['topHoldings'] != null
          ? (json['topHoldings'] as List)
              .map((holding) => EtfHolding.fromJson(holding))
              .toList()
          : [],
    );
  }

  /// EtfInfo 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logoUrl': logoUrl,
      'lastUpdateDate': lastUpdateDate,
      'top10HoldingsRatio': top10HoldingsRatio,
      'othersRatio': othersRatio,
      'totalStocks': totalStocks,
      'topHoldings': topHoldings.map((holding) => holding.toJson()).toList(),
    };
  }

  /// 복사본 생성
  EtfInfo copyWith({
    String? id,
    String? name,
    String? description,
    String? logoUrl,
    String? lastUpdateDate,
    String? top10HoldingsRatio,
    String? othersRatio,
    String? totalStocks,
    List<EtfHolding>? topHoldings,
  }) {
    return EtfInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      lastUpdateDate: lastUpdateDate ?? this.lastUpdateDate,
      top10HoldingsRatio: top10HoldingsRatio ?? this.top10HoldingsRatio,
      othersRatio: othersRatio ?? this.othersRatio,
      totalStocks: totalStocks ?? this.totalStocks,
      topHoldings: topHoldings ?? this.topHoldings,
    );
  }
}

/// ETF 보유 종목 모델
class EtfHolding {
  final String companyName;
  final String ratio;

  EtfHolding({
    required this.companyName,
    required this.ratio,
  });

  /// JSON에서 EtfHolding 객체 생성
  factory EtfHolding.fromJson(Map<String, dynamic> json) {
    return EtfHolding(
      companyName: json['companyName']?.toString() ?? '',
      ratio: json['ratio']?.toString() ?? '',
    );
  }

  /// EtfHolding 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'ratio': ratio,
    };
  }
}
