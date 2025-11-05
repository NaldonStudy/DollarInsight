/// 관심 산업 및 기업 매핑 데이터

class CompanyData {
  final String name;
  final String logoPath;
  final String industry;

  const CompanyData({
    required this.name,
    required this.logoPath,
    required this.industry,
  });
}

/// 산업별 대표 한국 기업 매핑
class WatchlistData {
  /// 12개의 산업 목록
  static const List<String> industries = [
    '기술',
    '커머스',
    '항공',
    '자동차',
    '엔터',
    '결제',
    '산업/물류',
    '리테일',
    '금융(은행)',
    '금융(IB)',
    '보험',
    '소비재',
  ];

  /// 12개의 대표 한국 기업 데이터
  static const List<CompanyData> companies = [
    CompanyData(
      name: '삼성전자',
      logoPath: 'assets/images/koreacompany/samsung.png',
      industry: '기술',
    ),
    CompanyData(
      name: '네이버',
      logoPath: 'assets/images/koreacompany/naver.png',
      industry: '커머스',
    ),
    CompanyData(
      name: '대한항공',
      logoPath: 'assets/images/koreacompany/koreaair.png',
      industry: '항공',
    ),
    CompanyData(
      name: '기아',
      logoPath: 'assets/images/koreacompany/kia.png',
      industry: '자동차',
    ),
    CompanyData(
      name: '하이브',
      logoPath: 'assets/images/koreacompany/hybe.png',
      industry: '엔터',
    ),
    CompanyData(
      name: 'KG이니시스',
      logoPath: 'assets/images/koreacompany/kg.png',
      industry: '결제',
    ),
    CompanyData(
      name: 'CJ대한통운',
      logoPath: 'assets/images/koreacompany/cjdaehan.png',
      industry: '산업/물류',
    ),
    CompanyData(
      name: '이마트',
      logoPath: 'assets/images/koreacompany/emart.png',
      industry: '리테일',
    ),
    CompanyData(
      name: 'KB금융',
      logoPath: 'assets/images/koreacompany/kb.png',
      industry: '금융(은행)',
    ),
    CompanyData(
      name: '미래에셋',
      logoPath: 'assets/images/koreacompany/miraeesset.png',
      industry: '금융(IB)',
    ),
    CompanyData(
      name: '삼성생명',
      logoPath: 'assets/images/koreacompany/samsung.png', // 삼성생명 로고가 없으면 삼성 로고 재사용
      industry: '보험',
    ),
    CompanyData(
      name: '롯데칠성음료',
      logoPath: 'assets/images/koreacompany/lottechilsung.png',
      industry: '소비재',
    ),
  ];

  /// 특정 산업의 대표 기업 조회
  static List<CompanyData> getCompaniesByIndustries(Set<String> selectedIndustries) {
    return companies
        .where((company) => selectedIndustries.contains(company.industry))
        .toList();
  }

  /// 모든 기업 조회 (산업 선택 없이 전체 표시용)
  static List<CompanyData> getAllCompanies() {
    return companies;
  }
}

/// 미국 기업 데이터
class USCompanyData {
  final String name;
  final String logoPath;
  final String category;

  const USCompanyData({
    required this.name,
    required this.logoPath,
    required this.category,
  });
}

/// 카테고리별 미국 기업 추천 데이터 (더미)
class USWatchlistData {
  /// 기술주 카테고리 미국 기업 12개
  static const List<USCompanyData> techStocks = [
    USCompanyData(
      name: '애플',
      logoPath: 'assets/images/company/apple.png', // 없음 - 추가 필요
      category: '기술',
    ),
    USCompanyData(
      name: '마이크로소프트',
      logoPath: 'assets/images/company/microsoft.png', // 없음 - 추가 필요
      category: '기술',
    ),
    USCompanyData(
      name: '구글',
      logoPath: 'assets/images/company/alphabeta.png',
      category: '기술',
    ),
    USCompanyData(
      name: '아마존',
      logoPath: 'assets/images/company/amazon.png',
      category: '기술',
    ),
    USCompanyData(
      name: '메타',
      logoPath: 'assets/images/company/meta.png', // 없음 - 추가 필요
      category: '기술',
    ),
    USCompanyData(
      name: '엔비디아',
      logoPath: 'assets/images/company/nvidia.png', // 없음 - 추가 필요
      category: '기술',
    ),
    USCompanyData(
      name: 'AMD',
      logoPath: 'assets/images/company/amd.png',
      category: '기술',
    ),
    USCompanyData(
      name: '인텔',
      logoPath: 'assets/images/company/intel.png',
      category: '기술',
    ),
    USCompanyData(
      name: 'TSMC',
      logoPath: 'assets/images/company/tsmc.png',
      category: '기술',
    ),
    USCompanyData(
      name: 'ASML',
      logoPath: 'assets/images/company/asml.png',
      category: '기술',
    ),
    USCompanyData(
      name: '어도비',
      logoPath: 'assets/images/company/adobe.png',
      category: '기술',
    ),
    USCompanyData(
      name: '오라클',
      logoPath: 'assets/images/company/oracle.png',
      category: '기술',
    ),
  ];

  /// 카테고리별 미국 기업 조회 (현재는 기술주만)
  static List<USCompanyData> getCompaniesByCategory(String category) {
    if (category == '기술') {
      return techStocks;
    }
    // TODO: 다른 카테고리 추가 (커머스, 항공, 자동차 등)
    return techStocks; // 기본값
  }
}
