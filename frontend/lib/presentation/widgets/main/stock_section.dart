import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/chat/chat_bubble.dart';

class StockSection extends StatelessWidget {
  final double w;
  final double h;

  const StockSection({super.key, required this.w, required this.h});

  @override
  Widget build(BuildContext context) {
    final messages = [
      "젠슨황 오늘 또 무대 오른다!\n엔비디아 주주들 지금 심장 쿵쾅거리는 거 들리냐ㅋㅋ",
      "오늘 Meta 발표가 있어요.\nAI 투자와 광고 매출 회복이 관전 포인트 입니다",
      "테슬라는 전기차를 넘어 AI·로봇·에너지까지 확장 중이에요",
      "애플 AI 아이폰 루머에 커뮤니티 난리🔥 이번엔 혁신 각이죠ㅋㅋ",
      "아마존, 위기 때마다 더 강해지는 기업이지.\n클라우드·AI로 또 한 번 판을 키우고 있어.",
    ];

    final images = [
      "assets/images/Heeyule.webp",
      "assets/images/Jiyule.webp",
      "assets/images/Taeo.webp",
      "assets/images/Minji.webp",
      "assets/images/Ducksu.webp",
    ];

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

            /// ✅ 오른쪽 "편집 · 전체보기"
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    context.push('/mypage/ai-friend');
                  },
                  child: Text(
                    "편집",
                    style: TextStyle(
                      fontSize: w * 0.032, // 약 12px
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFA9A9A9),
                    ),
                  ),
                ),

                SizedBox(width: w * 0.02), // 편집과 전체보기 간격

                GestureDetector(
                  onTap: () {
                    // 전체보기 페이지 이동 처리
                  },
                  child: Text(
                    "전체보기",
                    style: TextStyle(
                      fontSize: w * 0.032, // 약 12px
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFA9A9A9),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        SizedBox(height: h * 0.012),

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

          child: Column(
            children: [
              for (int i = 0; i < messages.length; i++) ...[
                ChatBubble(
                  text: messages[i],
                  imagePath: images[i],
                  w: w,
                  h: h,
                ),
                SizedBox(height: h * 0.016),
              ]
            ],
          ),
        ),
      ],
    );
  }
}
