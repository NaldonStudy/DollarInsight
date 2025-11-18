import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// 주식 점수 차트 위젯
/// 총점, 모멘텀, 가치, 성장, 수급, 위험 6가지 항목의 점수를 막대 그래프로 표시
/// 터치하면 점수가 표시됨
class StockScoreChart extends StatefulWidget {
  /// 주식 점수 데이터 (총점, 모멘텀, 가치, 성장, 수급, 위험)
  final Map<String, double>? scores;

  const StockScoreChart({
    super.key,
    this.scores,
  });

  @override
  State<StockScoreChart> createState() => _StockScoreChartState();
}

class _StockScoreChartState extends State<StockScoreChart> {
  int touchedIndex = -1;

  // 기본 더미 데이터 (API 데이터가 없을 때 사용)
  Map<String, double> get _defaultScores => {
    '총점': 70,
    '모멘텀': 80,
    '가치': 55,
    '성장': 75,
    '수급': 90,
    '위험': 75,
  };

  // 실제 사용할 데이터 (props가 있으면 props, 없으면 기본값)
  Map<String, double> get _scores => widget.scores ?? _defaultScores;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '주식 점수',
          style: TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            height: 1.87,
          ),
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
        const SizedBox(height: 8),
        const Text(
          '일부 지표는 적자·데이터 부족으로 표시되지 않을 수 있어요.',
          style: TextStyle(
            color: Color(0xFF9E9E9E),
            fontSize: 10,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// 막대 그래프 데이터 구성
  BarChartData _buildBarChartData() {
    return BarChartData(
      // 터치 설정
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => Colors.black87,
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final labels = _scores.keys.toList();
            final label = labels[group.x.toInt()];
            final score = _scores[label]!;

            // null 값인 경우 (-1로 통일, label로 구분)
            if (score < 0) {
              String message = '데이터 없음';
              if (label == '가치') {
                message = '적자인 종목은\n 계산이 어려워\n 점수가 없어요.';
              } else if (label == '성장') {
                message = '순이익 급감으로\n0점이에요.';
              }
              return BarTooltipItem(
                message,
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                ),
              );
            }

            return BarTooltipItem(
              '$label\n',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                fontFamily: 'Pretendard',
              ),
              children: <TextSpan>[
                TextSpan(
                  text: '${score.toInt()}점',
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
      // 그리드 설정 (숨김)
      gridData: const FlGridData(show: false),
      // 막대 그룹 데이터
      barGroups: _createBarGroups(),
      // Y축 범위 설정 (0~100)
      minY: 0,
      maxY: 100,
      alignment: BarChartAlignment.spaceEvenly,
    );
  }

  /// 하단 타이틀 위젯 (항목명과 점수)
  Widget _getBottomTitles(double value, TitleMeta meta) {
    final labels = _scores.keys.toList();
    final index = value.toInt();

    if (index < 0 || index >= labels.length) {
      return const SizedBox();
    }

    final label = labels[index];
    final score = _scores[label]!;

    // -1일 때: 가치는 "–", 성장은 "0", 그 외: 점수 표시
    String displayText;
    if (score < 0) {
      displayText = label == '성장' ? '0' : '–';
    } else {
      displayText = '${score.toInt()}';
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
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
            displayText,
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
    final labels = _scores.keys.toList();

    return List.generate(labels.length, (index) {
      final label = labels[index];
      final score = _scores[label]!;
      final isTouched = index == touchedIndex;
      // null인 경우 (score < 0이면 -1 또는 -2)
      final isNull = score < 0;

      return _makeGroupData(
        index,
        score,
        isTouched: isTouched,
        isNull: isNull,
      );
    });
  }

  /// 개별 막대 그룹 데이터 생성
  BarChartGroupData _makeGroupData(
    int x,
    double y, {
    bool isTouched = false,
    bool isNull = false,
    double width = 22,
  }) {
    // null 값인 경우 반투명 회색
    Color barColor;
    if (isNull) {
      barColor = const Color(0xFFD9D9D9).withOpacity(0.5);
    } else {
      barColor = isTouched ? const Color(0xFF60A4DA) : const Color(0xFFABCEEA);
    }

    // null 값인 경우 터치 가능하도록 최소 높이(3) 설정
    final displayY = isNull ? 3.0 : y;

    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: displayY,
          color: barColor,
          width: width,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
          // null 값인 경우 점선 스타일 (dashArray 사용)
          borderDashArray: isNull ? [4, 4] : null,
          borderSide: isNull
              ? BorderSide(
                  color: const Color(0xFF9E9E9E).withOpacity(0.5),
                  width: 1.5,
                )
              : BorderSide.none,
          // 배경 막대 (회색, 100점까지)
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 100,
            color: const Color(0xFFD9D9D9).withOpacity(0.3),
          ),
        ),
      ],
    );
  }
}
