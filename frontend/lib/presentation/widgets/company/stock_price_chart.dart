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
  // 선택된 차트 타입 (일봉, 주봉, 월봉)
  String selectedPeriod = '1일';

  // 더미 데이터 - 일봉 (상승하는 추세)
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
  ];

  // 더미 데이터 - 주봉
  final List<FlSpot> weeklyData = [
    const FlSpot(0, 275000),
    const FlSpot(1, 280000),
    const FlSpot(2, 283000),
    const FlSpot(3, 287000),
    const FlSpot(4, 291000),
  ];

  // 더미 데이터 - 월봉
  final List<FlSpot> monthlyData = [
    const FlSpot(0, 275000),
    const FlSpot(1, 285000),
    const FlSpot(2, 291000),
  ];

  // 현재 선택된 데이터 가져오기
  List<FlSpot> get currentData {
    switch (selectedPeriod) {
      case '1주':
        return weeklyData;
      case '1월':
        return monthlyData;
      default:
        return dailyData;
    }
  }

  // 최저/최고치 계산
  double get minPrice => currentData.map((e) => e.y).reduce((a, b) => a < b ? a : b);
  double get maxPrice => currentData.map((e) => e.y).reduce((a, b) => a > b ? a : b);

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
        const SizedBox(height: 16),
        // 기간 선택 탭
        _buildPeriodSelector(),
      ],
    );
  }

  /// 기간 선택 탭 (일봉/주봉/월봉)
  Widget _buildPeriodSelector() {
    return Row(
      children: ['일봉', '주봉', '월봉'].map((period) {
        final isSelected = selectedPeriod == period;
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedPeriod = period;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : Colors.white,
              border: Border.all(
                color: isSelected ? Colors.black : const Color(0xFFE0E0E0),
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              period,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF757575),
                fontSize: 12,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
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
      // 그리드 설정
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 5000,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: const Color(0xFFE0E0E0),
            strokeWidth: 1,
          );
        },
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
              return LineTooltipItem(
                '₩$price',
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
        // 왼쪽 타이틀 (가격)
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            interval: 5000,
            getTitlesWidget: (value, meta) {
              return Text(
                '${(value ~/ 1000)}K',
                style: const TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 10,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
        // 하단 타이틀 (날짜/인덱스)
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: selectedPeriod == '일봉' ? 2 : 1,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < currentData.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '${value.toInt()}',
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
      maxX: (currentData.length - 1).toDouble(),
      minY: minPrice - 2000,
      maxY: maxPrice + 2000,
      // 선 데이터
      lineBarsData: [
        LineChartBarData(
          spots: currentData,
          isCurved: true,
          curveSmoothness: 0.3,
          color: const Color(0xFF4CAF50),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                const Color(0xFF4CAF50).withOpacity(0.3),
                const Color(0xFF4CAF50).withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }
}
