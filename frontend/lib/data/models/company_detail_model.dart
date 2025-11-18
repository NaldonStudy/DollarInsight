/// 기업 상세 정보 응답 모델
class CompanyDetailResponse {
  final BasicInfo basicInfo;
  final PriceOverview priceOverview;
  final PriceSeries priceSeries;
  final Predictions predictions;
  final StockIndicators? stockIndicators;
  final EtfIndicators? etfIndicators;
  final StockScores? stockScores;
  final List<PersonaComment> personaComments;
  final List<NewsItem> latestNews;

  CompanyDetailResponse({
    required this.basicInfo,
    required this.priceOverview,
    required this.priceSeries,
    required this.predictions,
    this.stockIndicators,
    this.etfIndicators,
    this.stockScores,
    required this.personaComments,
    required this.latestNews,
  });

  factory CompanyDetailResponse.fromJson(Map<String, dynamic> json) {
    return CompanyDetailResponse(
      basicInfo: BasicInfo.fromJson(json['basicInfo'] ?? {}),
      priceOverview: PriceOverview.fromJson(json['priceOverview'] ?? {}),
      priceSeries: PriceSeries.fromJson(json['priceSeries'] ?? {}),
      predictions: Predictions.fromJson(json['predictions'] ?? {}),
      stockIndicators: json['stockIndicators'] != null
          ? StockIndicators.fromJson(json['stockIndicators'])
          : null,
      etfIndicators: json['etfIndicators'] != null
          ? EtfIndicators.fromJson(json['etfIndicators'])
          : null,
      stockScores: json['stockScores'] != null
          ? StockScores.fromJson(json['stockScores'])
          : null,
      personaComments: (json['personaComments'] as List?)
              ?.map((e) => PersonaComment.fromJson(e))
              .toList() ??
          [],
      latestNews: (json['latestNews'] as List?)
              ?.map((e) => NewsItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// 기본 정보
class BasicInfo {
  final String ticker;
  final String name;
  final String nameEng;
  final String assetType;
  final String exchange;
  final String exchangeName;
  final String currency;
  final String country;
  final String sector;
  final String industry;
  final String? listedAt;
  final String? website;
  final bool leverage;
  final double leverageFactor;

  BasicInfo({
    required this.ticker,
    required this.name,
    required this.nameEng,
    required this.assetType,
    required this.exchange,
    required this.exchangeName,
    required this.currency,
    required this.country,
    required this.sector,
    required this.industry,
    this.listedAt,
    this.website,
    required this.leverage,
    required this.leverageFactor,
  });

  factory BasicInfo.fromJson(Map<String, dynamic> json) {
    return BasicInfo(
      ticker: json['ticker']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      nameEng: json['nameEng']?.toString() ?? '',
      assetType: json['assetType']?.toString() ?? 'STOCK',
      exchange: json['exchange']?.toString() ?? '',
      exchangeName: json['exchangeName']?.toString() ?? '',
      currency: json['currency']?.toString() ?? 'USD',
      country: json['country']?.toString() ?? '',
      sector: json['sector']?.toString() ?? '',
      industry: json['industry']?.toString() ?? '',
      listedAt: json['listedAt']?.toString(),
      website: json['website']?.toString(),
      leverage: json['leverage'] ?? false,
      leverageFactor: (json['leverageFactor'] ?? 0).toDouble(),
    );
  }
}

/// 가격 개요
class PriceOverview {
  final double latestCloseUsd;
  final double latestCloseKrw;
  final String priceDate;
  final double changePct;
  final double periodLow;
  final double periodHigh;

  PriceOverview({
    required this.latestCloseUsd,
    required this.latestCloseKrw,
    required this.priceDate,
    required this.changePct,
    required this.periodLow,
    required this.periodHigh,
  });

  factory PriceOverview.fromJson(Map<String, dynamic> json) {
    return PriceOverview(
      latestCloseUsd: (json['latestCloseUsd'] ?? 0).toDouble(),
      latestCloseKrw: (json['latestCloseKrw'] ?? 0).toDouble(),
      priceDate: json['priceDate']?.toString() ?? '',
      changePct: (json['changePct'] ?? 0).toDouble(),
      periodLow: (json['periodLow'] ?? 0).toDouble(),
      periodHigh: (json['periodHigh'] ?? 0).toDouble(),
    );
  }
}

/// 가격 데이터 포인트
class PriceDataPoint {
  final String priceDate;
  final double open;
  final double high;
  final double low;
  final double close;

  PriceDataPoint({
    required this.priceDate,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  factory PriceDataPoint.fromJson(Map<String, dynamic> json) {
    return PriceDataPoint(
      priceDate: json['priceDate']?.toString() ?? '',
      open: (json['open'] ?? 0).toDouble(),
      high: (json['high'] ?? 0).toDouble(),
      low: (json['low'] ?? 0).toDouble(),
      close: (json['close'] ?? 0).toDouble(),
    );
  }
}

/// 가격 시계열
class PriceSeries {
  final List<PriceDataPoint> dailyRange;
  final List<PriceDataPoint> weeklyRange;
  final List<PriceDataPoint> monthlyRange;

  PriceSeries({
    required this.dailyRange,
    required this.weeklyRange,
    required this.monthlyRange,
  });

  factory PriceSeries.fromJson(Map<String, dynamic> json) {
    return PriceSeries(
      dailyRange: (json['dailyRange'] as List?)
              ?.map((e) => PriceDataPoint.fromJson(e))
              .toList() ??
          [],
      weeklyRange: (json['weeklyRange'] as List?)
              ?.map((e) => PriceDataPoint.fromJson(e))
              .toList() ??
          [],
      monthlyRange: (json['monthlyRange'] as List?)
              ?.map((e) => PriceDataPoint.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// 예측 정보
class PredictionData {
  final int horizonDays;
  final String predictionDate;
  final double pointEstimate;
  final double lowerBound;
  final double upperBound;
  final double probabilityUp;

  PredictionData({
    required this.horizonDays,
    required this.predictionDate,
    required this.pointEstimate,
    required this.lowerBound,
    required this.upperBound,
    required this.probabilityUp,
  });

  factory PredictionData.fromJson(Map<String, dynamic> json) {
    return PredictionData(
      horizonDays: json['horizonDays'] ?? 0,
      predictionDate: json['predictionDate']?.toString() ?? '',
      pointEstimate: (json['pointEstimate'] ?? 0).toDouble(),
      lowerBound: (json['lowerBound'] ?? 0).toDouble(),
      upperBound: (json['upperBound'] ?? 0).toDouble(),
      probabilityUp: (json['probabilityUp'] ?? 0).toDouble(),
    );
  }
}

/// 예측들
class Predictions {
  final PredictionData oneWeek;
  final PredictionData oneMonth;

  Predictions({
    required this.oneWeek,
    required this.oneMonth,
  });

  factory Predictions.fromJson(Map<String, dynamic> json) {
    return Predictions(
      oneWeek: PredictionData.fromJson(json['oneWeek'] ?? {}),
      oneMonth: PredictionData.fromJson(json['oneMonth'] ?? {}),
    );
  }
}

/// 주식 지표
class StockIndicators {
  final double marketCap;
  final double dividendYield;
  final double? pbr;
  final double? per;
  final double? roe;
  final double? psr;

  StockIndicators({
    required this.marketCap,
    required this.dividendYield,
    this.pbr,
    this.per,
    this.roe,
    this.psr,
  });

  factory StockIndicators.fromJson(Map<String, dynamic> json) {
    return StockIndicators(
      marketCap: (json['marketCap'] ?? 0).toDouble(),
      dividendYield: (json['dividendYield'] ?? 0).toDouble(),
      pbr: json['pbr'] != null ? (json['pbr'] as num).toDouble() : null,
      per: json['per'] != null ? (json['per'] as num).toDouble() : null,
      roe: json['roe'] != null ? (json['roe'] as num).toDouble() : null,
      psr: json['psr'] != null ? (json['psr'] as num).toDouble() : null,
    );
  }
}

/// ETF 지표
class EtfIndicators {
  final String asOfDate;
  final double marketCap;
  final double dividendYield;
  final double totalAssets;
  final double nav;
  final double premiumDiscount;
  final double expenseRatio;

  EtfIndicators({
    required this.asOfDate,
    required this.marketCap,
    required this.dividendYield,
    required this.totalAssets,
    required this.nav,
    required this.premiumDiscount,
    required this.expenseRatio,
  });

  factory EtfIndicators.fromJson(Map<String, dynamic> json) {
    return EtfIndicators(
      asOfDate: json['asOfDate']?.toString() ?? '',
      marketCap: (json['marketCap'] ?? 0).toDouble(),
      dividendYield: (json['dividendYield'] ?? 0).toDouble(),
      totalAssets: (json['totalAssets'] ?? 0).toDouble(),
      nav: (json['nav'] ?? 0).toDouble(),
      premiumDiscount: (json['premiumDiscount'] ?? 0).toDouble(),
      expenseRatio: (json['expenseRatio'] ?? 0).toDouble(),
    );
  }
}

/// 주식 점수
class StockScores {
  final String scoreDate;
  final double totalScore;
  final double momentum;
  final double? valuation;
  final double growth;
  final double flow;
  final double risk;

  StockScores({
    required this.scoreDate,
    required this.totalScore,
    required this.momentum,
    this.valuation,
    required this.growth,
    required this.flow,
    required this.risk,
  });

  factory StockScores.fromJson(Map<String, dynamic> json) {
    return StockScores(
      scoreDate: json['scoreDate']?.toString() ?? '',
      totalScore: (json['totalScore'] ?? 0).toDouble(),
      momentum: (json['momentum'] ?? 0).toDouble(),
      valuation: json['valuation'] != null ? (json['valuation'] as num).toDouble() : null,
      growth: (json['growth'] ?? 0).toDouble(),
      flow: (json['flow'] ?? 0).toDouble(),
      risk: (json['risk'] ?? 0).toDouble(),
    );
  }
}

/// 페르소나 코멘트
class PersonaComment {
  final String personaCode;
  final String personaName;
  final String comment;

  PersonaComment({
    required this.personaCode,
    required this.personaName,
    required this.comment,
  });

  factory PersonaComment.fromJson(Map<String, dynamic> json) {
    return PersonaComment(
      personaCode: json['personaCode']?.toString() ?? '',
      personaName: json['personaName']?.toString() ?? '',
      comment: json['comment']?.toString() ?? '',
    );
  }
}

/// 뉴스 아이템
class NewsItem {
  final String id;
  final String ticker;
  final String title;
  final String summary;
  final String url;
  final String publishedAt;

  NewsItem({
    required this.id,
    required this.ticker,
    required this.title,
    required this.summary,
    required this.url,
    required this.publishedAt,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      id: json['id']?.toString() ?? '',
      ticker: json['ticker']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      publishedAt: json['publishedAt']?.toString() ?? '',
    );
  }
}
