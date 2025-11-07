import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NewsSection extends StatelessWidget {
  final double w;
  final double h;

  const NewsSection({super.key, required this.w, required this.h});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "추천 뉴스",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),

            /// ✅ 전체보기 → 클릭 시 /news 이동
            GestureDetector(
              onTap: () => context.push('/news'),
              child: const Text(
                "전체보기",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFA9A9A9),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: h * 0.01),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _newsItem("(더미)이 대통령-트럼프 오늘 경주박물관서 정상회담…관세 샅바싸움 끝낼까"),
              _divider(),
              _newsItem("(더미)삼성 반도체가 살아났다…엔비디아 공급망 본격 진입"),
              _divider(),
              _newsItem("(더미)[경주 APEC] MS 부사장 AI 기술 활용서 인프라 투자가 가장 중요"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _divider() => Container(height: 1, color: const Color(0xFFE0E0E0));

  Widget _newsItem(String text) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: w * 0.04,
        vertical: h * 0.018,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      ),
    );
  }
}
