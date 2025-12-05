import '../../data/models/etf_model.dart';
import '../utils/ticker_logo_mapper.dart';


final Map<String, EtfInfo> etfDataMap = {
  // ==================== 1. VOO ====================
  'VOO': EtfInfo(
    id: 'VOO',
    name: 'VOO',

    description: 'S&P 500 지수 추종, 미국 대형주 대표 인덱스 ETF.',
    logoUrl: 'assets/images/company/1.voo.webp',
    top10HoldingsRatio: '38.7%',
    totalStocks: '507개',
    topHoldings: [
      EtfHolding(companyName: 'NVIDIA Corp.', ratio: '7.95%'),
      EtfHolding(companyName: 'Microsoft Corp.', ratio: '6.72%'),
      EtfHolding(companyName: 'Apple Inc.', ratio: '6.60%'),
      EtfHolding(companyName: 'Amazon.com Inc.', ratio: '3.72%'),
      EtfHolding(companyName: 'Meta Platforms Inc.', ratio: '2.78%'),
    ],
  ),

  // ==================== 2. SPY ====================
  'SPY': EtfInfo(
    id: 'SPY',
    name: 'SPY',
    description: 'S&P 500 지수를 추종하는 가장 오래된 대형 ETF.',
    logoUrl: 'assets/images/company/2.spy.webp',
    top10HoldingsRatio: '39.3%',
    totalStocks: '504개',
    topHoldings: [
      EtfHolding(companyName: 'NVIDIA Corp.', ratio: '7.93%'),
      EtfHolding(companyName: 'Apple Inc.', ratio: '7.04%'),
      EtfHolding(companyName: 'Microsoft Corp.', ratio: '6.51%'),
      EtfHolding(companyName: 'Amazon.com Inc.', ratio: '4.01%'),
      EtfHolding(companyName: 'Meta Platforms Inc.', ratio: '2.82%'),
    ],
  ),

  // ==================== 3. VTI ====================
  'VTI': EtfInfo(
    id: 'VTI',
    name: 'VTI',
    description: '미국 상장주식 거의 전부(대·중·소형)를 커버하는 토탈 마켓 인덱스 ETF.',
    logoUrl: 'assets/images/company/3.vti.webp',
    top10HoldingsRatio: '34.0%',
    totalStocks: '3,532개',
    topHoldings: [
      EtfHolding(companyName: 'NVIDIA Corp.', ratio: '6.70%'),
      EtfHolding(companyName: 'Microsoft Corp.', ratio: '5.99%'),
      EtfHolding(companyName: 'Apple Inc.', ratio: '5.88%'),
      EtfHolding(companyName: 'Amazon.com Inc.', ratio: '3.28%'),
      EtfHolding(companyName: 'Meta Platforms Inc.', ratio: '2.48%'),
    ],
  ),

  // ==================== 4. QQQ ====================
  'QQQ': EtfInfo(
    id: 'QQQ',
    name: 'QQQ',
    description: '나스닥 100 지수 추종, 대형 성장·기술주 중심 ETF.',
    logoUrl: 'assets/images/company/4.qqq.webp',
    top10HoldingsRatio: '53.0%',
    totalStocks: '102개',
    topHoldings: [
      EtfHolding(companyName: 'NVIDIA Corp.', ratio: '9.77%'),
      EtfHolding(companyName: 'Apple Inc.', ratio: '8.72%'),
      EtfHolding(companyName: 'Microsoft Corp.', ratio: '8.05%'),
      EtfHolding(companyName: 'Broadcom Inc.', ratio: '5.69%'),
      EtfHolding(companyName: 'Amazon.com Inc.', ratio: '5.45%'),
    ],
  ),

  // ==================== 5. QQQM ====================
  'QQQM': EtfInfo(
    id: 'QQQM',
    name: 'QQQM',
    description: 'QQQ와 같은 나스닥 100 추종, 보수가 더 낮은 장기투자용 ETF.',
    logoUrl: 'assets/images/company/5.qqqm.webp',
    top10HoldingsRatio: '52.9%',
    totalStocks: '107개',
    topHoldings: [
      EtfHolding(companyName: 'NVIDIA Corp.', ratio: '9.75%'),
      EtfHolding(companyName: 'Apple Inc.', ratio: '8.70%'),
      EtfHolding(companyName: 'Microsoft Corp.', ratio: '8.04%'),
      EtfHolding(companyName: 'Broadcom Inc.', ratio: '5.68%'),
      EtfHolding(companyName: 'Amazon.com Inc.', ratio: '5.44%'),
    ],
  ),

  // ==================== 6. SCHD ====================
  'SCHD': EtfInfo(
    id: 'SCHD',
    name: 'SCHD',
    description: '10년 이상 배당·재무지표 기준의 고배당 우량주 ETF.',
    logoUrl: 'assets/images/company/6.schd.webp',
    top10HoldingsRatio: '41.9%',
    totalStocks: '103개',
    topHoldings: [
      EtfHolding(companyName: 'Amgen Inc.', ratio: '4.77%'),
      EtfHolding(companyName: 'Cisco Systems Inc.', ratio: '4.61%'),
      EtfHolding(companyName: 'Merck & Co. Inc.', ratio: '4.45%'),
      EtfHolding(companyName: 'AbbVie Inc.', ratio: '4.42%'),
      EtfHolding(companyName: 'The Coca-Cola Co.', ratio: '4.15%'),
    ],
  ),

  // ==================== 7. SOXX ====================
  'SOXX': EtfInfo(
    id: 'SOXX',
    name: 'SOXX',
    description: '미국 상장 반도체 기업에 집중 투자하는 iShares 반도체 ETF.',
    logoUrl: 'assets/images/company/7.soxx.webp',
    top10HoldingsRatio: '60.7%',
    totalStocks: '34개',
    topHoldings: [
      EtfHolding(companyName: 'Advanced Micro Devices Inc.', ratio: '10.14%'),
      EtfHolding(companyName: 'Broadcom Inc.', ratio: '7.69%'),
      EtfHolding(companyName: 'NVIDIA Corp.', ratio: '7.29%'),
      EtfHolding(companyName: 'Micron Technology Inc.', ratio: '6.93%'),
      EtfHolding(companyName: 'Qualcomm Inc.', ratio: '5.40%'),
    ],
  ),

  // ==================== 8. TQQQ ====================
  'TQQQ': EtfInfo(
    id: 'TQQQ',
    name: 'TQQQ',
    description: '나스닥 100 일간 수익률의 3배를 목표로 하는 레버리지 ETF.',
    logoUrl: 'assets/images/company/8.tqqq.webp',
    top10HoldingsRatio: '237.6%',
    totalStocks: '125개',
    topHoldings: [
      EtfHolding(companyName: 'NVIDIA Corp.', ratio: '5.0%'),
      EtfHolding(companyName: 'Apple Inc.', ratio: '4.5%'),
      EtfHolding(companyName: 'Microsoft Corp.', ratio: '4.1%'),
      EtfHolding(companyName: 'Broadcom Inc.', ratio: '2.9%'),
      EtfHolding(companyName: 'Amazon.com Inc.', ratio: '2.8%'),
    ],
  ),

  // ==================== 9. SMH ====================
  'SMH': EtfInfo(
    id: 'SMH',
    name: 'SMH',
    description: '전세계(미국 상장) 반도체 대표 25개 기업에 집중 투자하는 VanEck 반도체 ETF.',
    logoUrl: 'assets/images/company/9.smh.webp',
    top10HoldingsRatio: '75.7%',
    totalStocks: '26개',
    topHoldings: [
      EtfHolding(companyName: 'NVIDIA Corp.', ratio: '18.30%'),
      EtfHolding(companyName: 'Taiwan Semiconductor Manufacturing Co.', ratio: '9.41%'),
      EtfHolding(companyName: 'Broadcom Inc.', ratio: '7.98%'),
      EtfHolding(companyName: 'Advanced Micro Devices Inc.', ratio: '6.75%'),
      EtfHolding(companyName: 'Micron Technology Inc.', ratio: '6.61%'),
    ],
  ),

  // ==================== 10. ITA ====================
  'ITA': EtfInfo(
    id: 'ITA',
    name: 'ITA',
    description: '미국 항공우주·방산 기업에 투자하는 iShares 항공우주/방산 ETF.',
    logoUrl: 'assets/images/company/10.ita.webp',
    top10HoldingsRatio: '74.0%',
    totalStocks: '39개',
    topHoldings: [
      EtfHolding(companyName: 'GE Aerospace', ratio: '21.0%'),
      EtfHolding(companyName: 'RTX Corp.', ratio: '16.0%'),
      EtfHolding(companyName: 'Boeing Co.', ratio: '7.0%'),
      EtfHolding(companyName: 'Howmet Aerospace Inc.', ratio: '4.6%'),
      EtfHolding(companyName: 'General Dynamics Corp.', ratio: '4.4%'),
    ],
  ),

  // ==================== 11. ICLN ====================
  'ICLN': EtfInfo(
    id: 'ICLN',
    name: 'ICLN',
    description: '전 세계 클린·재생에너지 기업에 투자하는 iShares 글로벌 클린에너지 ETF.',
    logoUrl: 'assets/images/company/11.icln.webp',
    top10HoldingsRatio: '52.5%',
    totalStocks: '128개',
    topHoldings: [
      EtfHolding(companyName: 'Bloom Energy Corp.', ratio: '9.5%'),
      EtfHolding(companyName: 'First Solar Inc.', ratio: '8.2%'),
      EtfHolding(companyName: 'Iberdrola SA', ratio: '6.2%'),
      EtfHolding(companyName: 'NextEra Energy', ratio: '6.1%'),
      EtfHolding(companyName: 'Vestas Wind Systems A/S', ratio: '5.5%'),
    ],
  ),

  // ==================== 12. XLF ====================
  'XLF': EtfInfo(
    id: 'XLF',
    name: 'XLF',
    description: 'S&P 500 금융 섹터에 투자하는 Financial Select Sector SPDR ETF.',
    logoUrl: 'assets/images/company/12.xlf.webp',
    top10HoldingsRatio: '57.2%',
    totalStocks: '72개',
    topHoldings: [
      EtfHolding(companyName: 'Berkshire Hathaway Inc.', ratio: '12.8%'),
      EtfHolding(companyName: 'JPMorgan Chase & Co.', ratio: '9.9%'),
      EtfHolding(companyName: 'Visa Inc.', ratio: '7.7%'),
      EtfHolding(companyName: 'Mastercard Inc.', ratio: '7.0%'),
      EtfHolding(companyName: 'Bank of America Corp.', ratio: '4.6%'),
    ],
  ),

  // ==================== 13. XLP ====================
  'XLP': EtfInfo(
    id: 'XLP',
    name: 'XLP',
    description: 'S&P 500 필수소비재 섹터에 투자하는 Consumer Staples Select Sector SPDR ETF.',
    logoUrl: 'assets/images/company/13.xlp.webp',
    top10HoldingsRatio: '61.7%',
    totalStocks: '39개',
    topHoldings: [
      EtfHolding(companyName: 'Procter & Gamble Co.', ratio: '15.13%'),
      EtfHolding(companyName: 'Costco Wholesale Corp.', ratio: '10.46%'),
      EtfHolding(companyName: 'Walmart Inc.', ratio: '9.21%'),
      EtfHolding(companyName: 'PepsiCo Inc.', ratio: '8.47%'),
      EtfHolding(companyName: 'Mondelez International Inc.', ratio: '4.36%'),
    ],
  ),

  // ==================== 14. GDX ====================
  'GDX': EtfInfo(
    id: 'GDX',
    name: 'GDX',
    description: '전 세계 금광·골드 마이너 기업에 투자하는 VanEck Gold Miners ETF.',
    logoUrl: 'assets/images/company/gdx.webp',
    top10HoldingsRatio: '53.4%',
    totalStocks: '49개',
    topHoldings: [
      EtfHolding(companyName: 'Newmont Corp.', ratio: '8.3%'),
      EtfHolding(companyName: 'Barrick Gold Corp.', ratio: '7.0%'),
      EtfHolding(companyName: 'Franco-Nevada Corp.', ratio: '6.4%'),
      EtfHolding(companyName: 'Agnico Eagle Mines Ltd.', ratio: '6.4%'),
      EtfHolding(companyName: 'Wheaton Precious Metals Corp.', ratio: '5.3%'),
    ],
  ),

  // ==================== 15. XLY ====================
  'XLY': EtfInfo(
    id: 'XLY',
    name: 'XLY',
    description: 'S&P 500 경기소비재 섹터에 투자하는 Consumer Discretionary Select Sector SPDR ETF.',
    logoUrl: 'assets/images/company/xly.webp',
    top10HoldingsRatio: '71.2%',
    totalStocks: '52개',
    topHoldings: [
      EtfHolding(companyName: 'Amazon.com Inc.', ratio: '22.0%'),
      EtfHolding(companyName: 'Tesla Inc.', ratio: '12.0%'),
      EtfHolding(companyName: 'The Home Depot Inc.', ratio: '9.0%'),
      EtfHolding(companyName: 'McDonald\'s Corp.', ratio: '4.0%'),
      EtfHolding(companyName: 'Booking Holdings Inc.', ratio: '4.0%'),
    ],
  ),
};

/// 특정 ETF ID로 데이터 조회 (ticker_logo_mapper를 통해 로고 자동 연결)
EtfInfo? getEtfData(String etfId) {
  final data = etfDataMap[etfId];
  if (data == null) return null;

  // ticker_logo_mapper에서 로고 경로 가져오기
  final logoPath = TickerLogoMapper.getLogoPath(etfId);

  // 로고 경로가 있으면 업데이트된 EtfInfo 반환
  return data.copyWith(
    logoUrl: logoPath.isNotEmpty ? logoPath : data.logoUrl,
  );
}

/// 모든 ETF 리스트 조회
List<EtfInfo> getAllEtfs() {
  return etfDataMap.values.toList();
}

/// ETF ID 리스트 조회
List<String> getEtfIds() {
  return etfDataMap.keys.toList();
}