import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../widgets/common/top_navigation.dart';
import '../../widgets/main/live_chat_card.dart';
import '../chat/chat_list_screen.dart';
import '../../widgets/chat/chat_bubble.dart';

class AllNewsDetailScreen extends StatefulWidget {
  const AllNewsDetailScreen({super.key});

  @override
  State<AllNewsDetailScreen> createState() => _AllNewsDetailScreenState();
}

class _AllNewsDetailScreenState extends State<AllNewsDetailScreen> {
  bool isCompany = true;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      body: SafeArea(
        child: Column(
          children: [
            /// ✅ Top Navigation
            TopNavigation(
              w: w,
              h: h,
              isCompany: isCompany,
              onTapCompany: () => setState(() => isCompany = true),
              onTapChat: () => setState(() => isCompany = false),
              onProfileTap: () => context.push('/mypage'),
            ),

            if (isCompany) SizedBox(height: AppSpacing.section(context)),

            /// ✅ 화면 전환
            Expanded(
              child:
              isCompany ? _buildNewsDetailBody(context, w, h) : const ChatListScreen(),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ 뉴스 상세 페이지 본문
  Widget _buildNewsDetailBody(BuildContext context, double w, double h) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.horizontal(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ✅ LiveChatCard
          LiveChatCard(w: w, h: h),

          SizedBox(height: AppSpacing.section(context)),

          /// ✅ 전체 컨텐츠 흰색 카드
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.05,   // ✅ 반응형 padding
              vertical: w * 0.045,    // ✅ 반응형 padding
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ✅ 뉴스 제목
                Text(
                  "미국 빅테크 3분기 실적 희비…구글 분기 매출 첫 1000억 달러 돌파",
                  style: TextStyle(
                    fontSize: w * 0.055,    // ✅ 반응형 (약 22px)
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF143D60),
                  ),
                ),

                SizedBox(height: AppSpacing.small(context)),

                /// ✅ 날짜
                Text(
                  "2025년 10월 30일 15:15",
                  style: TextStyle(
                    fontSize: w * 0.038,    // ✅ 반응형 (약 14px)
                    color: Colors.grey,
                  ),
                ),

                SizedBox(height: AppSpacing.medium(context)),

                /// ✅ 본문 텍스트
                Text(
                  "3사 모두 사상 최대 매출\n"
                      "시장 평가는 크게 엇갈려\n"
                      "알파벳, 클라우드 부문 고성장 견인\n"
                      "MS, 과도한 설비 투자에 투자자 불안감 커져"
                      "메타, 현실성 떨어진 비용에 EPS 예상 쇼크",
                  style: TextStyle(
                    fontSize: w * 0.040,   // ✅ 반응형 (약 16px)
                    height: 1.5,
                    color: const Color(0xFF333333),
                  ),
                ),

                SizedBox(height: AppSpacing.big(context)),

                /// ✅ AI 말풍선 리스트
                _buildAiComments(),

              ],
            ),
          ),

          SizedBox(height: AppSpacing.bottomLarge(context)),
        ],
      ),
    );
  }

  /// ✅ AI 댓글 말풍선 리스트
  Widget _buildAiComments() {
    final comments = [
      "구글 미쳤다ㅋㅋ 드디어 분기 매출 1,000억 달러 돌파🔥 알파벳이 AI 시장 제대로 접수했네!",
      "MS는 투자 너무 과했어요. 데이터센터에 349억 달러라니 리스크 커보여요",
      "클라우드 잔액 1,550억 달러면 구조적으로 알파벳이 AI 인프라 경쟁서 유리한 포지션이야",
      "메타 주가 8% 급락😨 이번엔 세금공제 때문에 커뮤니티 분위기도 싸늘해요.",
      "AI 붐이 끝없이 이어질 순 없지. 투자 과열 땐 항상 조정이 오더라고",
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
      children: List.generate(comments.length, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.small(context)),
          child: ChatBubble(
            text: comments[index],
            imagePath: images[index % images.length],
            w: MediaQuery.of(context).size.width,
            h: MediaQuery.of(context).size.height,
          ),
        );
      }),
    );
  }
}
