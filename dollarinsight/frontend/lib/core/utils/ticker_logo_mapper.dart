/// Ticker 심볼과 로고 이미지 경로를 매핑하는 유틸리티
class TickerLogoMapper {
  /// Ticker를 받아서 로고 경로를 반환
  ///
  /// [ticker]: 종목 심볼 (예: "AAPL", "MSFT")
  ///
  /// Returns: 로고 이미지 경로 또는 빈 문자열 (로고 없을 시)
  static String getLogoPath(String ticker) {
    final upperTicker = ticker.toUpperCase();
    return _tickerLogoMap[upperTicker] ?? '';
  }

  /// Ticker에 대응하는 로고가 있는지 확인
  ///
  /// [ticker]: 종목 심볼
  ///
  /// Returns: 로고 존재 여부
  static bool hasLogo(String ticker) {
    return _tickerLogoMap.containsKey(ticker.toUpperCase());
  }

  /// Ticker -> 로고 경로 매핑 맵
  static const Map<String, String> _tickerLogoMap = {
    // 기술주
    'AAPL': 'assets/images/company/apple.webp',
    'MSFT': 'assets/images/company/microsoft.webp',
    'GOOGL': 'assets/images/company/alphabeta.webp',
    'GOOG': 'assets/images/company/alphabeta.webp', // 구글 A, C 클래스
    'AMZN': 'assets/images/company/amazon.webp',
    'META': 'assets/images/company/meta.webp',
    'NVDA': 'assets/images/company/nvidia.webp',
    'AMD': 'assets/images/company/amd.webp',
    'INTC': 'assets/images/company/intel.webp',
    'TSM': 'assets/images/company/tsmc.webp',
    'ASML': 'assets/images/company/asml.webp',
    'ADBE': 'assets/images/company/adobe.webp',
    'ORCL': 'assets/images/company/oracle.webp',

    // 커머스
    'CPNG': 'assets/images/company/coupang.webp',
    'BABA': 'assets/images/company/alibaba.webp',

    // 자동차
    'TSLA': 'assets/images/company/tesla.webp',

    // 항공
    'BA': 'assets/images/company/boing.webp',
    'DAL': 'assets/images/company/delta.webp',

    // 소비재
    'NKE': 'assets/images/company/nike.webp',
    'SBUX': 'assets/images/company/starbucks.webp',
    'KO': 'assets/images/company/ko.webp',
    'PEP': 'assets/images/company/pepsi.webp',
    'DIS': 'assets/images/company/disney.webp',
    'WMT': 'assets/images/company/wallmart.webp',
    'COST': 'assets/images/company/cstco.webp',
    'SONY': 'assets/images/company/sony.webp',
    'NFLX': 'assets/images/company/netflix.webp',
    'MCD' : 'assets/images/company/mcd.webp',

    // 금융
    'JPM': 'assets/images/company/jpmorgan.webp',
    'GS': 'assets/images/company/goldmansocks.webp',
    'BAC': 'assets/images/company/bankofamerica.webp',
    'AIG': 'assets/images/company/aig.webp',
    'V': 'assets/images/company/visa.webp',
    'PYPL': 'assets/images/company/paypal.webp',
    'MA': 'assets/images/company/ma.webp',

    // 물류
    'FDX': 'assets/images/company/fedex.webp',
    'UBER': 'assets/images/company/uber.webp',

    // 기타
    'PLTR': 'assets/images/company/palanteer.webp',

    // ETF
    'GDX': 'assets/images/company/gdx.webp',
    'XLY': 'assets/images/company/xly.webp',

    // Index ETF
    'VOO': 'assets/images/company/1.voo.webp',
    'SPY': 'assets/images/company/2.spy.webp',
    'VTI': 'assets/images/company/3.vti.webp',
    'QQQ': 'assets/images/company/4.qqq.webp',
    'QQQM': 'assets/images/company/5.qqqm.webp',
    'SCHD': 'assets/images/company/6.schd.webp',
    'SOXX': 'assets/images/company/7.soxx.webp',
    'TQQQ': 'assets/images/company/8.tqqq.webp',
    'SMH': 'assets/images/company/9.smh.webp',
    'ITA': 'assets/images/company/10.ita.webp',
    'ICLN': 'assets/images/company/11.icln.webp',
    'XLF': 'assets/images/company/12.xlf.webp',
    'XLP': 'assets/images/company/13.xlp.webp',

  };

  /// 등록된 전체 ticker 목록
  static List<String> get allTickers => _tickerLogoMap.keys.toList();

  /// 등록된 ticker 개수
  static int get count => _tickerLogoMap.length;
}
