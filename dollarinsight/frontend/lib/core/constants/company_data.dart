import '../../data/models/company_model.dart';
import '../utils/ticker_logo_mapper.dart';


final Map<String, CompanyInfo> companyDataMap = {
  // ==================== 1. 엔비디아 (NVDA) ====================
  'NVDA': CompanyInfo(
    id: 'NVDA',
    name: 'NVIDIA',
    description: '그래픽 프로세서 기술을 제공하는 세계적인 반도체 기업으로서, 컴퓨터, 게임기 등에 들어가는 GPU 개발 및 판매',
    logoUrl: 'assets/images/company/nvidia.webp',
    homepage: 'http://www.nvidia.com',
    ceo: 'Jen Hsun Huang',
    foundedYear: '1993년',
    listingDate: '1999년 1월 22일',
  ),

  // ==================== 2. Apple (AAPL) ====================
  'AAPL': CompanyInfo(
    id: 'AAPL',
    name: 'Apple',
    description: '아이폰·아이패드·맥 등 하드웨어와 iOS, 앱스토어 생태계를 보유한 글로벌 소비자 기술 기업',
    logoUrl: 'assets/images/company/apple.webp',
    homepage: 'https://www.apple.com/',
    ceo: 'Timothy Donald Cook',
    foundedYear: '1976년',
    listingDate: '1980년 12월 12일',
  ),

  // ==================== 3. Microsoft (MSFT) ====================
  'MSFT': CompanyInfo(
    id: 'MSFT',
    name: 'Microsoft',
    description: '윈도우 운영체제와 오피스, 클라우드 플랫폼 애저(Azure)를 제공하는 대표적인 글로벌 소프트웨어·클라우드 기업',
    logoUrl: 'assets/images/company/microsoft.webp',
    homepage: 'https://www.microsoft.com/ko-kr/',
    ceo: 'Satya Nadella',
    foundedYear: '1975년',
    listingDate: '1986년 3월 13일',
  ),

  // ==================== 4. Alphabet (GOOGL) ====================
  'GOOGL': CompanyInfo(
    id: 'GOOGL',
    name: 'Alphabet',
    description: '구글 검색, 유튜브, 안드로이드 등 다양한 인터넷 서비스를 보유한 알파벳의 A클래스 보통주',
    logoUrl: 'assets/images/company/alphabeta.webp',
    homepage: 'https://www.abc.xyz/',
    ceo: 'Sundar Pichai',
    foundedYear: '2015년',
    listingDate: '2004년 8월 19일',
  ),

  // ==================== 5. Alphabet C (GOOG) ====================
  'GOOG': CompanyInfo(
    id: 'GOOG',
    name: 'Alphabet',
    description: '구글 검색, 유튜브, 안드로이드 등 다양한 인터넷 서비스를 보유한 알파벳의 C클래스 보통주',
    logoUrl: 'assets/images/company/alphabeta.webp',
    homepage: 'https://www.abc.xyz/',
    ceo: 'Sundar Pichai',
    foundedYear: '2015년',
    listingDate: '2004년 8월 19일',
  ),

  // ==================== 6. Amazon (AMZN) ====================
  'AMZN': CompanyInfo(
    id: 'AMZN',
    name: 'Amazon',
    description: '전자상거래와 아마존 웹 서비스(AWS) 클라우드를 중심으로 성장한 글로벌 이커머스·테크 기업',
    logoUrl: 'assets/images/company/amazon.webp',
    homepage: 'https://www.aboutamazon.com/',
    ceo: 'Andrew R. Jassy',
    foundedYear: '1994년',
    listingDate: '1997년 5월 15일',
  ),

  // ==================== 7. Meta (META) ====================
  'META': CompanyInfo(
    id: 'META',
    name: 'Meta Platforms',
    description: '페이스북, 인스타그램, 왓츠앱을 운영하며 소셜 네트워크와 디지털 광고, 메타버스를 중심으로 성장하는 기업',
    logoUrl: 'assets/images/company/meta.webp',
    homepage: 'https://www.meta.com/',
    ceo: 'Mark Elliot Zuckerberg',
    foundedYear: '2004년',
    listingDate: '2012년 5월 18일',
  ),

  // ==================== 8. AMD (AMD) ====================
  'AMD': CompanyInfo(
    id: 'AMD',
    name: 'AMD',
    description: 'CPU와 GPU, 데이터센터용 칩 등을 설계·판매하는 글로벌 반도체·고성능 컴퓨팅 기업',
    logoUrl: 'assets/images/company/amd.webp',
    homepage: 'https://www.amd.com/',
    ceo: 'Lisa T. Su',
    foundedYear: '1969년',
    listingDate: '2015년 1월 2일',
  ),

  // ==================== 9. Intel (INTC) ====================
  'INTC': CompanyInfo(
    id: 'INTC',
    name: 'Intel',
    description: 'PC·서버용 CPU를 중심으로 반도체를 설계·제조하는 전통적인 글로벌 종합 반도체 기업',
    logoUrl: 'assets/images/company/intel.webp',
    homepage: 'https://www.intel.co.kr/',
    ceo: 'Lip-Bu Tan',
    foundedYear: '1968년',
    listingDate: '1971년 10월 13일',
  ),

  // ==================== 10. TSMC (TSM) ====================
  'TSM': CompanyInfo(
    id: 'TSM',
    name: 'TSMC',
    description: '다양한 팹리스 업체의 칩을 수탁 생산하는 세계 최대 규모의 반도체 파운드리(위탁 생산) 기업',
    logoUrl: 'assets/images/company/tsmc.webp',
    homepage: 'https://www.tsmc.com/',
    ceo: 'Che Chia Wei',
    foundedYear: '1987년',
    listingDate: '1997년 10월 8일',
  ),

  // ==================== 11. ASML (ASML) ====================
  'ASML': CompanyInfo(
    id: 'ASML',
    name: 'ASML',
    description: '첨단 반도체 생산에 필요한 극자외선(EUV) 노광 장비를 독점 공급하는 네덜란드 기반의 장비 업체',
    logoUrl: 'assets/images/company/asml.webp',
    homepage: 'https://www.asml.com',
    ceo: 'Christophe D. Fouquet',
    foundedYear: '1984년',
    listingDate: '1995년 3월 15일',
  ),

  // ==================== 12. Adobe (ADBE) ====================
  'ADBE': CompanyInfo(
    id: 'ADBE',
    name: 'Adobe',
    description: '포토샵, 일러스트레이터, 프리미어 등 크리에이티브 소프트웨어와 디지털 미디어 솔루션을 제공하는 소프트웨어 기업',
    logoUrl: 'assets/images/company/adobe.webp',
    homepage: 'https://www.adobe.com',
    ceo: 'Shantanu Narayen',
    foundedYear: '1982년',
    listingDate: '1986년 8월 20일',
  ),

  // ==================== 13. Oracle (ORCL) ====================
  'ORCL': CompanyInfo(
    id: 'ORCL',
    name: 'Oracle',
    description: '데이터베이스, ERP 등 엔터프라이즈용 소프트웨어와 클라우드 인프라를 제공하는 기업용 IT 솔루션 회사',
    logoUrl: 'assets/images/company/oracle.webp',
    homepage: 'https://www.oracle.com/',
    ceo: 'Clayton Magouyrk / Michael Sicilia',
    foundedYear: '1977년',
    listingDate: '1986년 3월 12일',
  ),

  // ==================== 14. Coupang (CPNG) ====================
  'CPNG': CompanyInfo(
    id: 'CPNG',
    name: 'Coupang',
    description: '로켓배송 등 빠른 물류·배송을 강점으로 하는 한국 기반 이커머스 플랫폼 기업',
    logoUrl: 'assets/images/company/coupang.webp',
    homepage: 'https://www.aboutcoupang.com',
    ceo: 'Bom Kim',
    foundedYear: '2010년',
    listingDate: '2021년 3월 10일',
  ),

  // ==================== 15. Alibaba (BABA) ====================
  'BABA': CompanyInfo(
    id: 'BABA',
    name: 'Alibaba',
    description: '타오바오·티몰 등 중국 전자상거래 플랫폼과 클라우드, 디지털 결제를 아우르는 종합 테크·커머스 기업',
    logoUrl: 'assets/images/company/alibaba.webp',
    homepage: 'https://www.alibabagroup.com',
    ceo: 'Yong Ming Eddie Wu',
    foundedYear: '1999년',
    listingDate: '2014년 9월 15일',
  ),

  // ==================== 16. Tesla (TSLA) ====================
  'TSLA': CompanyInfo(
    id: 'TSLA',
    name: 'Tesla',
    description: '전기차와 배터리, 에너지 저장장치, 자율주행 소프트웨어를 개발·판매하는 글로벌 전기차 선도 기업',
    logoUrl: 'assets/images/company/tesla.webp',
    homepage: 'https://www.tesla.com',
    ceo: 'Elon Reeve Musk',
    foundedYear: '2003년',
    listingDate: '2010년 6월 29일',
  ),

  // ==================== 17. Boeing (BA) ====================
  'BA': CompanyInfo(
    id: 'BA',
    name: 'Boeing',
    description: '상업용 여객기와 군용기, 우주 관련 장비를 제조하는 미국의 대표적인 항공우주·방산 기업',
    logoUrl: 'assets/images/company/boing.webp',
    homepage: 'https://www.boeing.com/',
    ceo: 'Robert Kelly Ortberg',
    foundedYear: '1916년',
    listingDate: '1952년 5월 23일',
  ),

  // ==================== 18. Delta Air Lines (DAL) ====================
  'DAL': CompanyInfo(
    id: 'DAL',
    name: 'Delta Air Lines',
    description: '미국을 중심으로 전 세계 노선을 운영하는 대형 항공사로, 여객·화물 운송 서비스를 제공합니다.',
    logoUrl: 'assets/images/company/delta.webp',
    homepage: 'https://ko.delta.com/',
    ceo: 'Edward Herman Bastian',
    foundedYear: '1928년',
    listingDate: '1967년 7월 3일',
  ),

  // ==================== 19. Nike (NKE) ====================
  'NKE': CompanyInfo(
    id: 'NKE',
    name: 'Nike',
    description: '스포츠 의류·신발·용품을 디자인·판매하는 글로벌 스포츠 브랜드 기업',
    logoUrl: 'assets/images/company/nike.webp',
    homepage: 'https://www.nike.com/',
    ceo: 'Elliott J. Hill',
    foundedYear: '1964년',
    listingDate: '1990년 10월 17일',
  ),

  // ==================== 20. Starbucks (SBUX) ====================
  'SBUX': CompanyInfo(
    id: 'SBUX',
    name: 'Starbucks',
    description: '전 세계에 커피 전문 매장을 운영하며 커피·음료·푸드를 판매하는 글로벌 프랜차이즈 기업',
    logoUrl: 'assets/images/company/starbucks.webp',
    homepage: 'https://www.starbucks.com/',
    ceo: 'Brian R. Niccol',
    foundedYear: '1985년',
    listingDate: '1992년 6월 26일',
  ),

  // ==================== 21. Coca-Cola (KO) ====================
  'KO': CompanyInfo(
    id: 'KO',
    name: 'Coca-Cola',
    description: '코카콜라를 비롯한 탄산음료·주스·생수 등 다양한 음료 브랜드를 보유한 글로벌 음료 회사',
    logoUrl: 'assets/images/company/ko.webp',
    homepage: 'https://www.coca-colacompany.com',
    ceo: 'James Quincey',
    foundedYear: '1886년',
    listingDate: '1924년 9월 26일',
  ),

  // ==================== 22. PepsiCo (PEP) ====================
  'PEP': CompanyInfo(
    id: 'PEP',
    name: 'PepsiCo',
    description: '펩시콜라와 각종 스낵 브랜드(도리토스 등)를 보유한 글로벌 음료·식품 기업',
    logoUrl: 'assets/images/company/pepsi.webp',
    homepage: 'https://www.pepsico.com/',
    ceo: 'Ramon Luis Laguarta',
    foundedYear: '1965년',
    listingDate: '2017년 12월 20일',
  ),

  // ==================== 23. Disney (DIS) ====================
  'DIS': CompanyInfo(
    id: 'DIS',
    name: 'Disney',
    description: '디즈니·픽사·마블·스타워즈 IP를 기반으로 콘텐츠, 테마파크, 스트리밍(디즈니+) 사업을 영위하는 엔터테인먼트 기업',
    logoUrl: 'assets/images/company/disney.webp',
    homepage: 'https://thewaltdisneycompany.com/',
    ceo: 'Robert A. Iger',
    foundedYear: '1923년',
    listingDate: '1962년 1월 2일',
  ),

  // ==================== 24. Walmart (WMT) ====================
  'WMT': CompanyInfo(
    id: 'WMT',
    name: 'Walmart',
    description: '대형 할인점과 마트 체인을 운영하며 온·오프라인 유통을 결합한 글로벌 리테일 기업',
    logoUrl: 'assets/images/company/wallmart.webp',
    homepage: 'http://www.corporate.walmart.com/',
    ceo: 'C. Douglas McMillon',
    foundedYear: '1962년',
    listingDate: '1970년 10월 1일',
  ),

  // ==================== 25. Costco (COST) ====================
  'COST': CompanyInfo(
    id: 'COST',
    name: 'Costco',
    description: '회원제 창고형 매장을 통해 대량 구매 중심의 유통 모델을 운영하는 글로벌 도매·소매 유통 기업',
    logoUrl: 'assets/images/company/cstco.webp',
    homepage: 'https://www.costco.com/',
    ceo: 'Roland M. Vachris',
    foundedYear: '1983년',
    listingDate: '1985년 11월 27일',
  ),

  // ==================== 26. Sony (SONY) ====================
  'SONY': CompanyInfo(
    id: 'SONY',
    name: 'Sony',
    description: '게임(플레이스테이션), 이미지 센서, 가전, 음악·영화 등 다양한 사업을 영위하는 일본의 종합 엔터·전자 기업',
    logoUrl: 'assets/images/company/sony.webp',
    homepage: 'https://www.sony.com',
    ceo: 'Hiroki Totoki',
    foundedYear: '1946년',
    listingDate: '2021년 4월 1일',
  ),

  // ==================== 27. Netflix (NFLX) ====================
  'NFLX': CompanyInfo(
    id: 'NFLX',
    name: 'Netflix',
    description: '구독형 스트리밍 서비스를 통해 영화·드라마·오리지널 콘텐츠를 제공하는 글로벌 OTT 플랫폼 기업',
    logoUrl: 'assets/images/company/netflix.webp',
    homepage: 'https://www.netflix.com',
    ceo: 'Gregory K. Peters / Theodore A. Sarandos',
    foundedYear: '1997년',
    listingDate: '2002년 5월 23일',
  ),

  // ==================== 28. McDonald's (MCD) ====================
  'MCD': CompanyInfo(
    id: 'MCD',
    name: 'McDonald\'s',
    description: '전 세계에 매장을 운영하며 햄버거·패스트푸드를 판매하는 대표적인 글로벌 프랜차이즈 외식 기업',
    logoUrl: 'assets/images/company/mcd.webp',
    homepage: 'https://corporate.mcdonalds.com',
    ceo: 'Christopher J. Kempczinski',
    foundedYear: '1955년',
    listingDate: '1966년 7월 5일',
  ),

  // ==================== 29. JPMorgan Chase (JPM) ====================
  'JPM': CompanyInfo(
    id: 'JPM',
    name: 'JPMorgan Chase',
    description: '투자은행, 자산관리, 상업은행 등 종합 금융 서비스를 제공하는 미국 최대 규모의 금융 그룹',
    logoUrl: 'assets/images/company/jpmorgan.webp',
    homepage: 'https://www.jpmorganchase.com/',
    ceo: 'James Dimon',
    foundedYear: '1799년',
    listingDate: '1969년 4월 1일',
  ),

  // ==================== 30. Goldman Sachs (GS) ====================
  'GS': CompanyInfo(
    id: 'GS',
    name: 'Goldman Sachs',
    description: '투자은행, 자산운용, 자문 등을 통해 기업·기관 투자자를 대상으로 금융 서비스를 제공하는 글로벌 IB',
    logoUrl: 'assets/images/company/goldmansocks.webp',
    homepage: 'https://www.goldmansachs.com/',
    ceo: 'David Michael Solomon',
    foundedYear: '1869년',
    listingDate: '1999년 5월 4일',
  ),

  // ==================== 31. Bank of America (BAC) ====================
  'BAC': CompanyInfo(
    id: 'BAC',
    name: 'Bank of America',
    description: '소매·기업금융, 자산관리 등 다양한 은행 서비스를 제공하는 미국 대형 상업은행 그룹',
    logoUrl: 'assets/images/company/bankofamerica.webp',
    homepage: 'https://www.bankofamerica.com/',
    ceo: 'Brian T. Moynihan',
    foundedYear: '1904년',
    listingDate: '1973년 1월 2일',
  ),

  // ==================== 32. AIG (AIG) ====================
  'AIG': CompanyInfo(
    id: 'AIG',
    name: 'AIG',
    description: '손해보험·생명보험 및 관련 금융 서비스를 제공하는 글로벌 보험·금융 회사',
    logoUrl: 'assets/images/company/aig.webp',
    homepage: 'https://www.aig.com/',
    ceo: 'Peter S. Zaffino',
    foundedYear: '1919년',
    listingDate: '1984년 10월 10일',
  ),

  // ==================== 33. Visa (V) ====================
  'V': CompanyInfo(
    id: 'V',
    name: 'Visa',
    description: '글로벌 결제 네트워크를 운영하며 신용·체크카드 결제 인프라를 제공하는 전자 결제 기업',
    logoUrl: 'assets/images/company/visa.webp',
    homepage: 'https://www.visa.com/en-us',
    ceo: 'Ryan McInerney',
    foundedYear: '1958년',
    listingDate: '2008년 3월 19일',
  ),

  // ==================== 34. PayPal (PYPL) ====================
  'PYPL': CompanyInfo(
    id: 'PYPL',
    name: 'PayPal',
    description: '온라인·모바일 결제를 지원하는 디지털 지갑 및 결제 플랫폼을 운영하는 핀테크 기업',
    logoUrl: 'assets/images/company/paypal.webp',
    homepage: 'https://www.paypal.com',
    ceo: 'James Alexander Chriss',
    foundedYear: '1998년',
    listingDate: '2015년 7월 21일',
  ),

  // ==================== 35. Mastercard (MA) ====================
  'MA': CompanyInfo(
    id: 'MA',
    name: 'Mastercard',
    description: '전 세계 카드 결제 네트워크를 운영하며 가맹점·은행을 연결하는 글로벌 전자 결제 기업',
    logoUrl: 'assets/images/company/ma.webp',
    homepage: 'https://www.mastercard.co.kr',
    ceo: 'Michael E. Miebach',
    foundedYear: '1966년',
    listingDate: '2006년 5월 25일',
  ),

  // ==================== 36. FedEx (FDX) ====================
  'FDX': CompanyInfo(
    id: 'FDX',
    name: 'FedEx',
    description: '국제 특송·택배·물류 서비스를 제공하는 글로벌 배송·물류 기업',
    logoUrl: 'assets/images/company/fedex.webp',
    homepage: 'https://www.fedex.com/',
    ceo: 'Rajesh Subramaniam',
    foundedYear: '1971년',
    listingDate: '1978년 4월 12일',
  ),

  // ==================== 37. Uber (UBER) ====================
  'UBER': CompanyInfo(
    id: 'UBER',
    name: 'Uber',
    description: '승차 공유(우버)와 음식 배달(우버이츠) 등 모빌리티·온디맨드 서비스를 제공하는 플랫폼 기업',
    logoUrl: 'assets/images/company/uber.webp',
    homepage: 'https://www.uber.com',
    ceo: 'Dara Khosrowshahi',
    foundedYear: '2009년',
    listingDate: '2019년 5월 9일',
  ),

  // ==================== 38. Palantir (PLTR) ====================
  'PLTR': CompanyInfo(
    id: 'PLTR',
    name: 'Palantir',
    description: '정부·기업 고객을 대상으로 대규모 데이터 분석·시각화 플랫폼을 제공하는 소프트웨어·데이터 분석 기업',
    logoUrl: 'assets/images/company/palanteer.webp',
    homepage: 'https://www.palantir.com/',
    ceo: 'Alexander Caedmon Karp',
    foundedYear: '2003년',
    listingDate: '2020년 9월 30일',
  ),
};

/// 특정 기업 ID로 데이터 조회 (ticker_logo_mapper를 통해 로고 자동 연결)
CompanyInfo? getCompanyData(String companyId) {
  final data = companyDataMap[companyId];
  if (data == null) return null;

  // ticker_logo_mapper에서 로고 경로 가져오기
  final logoPath = TickerLogoMapper.getLogoPath(companyId);

  // 로고 경로가 있으면 업데이트된 CompanyInfo 반환
  return data.copyWith(
    logoUrl: logoPath.isNotEmpty ? logoPath : data.logoUrl,
  );
}

/// 모든 기업 리스트 조회
List<CompanyInfo> getAllCompanies() {
  return companyDataMap.values.toList();
}

/// 기업 ID 리스트 조회
List<String> getCompanyIds() {
  return companyDataMap.keys.toList();
}