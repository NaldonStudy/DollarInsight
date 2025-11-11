import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// 주가 차트 위젯
/// 일/주/월봉을 선택할 수 있는 꺾은선 그래프
/// Trackball을 통해 데이터 포인트 상세 정보 표시
class StockPriceChart extends StatefulWidget {
  const StockPriceChart({super.key});

  @override
  State<StockPriceChart> createState() => _StockPriceChartState();
}

class _StockPriceChartState extends State<StockPriceChart> {
  // 더미 데이터 - 일봉 30일 (상승하는 추세)
  final List<FlSpot> dailyData = [
    const FlSpot(0, 275000),
    const FlSpot(1, 277000),
    const FlSpot(2, 279000),
    const FlSpot(3, 278500),
    const FlSpot(4, 281000),
    const FlSpot(5, 283000),
    const FlSpot(6, 285000),
    const FlSpot(7, 287000),
    const FlSpot(8, 286500),
    const FlSpot(9, 289000),
    const FlSpot(10, 291000),
    const FlSpot(11, 290000),
    const FlSpot(12, 292000),
    const FlSpot(13, 294000),
    const FlSpot(14, 293500),
    const FlSpot(15, 295000),
    const FlSpot(16, 297000),
    const FlSpot(17, 296500),
    const FlSpot(18, 298000),
    const FlSpot(19, 300000),
    const FlSpot(20, 299500),
    const FlSpot(21, 301000),
    const FlSpot(22, 303000),
    const FlSpot(23, 302500),
    const FlSpot(24, 304000),
    const FlSpot(25, 306000),
    const FlSpot(26, 305500),
    const FlSpot(27, 307000),
    const FlSpot(28, 309000),
    const FlSpot(29, 310000),
  ];

  // 최저/최고치 계산
  double get minPrice => dailyData.map((e) => e.y).reduce((a, b) => a < b ? a : b);
  double get maxPrice => dailyData.map((e) => e.y).reduce((a, b) => a > b ? a : b);

  // 최저/최고 인덱스 찾기
  int get minPriceIndex => dailyData.indexWhere((spot) => spot.y == minPrice);
  int get maxPriceIndex => dailyData.indexWhere((spot) => spot.y == maxPrice);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 최저/최고치 표시
        _buildPriceInfo(),
        const SizedBox(height: 16),
        // 차트
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 16, top: 8),
            child: LineChart(
              _buildChartData(),
            ),
          ),
        ),
      ],
    );
  }

  /// 최저/최고치 정보 표시
  Widget _buildPriceInfo() {
    return Row(
      children: [
        _buildPriceLabel('최저', minPrice, const Color(0xFF2196F3)),
        const SizedBox(width: 16),
        _buildPriceLabel('최고', maxPrice, const Color(0xFFFF5252)),
      ],
    );
  }

  /// 개별 가격 레이블
  Widget _buildPriceLabel(String label, double price, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label ',
          style: const TextStyle(
            color: Color(0xFF757575),
            fontSize: 12,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '${price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  /// 차트 데이터 구성
  LineChartData _buildChartData() {
    return LineChartData(
      // 그리드 설정 (보조선 제거)
      gridData: const FlGridData(
        show: false,
      ),
      // 터치 설정 (Trackball)
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => Colors.black87,
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((spot) {
              final price = spot.y.toInt().toString().replaceAllMapped(
                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                    (Match m) => '${m[1]},',
                  );

              // 날짜 계산 (오늘부터 역산)
              final daysAgo = spot.x.toInt();
              final date = DateTime.now().subtract(Duration(days: 29 - daysAgo));
              final dateString = '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

              return LineTooltipItem(
                '$dateString\n₩$price',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList();
          },
        ),
        getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
          return spotIndexes.map((index) {
            return TouchedSpotIndicatorData(
              FlLine(
                color: Colors.black54,
                strokeWidth: 2,
                dashArray: [5, 5],
              ),
              FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: const Color(0xFF4CAF50),
                  );
                },
              ),
            );
          }).toList();
        },
      ),
      // 타이틀 설정
      titlesData: FlTitlesData(
        show: true,
        // 왼쪽 타이틀 (가격 표시 제거)
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        // 하단 타이틀 (10일 단위만 표시: 30, 20, 10)
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();

              if (index >= 0 && index < dailyData.length) {
                String text;
                if (index == 0) {
                  text = '30';
                } else if (index == 10) {
                  text = '20';
                } else if (index == 20) {
                  text = '10';
                } else {
                  text = '-';
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Color(0xFF757575),
                      fontSize: 10,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        // 상단, 오른쪽 타이틀 숨기기
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      // 테두리 설정
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: const Color(0xFFE0E0E0), width: 1),
          left: BorderSide(color: const Color(0xFFE0E0E0), width: 1),
        ),
      ),
      // 최소/최대 X, Y 값 설정
      minX: 0,
      maxX: (dailyData.length - 1).toDouble(),
      minY: minPrice - 2000,
      maxY: maxPrice + 2000,
      // 선 데이터
      lineBarsData: [
        LineChartBarData(
          spots: dailyData,
          isCurved: true,
          curveSmoothness: 0.3,
          color: const Color(0xFF4CAF50),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            checkToShowDot: (spot, barData) {
              // 최고점과 최저점에만 dot 표시
              final index = spot.x.toInt();
              return index == minPriceIndex || index == maxPriceIndex;
            },
            getDotPainter: (spot, percent, barData, index) {
              // 최고점은 빨간색, 최저점은 파란색
              final isMaxPrice = spot.x.toInt() == maxPriceIndex;
              final dotColor = isMaxPrice ? const Color(0xFFFF5252) : const Color(0xFF2196F3);

              return FlDotCirclePainter(
                radius: 5,
                color: dotColor,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: false,
          ),
        ),
      ],
    );
  }
}
