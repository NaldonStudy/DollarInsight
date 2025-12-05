/// 기업 정보 모델
class CompanyInfo {
  final String id;
  final String name;
  final String description;
  final String? logoUrl;
  final String? homepage;
  final String? ceo;
  final String? foundedYear;
  final String? listingDate;

  CompanyInfo({
    required this.id,
    required this.name,
    required this.description,
    this.logoUrl,
    this.homepage,
    this.ceo,
    this.foundedYear,
    this.listingDate,
  });

  /// JSON에서 CompanyInfo 객체 생성
  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    return CompanyInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      logoUrl: json['logoUrl']?.toString(),
      homepage: json['homepage']?.toString(),
      ceo: json['ceo']?.toString(),
      foundedYear: json['foundedYear']?.toString(),
      listingDate: json['listingDate']?.toString(),
    );
  }

  /// CompanyInfo 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logoUrl': logoUrl,
      'homepage': homepage,
      'ceo': ceo,
      'foundedYear': foundedYear,
      'listingDate': listingDate,
    };
  }

  /// 복사본 생성 (일부 필드만 변경할 때)
  CompanyInfo copyWith({
    String? id,
    String? name,
    String? description,
    String? logoUrl,
    String? homepage,
    String? ceo,
    String? foundedYear,
    String? listingDate,
  }) {
    return CompanyInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      homepage: homepage ?? this.homepage,
      ceo: ceo ?? this.ceo,
      foundedYear: foundedYear ?? this.foundedYear,
      listingDate: listingDate ?? this.listingDate,
    );
  }
}
