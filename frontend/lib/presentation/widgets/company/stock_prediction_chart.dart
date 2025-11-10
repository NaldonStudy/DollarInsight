import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 주가 예측 그래프 위젯 (추차춥스 모양)
/// 1주 후, 1달 후 예측치를 최저/예상/최고로 표시
class StockPredictionChart extends StatelessWidget {
  final List<PredictionData> predictions;

  const StockPredictionChart({
    super.key,
    required this.predictions,
  });

  @override
  Widget build(BuildContext context) {
    if (predictions.isEmpty) {
      return const Center(
        child: Text(
          '예측 데이터가 없습니다.',
          style: TextStyle(color: Color(0xFF757575)),
        ),
      );
    }

    // 전체 데이터에서 최대/최소값 찾기
    double globalMax = 0;
    double globalMin = double.infinity;

    for (var prediction in predictions) {
      if (prediction.high > globalMax) globalMax = prediction.high;
      if (prediction.low < globalMin) globalMin = prediction.low;
    }

    final range = globalMax - globalMin;
    final chartHeight = 300.0;
    final barWidth = 60.0;
    final spacing = 40.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 16),
          child: Text(
            '주가 예측',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = predictions.length * (barWidth + spacing);
              final availableWidth = constraints.maxWidth;
              final leftPadding = (availableWidth - totalWidth) / 2;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  height: chartHeight,
                  padding: EdgeInsets.only(
                    left: leftPadding > 0 ? leftPadding : 20,
                    right: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: predictions.asMap().entries.map((entry) {
                      return _buildPredictionBar(
                        entry.value,
                        globalMin,
                        globalMax,
                        range,
                        chartHeight,
                        barWidth,
                        entry.key < predictions.length - 1 ? spacing : 0,
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildLegend(),
      ],
    );
  }

  Widget _buildPredictionBar(
    PredictionData prediction,
    double globalMin,
    double globalMax,
    double range,
    double chartHeight,
    double barWidth,
    double rightMargin,
  ) {
    // 각 값의 높이 계산 (차트 하단부터의 높이)
    final maxHeight = chartHeight - 40; // 상단 여백
    final lowHeight = ((prediction.low - globalMin) / range) * maxHeight;
    final expectedHeight = ((prediction.expected - globalMin) / range) * maxHeight;
    final highHeight = ((prediction.high - globalMin) / range) * maxHeight;

    // 선 높이 (최저가부터 최고가까지)
    final lineHeight = highHeight - lowHeight;

    return Container(
      margin: EdgeInsets.only(right: rightMargin),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 차트 영역
          SizedBox(
            height: chartHeight - 40,
            width: barWidth,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // 최저가부터 최고가까지 세로 선
                Positioned(
                  bottom: lowHeight,
                  child: Container(
                    width: 2,
                    height: lineHeight,
                    color: const Color(0xFF757575),
                  ),
                ),
                // 최저가 점
                Positioned(
                  bottom: lowHeight - 6,
                  child: _buildDot(
                    Colors.blue,
                    NumberFormat('#,###').format(prediction.low),
                    '최저',
                  ),
                ),
                // 예상가 점 (중간)
                Positioned(
                  bottom: expectedHeight - 6,
                  child: _buildDot(
                    const Color(0xFF2196F3),
                    NumberFormat('#,###').format(prediction.expected),
                    '예상',
                  ),
                ),
                // 최고가 점
                Positioned(
                  bottom: highHeight - 6,
                  child: _buildDot(
                    Colors.red,
                    NumberFormat('#,###').format(prediction.high),
                    '최고',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // X축 라벨
          Text(
            prediction.label,
            style: const TextStyle(
              color: Color(0xFF757575),
              fontSize: 12,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(Color color, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 왼쪽 라벨
        Container(
          constraints: const BoxConstraints(minWidth: 60),
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF595959),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 점
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // 오른쪽 라벨
        SizedBox(
          width: 30,
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem(Colors.red, '예측 최고가'),
          const SizedBox(width: 16),
          _buildLegendItem(const Color(0xFF2196F3), '예상가'),
          const SizedBox(width: 16),
          _buildLegendItem(Colors.blue, '예측 최저가'),
        ],
      ),
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
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// 예측 데이터 모델
class PredictionData {
  final String label; // '1주 후', '1달 후'
  final double low; // 최저 예측가
  final double expected; // 예상가
  final double high; // 최고 예측가

  PredictionData({
    required this.label,
    required this.low,
    required this.expected,
    required this.high,
  });
}
