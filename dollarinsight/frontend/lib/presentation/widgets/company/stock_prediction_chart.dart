import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// 주가예측 차트 위젯
/// 1주/1달 각각에 최저/예상/최고 퍼센트를 독립적인 막대로 표시
/// 0 기준선 기준으로 양수는 파란색, 음수는 보라색
class StockPredictionChart extends StatefulWidget {
  /// 1주 예측 데이터 (최저%, 예상%, 최고%)
  final Map<String, double>? weekPrediction;

  /// 1달 예측 데이터 (최저%, 예상%, 최고%)
  final Map<String, double>? monthPrediction;

  const StockPredictionChart({
    super.key,
    this.weekPrediction,
    this.monthPrediction,
  });

  @override
  State<StockPredictionChart> createState() => _StockPredictionChartState();
}

class _StockPredictionChartState extends State<StockPredictionChart> {
  int touchedIndex = -1;
  String selectedPeriod = '1주'; // 선택된 기간 (1주 또는 1달)

  // 색상 정의
  static const positiveColor = Color(0xFFFFD0EA); // 양수 - 보라색 (기본)
  static const positiveColorTouched = Color(0xFFDA60A4); // 양수 - 보라색 (터치)
  static const negativeColor = Color(0xFFABCEEA); // 음수 - 파란색 (기본)
  static const negativeColorTouched = Color(0xFF60A4DA); // 음수 - 파란색 (터치)

  // 기본 더미 데이터
  Map<String, double> get _defaultWeekPrediction => {
        '최저': -2.5,
        '예상': 3.5,
        '최고': 4.0,
      };

  Map<String, double> get _defaultMonthPrediction => {
        '최저': -1.5,
        '예상': 5.0,
        '최고': 6.0,
      };

  Map<String, double> get _weekData =>
      widget.weekPrediction ?? _defaultWeekPrediction;
  Map<String, double> get _monthData =>
      widget.monthPrediction ?? _defaultMonthPrediction;

  // 선택된 기간의 데이터만 반환
  Map<String, double> get _currentData {
    return selectedPeriod == '1주' ? _weekData : _monthData;
  }

  // 현재 선택된 데이터를 리스트로 변환
  List<MapEntry<String, double>> get _allData {
    return _currentData.entries.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            _buildPeriodSelector(),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: BarChart(
              _buildBarChartData(),
            ),
          ),
        ),
      ],
    );
  }

  /// 기간 선택 인디케이터 (1주/1달)
  Widget _buildPeriodSelector() {
    return Row(
      children: ['1주', '1달'].map((period) {
        final isSelected = selectedPeriod == period;
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedPeriod = period;
              touchedIndex = -1; // 터치 상태 초기화
            });
          },
          child: Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE5E5E5) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              period,
              style: TextStyle(
                color: isSelected ? Colors.black : const Color(0xFF757575),
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

  /// 막대 그래프 데이터 구성
  BarChartData _buildBarChartData() {
    // 최소/최대값 계산
    final allValues = _allData.map((e) => e.value).toList();
    final double minValue = allValues.reduce((a, b) => a < b ? a : b);
    final double maxValue = allValues.reduce((a, b) => a > b ? a : b);

    // Y축 범위 설정 (0 기준선 포함)
    final double minY = minValue < 0 ? minValue - 1 : -1;
    final double maxY = maxValue > 0 ? maxValue + 1 : 1;

    return BarChartData(
      // 터치 설정
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => Colors.black87,
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final data = _allData[group.x.toInt()];
            final label = data.key;
            final value = data.value;

            return BarTooltipItem(
              '$selectedPeriod - $label\n',
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
        touchCallback: (FlTouchEvent event, barTouchResponse) {
          setState(() {
            if (!event.isInterestedForInteractions ||
                barTouchResponse == null ||
                barTouchResponse.spot == null) {
              touchedIndex = -1;
              return;
            }
            touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
          });
        },
      ),
      // 타이틀 설정
      titlesData: FlTitlesData(
        show: true,
        // 하단 타이틀 (항목명)
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            getTitlesWidget: _getBottomTitles,
          ),
        ),
        // 왼쪽, 오른쪽, 상단 타이틀 숨기기
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      // 테두리 설정 (숨김)
      borderData: FlBorderData(
        show: false,
      ),
      // 그리드 설정 (0 기준선만 표시)
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY - minY, // 큰 값으로 설정해서 0만 그리도록
        checkToShowHorizontalLine: (value) => value == 0,
        getDrawingHorizontalLine: (value) {
          if (value == 0) {
            return FlLine(
              color: const Color(0xFF757575),
              strokeWidth: 1,
            );
          }
          return FlLine(color: Colors.transparent);
        },
      ),
      // 막대 그룹 데이터
      barGroups: _createBarGroups(),
      // Y축 범위 설정
      minY: minY,
      maxY: maxY,
      alignment: BarChartAlignment.spaceEvenly,
    );
  }

  /// 하단 타이틀 위젯 (항목명과 값)
  Widget _getBottomTitles(double value, TitleMeta meta) {
    final index = value.toInt();

    if (index < 0 || index >= _allData.length) {
      return const SizedBox();
    }

    final data = _allData[index];
    final label = data.key;
    final percentage = data.value;

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF757575),
              fontSize: 10,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              height: 1.40,
              letterSpacing: 0.30,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF757575),
              fontSize: 10,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  /// 막대 그룹 생성
  List<BarChartGroupData> _createBarGroups() {
    return List.generate(_allData.length, (index) {
      final value = _allData[index].value;
      final isTouched = index == touchedIndex;

      return _makeGroupData(
        index,
        value,
        isTouched: isTouched,
      );
    });
  }

  /// 개별 막대 그룹 데이터 생성
  BarChartGroupData _makeGroupData(
    int x,
    double y, {
    bool isTouched = false,
    double width = 22,
  }) {
    // 값에 따라 색상 결정 (양수: 파란색, 음수: 보라색)
    final isPositive = y >= 0;
    final barColor = isTouched
        ? (isPositive ? positiveColorTouched : negativeColorTouched)
        : (isPositive ? positiveColor : negativeColor);

    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          fromY: 0,
          toY: y,
          color: barColor,
          width: width,
          borderRadius: y >= 0
              ? const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                )
              : const BorderRadius.only(
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
        ),
      ],
    );
  }
}
