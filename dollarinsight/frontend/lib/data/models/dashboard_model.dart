/// 대시보드 응답 모델
class DashboardResponse {
  final List<MajorIndex> majorIndices;
  final List<RecommendedNews> recommendedNews;
  final List<DailyPick> dailyPick;

  DashboardResponse({
    required this.majorIndices,
    required this.recommendedNews,
    required this.dailyPick,
  });

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    return DashboardResponse(
      majorIndices: (json['majorIndices'] as List?)
              ?.map((e) => MajorIndex.fromJson(e))
              .toList() ??
          [],
      recommendedNews: (json['recommendedNews'] as List?)
              ?.map((e) => RecommendedNews.fromJson(e))
              .toList() ??
          [],
      dailyPick: (json['dailyPick'] as List?)
              ?.map((e) => DailyPick.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// 주요 지수
class MajorIndex {
  final String ticker;
  final String name;
  final double close;
  final double changePct;
  final String priceDate;

  MajorIndex({
    required this.ticker,
    required this.name,
    required this.close,
    required this.changePct,
    required this.priceDate,
  });

  factory MajorIndex.fromJson(Map<String, dynamic> json) {
    return MajorIndex(
      ticker: json['ticker']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      close: (json['close'] ?? 0).toDouble(),
      changePct: (json['changePct'] ?? 0).toDouble(),
      priceDate: json['priceDate']?.toString() ?? '',
    );
  }
}

/// 추천 뉴스
class RecommendedNews {
  final String id;
  final String ticker;
  final String title;
  final String summary;
  final String url;
  final String publishedAt;

  RecommendedNews({
    required this.id,
    required this.ticker,
    required this.title,
    required this.summary,
    required this.url,
    required this.publishedAt,
  });

  factory RecommendedNews.fromJson(Map<String, dynamic> json) {
    return RecommendedNews(
      id: json['id']?.toString() ?? '',
      ticker: json['ticker']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      publishedAt: json['publishedAt']?.toString() ?? '',
    );
  }
}

/// 오늘의 픽
class DailyPick {
  final String ticker;
  final String companyName;
  final String companyInfo;
  final String analyzedDate;
  final PersonaComment personaComment;

  DailyPick({
    required this.ticker,
    required this.companyName,
    required this.companyInfo,
    required this.analyzedDate,
    required this.personaComment,
  });

  factory DailyPick.fromJson(Map<String, dynamic> json) {
    return DailyPick(
      ticker: json['ticker']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? '',
      companyInfo: json['companyInfo']?.toString() ?? '',
      analyzedDate: json['analyzedDate']?.toString() ?? '',
      personaComment: PersonaComment.fromJson(json['personaComment'] ?? {}),
    );
  }
}

/// 페르소나 코멘트 (DailyPick용)
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
