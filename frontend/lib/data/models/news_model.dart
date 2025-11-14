/// 뉴스 목록 아이템 모델
class NewsListItem {
  final String id;
  final String ticker;
  final String title;
  final String summary;
  final String url;
  final String publishedAt;

  NewsListItem({
    required this.id,
    required this.ticker,
    required this.title,
    required this.summary,
    required this.url,
    required this.publishedAt,
  });

  /// JSON에서 NewsListItem 객체 생성
  factory NewsListItem.fromJson(Map<String, dynamic> json) {
    return NewsListItem(
      id: json['id']?.toString() ?? '',
      ticker: json['ticker']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      publishedAt: json['publishedAt']?.toString() ?? '',
    );
  }

  /// NewsListItem 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticker': ticker,
      'title': title,
      'summary': summary,
      'url': url,
      'publishedAt': publishedAt,
    };
  }
}

/// 뉴스 상세 정보 모델
class NewsDetail {
  final String id;
  final String ticker;
  final String title;
  final String summary;
  final String content;
  final String url;
  final String publishedAt;
  final List<PersonaComment> personaComments;

  NewsDetail({
    required this.id,
    required this.ticker,
    required this.title,
    required this.summary,
    required this.content,
    required this.url,
    required this.publishedAt,
    required this.personaComments,
  });

  /// JSON에서 NewsDetail 객체 생성
  factory NewsDetail.fromJson(Map<String, dynamic> json) {
    return NewsDetail(
      id: json['id']?.toString() ?? '',
      ticker: json['ticker']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      publishedAt: json['publishedAt']?.toString() ?? '',
      personaComments: (json['personaComments'] as List<dynamic>?)
              ?.map((e) => PersonaComment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// NewsDetail 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticker': ticker,
      'title': title,
      'summary': summary,
      'content': content,
      'url': url,
      'publishedAt': publishedAt,
      'personaComments': personaComments.map((e) => e.toJson()).toList(),
    };
  }

  /// 복사본 생성 (일부 필드만 변경할 때)
  NewsDetail copyWith({
    String? id,
    String? ticker,
    String? title,
    String? summary,
    String? content,
    String? url,
    String? publishedAt,
    List<PersonaComment>? personaComments,
  }) {
    return NewsDetail(
      id: id ?? this.id,
      ticker: ticker ?? this.ticker,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      url: url ?? this.url,
      publishedAt: publishedAt ?? this.publishedAt,
      personaComments: personaComments ?? this.personaComments,
    );
  }
}

/// 페르소나 댓글 모델
class PersonaComment {
  final String personaCode;
  final String personaName;
  final String comment;

  PersonaComment({
    required this.personaCode,
    required this.personaName,
    required this.comment,
  });

  /// JSON에서 PersonaComment 객체 생성
  factory PersonaComment.fromJson(Map<String, dynamic> json) {
    return PersonaComment(
      personaCode: json['personaCode']?.toString() ?? '',
      personaName: json['personaName']?.toString() ?? '',
      comment: json['comment']?.toString() ?? '',
    );
  }

  /// PersonaComment 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'personaCode': personaCode,
      'personaName': personaName,
      'comment': comment,
    };
  }

  /// 복사본 생성 (일부 필드만 변경할 때)
  PersonaComment copyWith({
    String? personaCode,
    String? personaName,
    String? comment,
  }) {
    return PersonaComment(
      personaCode: personaCode ?? this.personaCode,
      personaName: personaName ?? this.personaName,
      comment: comment ?? this.comment,
    );
  }
}
