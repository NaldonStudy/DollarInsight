import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/chat/chat_bubble.dart';
import '../../../data/models/dashboard_model.dart';
import '../../../core/constants/etf_data.dart';

class StockSection extends StatelessWidget {
  final double w;
  final double h;
  final List<DailyPick> dailyPicks;

  const StockSection({
    super.key,
    required this.w,
    required this.h,
    required this.dailyPicks,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ 페르소나 코드에 따른 이미지 매핑 (백엔드 기준)
    String _getPersonaImage(String personaCode) {
      final code = personaCode.toLowerCase();

      switch (code) {
        case 'heuyeol':
          return 'assets/images/heuyeol.webp';
        case 'jiyul':
          return 'assets/images/jiyul.webp';
        case 'teo':
          return 'assets/images/teo.webp';
        case 'minji':
          return 'assets/images/minji.webp';
        case 'deoksu':
          return 'assets/images/deoksu.webp';
        default:
          // 알 수 없는 페르소나 코드는 기본 이미지 사용
          return 'assets/images/heuyeol.webp';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// ✅ 타이틀 + 편집 + 전체보기
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            /// ✅ 왼쪽 제목
            Text(
              "데일리 픽",
              style: TextStyle(
                fontSize: w * 0.055, // 약 20px
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),

        /// ✅ 데일리픽 리스트 카드
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.035,
            vertical: w * 0.035,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(w * 0.03),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: dailyPicks.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      "데일리 픽이 없습니다",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (int i = 0; i < dailyPicks.length; i++) ...[
                      GestureDetector(
                        onTap: () {
                          final ticker = dailyPicks[i].ticker;
                          // ✅ ETF인지 확인 후 적절한 경로로 이동
                          final isEtf = etfDataMap.containsKey(ticker.toUpperCase());
                          if (isEtf) {
                            context.push('/etf/$ticker');
                          } else {
                            context.push('/company/$ticker');
                          }
                        },
                        child: ChatBubble(
                          text: dailyPicks[i].personaComment.comment,
                          imagePath: _getPersonaImage(
                            dailyPicks[i].personaComment.personaCode,
                          ),
                          w: w,
                          h: h,
                        ),
                      ),
                      if (i < dailyPicks.length - 1)
                        SizedBox(height: h * 0.016),
                    ]
                  ],
                ),
        ),
      ],
    );
  }
}
