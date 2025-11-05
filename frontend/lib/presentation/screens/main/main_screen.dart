import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../widgets/common/top_navigation.dart';
import '../chat/chat_list_screen.dart';
import '../../widgets/main/live_chat_card.dart';
import '../../widgets/main/index_section.dart';
import '../../widgets/main/news_section.dart';
import '../../widgets/main/stock_section.dart';
import '../../widgets/common/scroll_fab_button.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool isCompany = true; // ✅ 기업분석 / 채팅 상태 저장
  final ScrollController _scrollController = ScrollController();
  bool showFab = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      setState(() {
        showFab = _scrollController.offset > 40;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),

      /// ✅ 스크롤 시 나타나는 FAB 버튼
      floatingActionButton: ScrollFabButton(
        w: w,
        showFab: showFab,
        onTap: () {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      /// ✅ MAIN BODY
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

            /// ✅ 기업분석일 때만 Navigation 아래 간격 추가
            if (isCompany)
              SizedBox(height: AppSpacing.section(context)),

            /// ✅ 화면 스위칭 (화면 전체 전환 아님)
            Expanded(
              child: isCompany
                  ? _buildCompanyBody(context, w, h)
                  : const ChatListScreen(),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ 기업분석 탭 화면 구성
  Widget _buildCompanyBody(BuildContext context, double w, double h) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.horizontal(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ✅ 실시간 채팅 박스
          LiveChatCard(w: w, h: h),

          SizedBox(height: AppSpacing.section(context)),

          /// ✅ 주요 지수
          IndexSection(w: w, h: h),

          SizedBox(height: AppSpacing.section(context)),

          /// ✅ 뉴스 섹션
          NewsSection(w: w, h: h),

          SizedBox(height: AppSpacing.section(context)),

          /// ✅ 관심종목 섹션
          StockSection(w: w, h: h),

          SizedBox(height: AppSpacing.bottomLarge(context)),
        ],
      ),
    );
  }
}
