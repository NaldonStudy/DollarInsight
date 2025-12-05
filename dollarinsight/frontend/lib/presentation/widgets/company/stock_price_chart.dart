import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../data/models/company_detail_model.dart';

/// 주가 차트 위젯
/// 일봉 30일치 데이터를 표시하는 꺾은선 그래프
/// Trackball을 통해 데이터 포인트 상세 정보 표시
class StockPriceChart extends StatefulWidget {
  final List<PriceDataPoint> dailyData;

  const StockPriceChart({
    super.key,
    required this.dailyData,
  });

  @override
  State<StockPriceChart> createState() => _StockPriceChartState();
}

class _StockPriceChartState extends State<StockPriceChart> {
  // API 데이터를 FlSpot으로 변환
  List<FlSpot> get chartData {
    if (widget.dailyData.isEmpty) return [];

    return widget.dailyData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.close);
    }).toList();
  }

  // 최저/최고치 계산
  double get minPrice {
    if (chartData.isEmpty) return 0;
    return chartData.map((e) => e.y).reduce((a, b) => a < b ? a : b);
  }

  double get maxPrice {
    if (chartData.isEmpty) return 0;
    return chartData.map((e) => e.y).reduce((a, b) => a > b ? a : b);
  }

  // 최저/최고 인덱스 찾기
  int get minPriceIndex => chartData.indexWhere((spot) => spot.y == minPrice);
  int get maxPriceIndex => chartData.indexWhere((spot) => spot.y == maxPrice);

  @override
  Widget build(BuildContext context) {
    if (chartData.isEmpty) {
      return const Center(
        child: Text(
          '차트 데이터가 없습니다.',
          style: TextStyle(color: Color(0xFF757575)),
        ),
      );
    }

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
          '\$${price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
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

              // 날짜 표시 (API 데이터 사용)
              final index = spot.x.toInt();
              String dateString = '';
              if (index >= 0 && index < widget.dailyData.length) {
                dateString = widget.dailyData[index].priceDate;
              }

              return LineTooltipItem(
                '$dateString\n\$$price',
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

              if (index >= 0 && index < chartData.length) {
                String text;
                // 30일치 데이터: 0, 10, 20 위치에 표시
                if (index == 0) {
                  text = '30';
                } else if (index == 10) {
                  text = '20';
                } else if (index == 20) {
                  text = '10';
                } else {
                  return const Text('');
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
      maxX: chartData.isEmpty ? 0 : (chartData.length - 1).toDouble(),
      minY: minPrice > 0 ? minPrice * 0.98 : 0,
      maxY: maxPrice > 0 ? maxPrice * 1.02 : 100,
      // 선 데이터
      lineBarsData: [
        LineChartBarData(
          spots: chartData,
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
