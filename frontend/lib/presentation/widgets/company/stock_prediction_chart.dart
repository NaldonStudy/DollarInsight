import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// 주가예측 차트 위젯
/// 1주/1달 각각에 최저/예상/최고 퍼센트를 세로로 쌓은 막대 그래프
class StockPredictionChart extends StatelessWidget {
  /// 1주 예측 데이터 (최저%, 예상%, 최고%)
  final Map<String, double>? weekPrediction;

  /// 1달 예측 데이터 (최저%, 예상%, 최고%)
  final Map<String, double>? monthPrediction;

  const StockPredictionChart({
    super.key,
    this.weekPrediction,
    this.monthPrediction,
  });

  // 색상 정의
  static const lowColor = Color(0xFF2196F3); // 최저 - 파란색
  static const expectedColor = Color(0xFF4CAF50); // 예상 - 초록색
  static const highColor = Color(0xFFFF5252); // 최고 - 빨간색
  static const betweenSpace = 0.2;

  // 기본 더미 데이터
  Map<String, double> get _defaultWeekPrediction => {
        '최저': 2.5,
        '예상': 3.5,
        '최고': 4.0,
      };

  Map<String, double> get _defaultMonthPrediction => {
        '최저': 3.0,
        '예상': 5.0,
        '최고': 6.0,
      };

  Map<String, double> get _weekData =>
      weekPrediction ?? _defaultWeekPrediction;
  Map<String, double> get _monthData =>
      monthPrediction ?? _defaultMonthPrediction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '주가 예측',
          style: TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            height: 1.87,
          ),
        ),
        const SizedBox(height: 8),
        _buildLegend(),
        const SizedBox(height: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 16, top: 8),
            child: BarChart(
              _buildBarChartData(),
            ),
          ),
        ),
      ],
    );
  }

  /// 범례
  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(lowColor, '최저'),
        const SizedBox(width: 16),
        _buildLegendItem(expectedColor, '예상'),
        const SizedBox(width: 16),
        _buildLegendItem(highColor, '최고'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
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
          label,
          style: const TextStyle(
            color: Color(0xFF757575),
            fontSize: 10,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 막대 그래프 데이터 구성
  BarChartData _buildBarChartData() {
    // 최대값 계산
    final maxWeek = _weekData.values.reduce((a, b) => a + b);
    final maxMonth = _monthData.values.reduce((a, b) => a + b);
    final maxY = (maxWeek > maxMonth ? maxWeek : maxMonth) +
        (betweenSpace * 2) +
        2; // 여유 공간

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => Colors.black87,
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            String period = group.x == 0 ? '1주' : '1달';
            String type = rodIndex == 0
                ? '최저'
                : rodIndex == 1
                    ? '예상'
                    : '최고';
            double value = rodIndex == 0
                ? rod.toY
                : rod.toY - rod.fromY - betweenSpace;

            return BarTooltipItem(
              '$period - $type\n',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                fontFamily: 'Pretendard',
              ),
              children: <TextSpan>[
                TextSpan(
                  text: '${value.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ],
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}%',
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
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: _bottomTitles,
            reservedSize: 30,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: const Color(0xFFE0E0E0), width: 1),
          left: BorderSide(color: const Color(0xFFE0E0E0), width: 1),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: const Color(0xFFE0E0E0),
            strokeWidth: 1,
          );
        },
      ),
      barGroups: [
        _generateGroupData(0, _weekData), // 1주
        _generateGroupData(1, _monthData), // 1달
      ],
    );
  }

  /// 하단 타이틀
  Widget _bottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xFF757575),
      fontSize: 12,
      fontFamily: 'Pretendard',
      fontWeight: FontWeight.w600,
    );
    String text = value.toInt() == 0 ? '1주' : '1달';
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(text, style: style),
    );
  }

  /// 막대 그룹 데이터 생성 (세로로 쌓기)
  BarChartGroupData _generateGroupData(int x, Map<String, double> data) {
    final low = data['최저'] ?? 0;
    final expected = data['예상'] ?? 0;
    final high = data['최고'] ?? 0;

    return BarChartGroupData(
      x: x,
      groupVertically: true,
      barRods: [
        BarChartRodData(
          fromY: 0,
          toY: low,
          color: lowColor,
          width: 40,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
        BarChartRodData(
          fromY: low + betweenSpace,
          toY: low + betweenSpace + expected,
          color: expectedColor,
          width: 40,
        ),
        BarChartRodData(
          fromY: low + betweenSpace + expected + betweenSpace,
          toY: low + betweenSpace + expected + betweenSpace + high,
          color: highColor,
          width: 40,
        ),
      ],
    );
  }
}
