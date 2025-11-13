import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/dashboard_model.dart';

class NewsSection extends StatelessWidget {
  final double w;
  final double h;
  final List<RecommendedNews> recommendedNews;

  const NewsSection({
    super.key,
    required this.w,
    required this.h,
    required this.recommendedNews,
  });

  @override
  Widget build(BuildContext context) {
    print('🟢 NewsSection - recommendedNews 개수: ${recommendedNews.length}');
    if (recommendedNews.isNotEmpty) {
      print('🟢 첫 번째 뉴스: ${recommendedNews[0].title}');
    }

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
          child: recommendedNews.isEmpty
              ? Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.04,
                    vertical: h * 0.04,
                  ),
                  child: const Center(
                    child: Text(
                      "추천 뉴스가 없습니다",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (int i = 0; i < recommendedNews.length; i++) ...[
                      if (i > 0) _divider(),
                      _newsItem(recommendedNews[i]),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _divider() => Container(height: 1, color: const Color(0xFFE0E0E0));

  Widget _newsItem(RecommendedNews news) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(news.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.04,
          vertical: h * 0.018,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              news.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            if (news.summary.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                news.summary,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
