import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../widgets/common/top_navigation.dart';
import '../chat/chat_list_screen.dart';
import '../../widgets/main/live_chat_card.dart';
import '../../widgets/main/index_section.dart';
import '../../widgets/main/news_section.dart';
import '../../widgets/main/stock_section.dart';

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
      body: SafeArea(
        child: Column(
          children: [
            /// ✅ TopNavigation 을 MainScreen이 직접 제어
            TopNavigation(
              w: w,
              h: h,
              isCompany: isCompany,
              onTapCompany: () => setState(() => isCompany = true),
              onTapChat: () => setState(() => isCompany = false),
              onProfileTap: () => context.push('/mypage'),
            ),

            if (isCompany)
              SizedBox(height: AppSpacing.section(context)),

            /// ✅ 탭에 따라 Body 변경
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

  /// ✅ 기업분석 화면 Body
  Widget _buildCompanyBody(BuildContext context, double w, double h) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.horizontal(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LiveChatCard(w: w, h: h),

          SizedBox(height: AppSpacing.section(context)),

          IndexSection(w: w, h: h),

          SizedBox(height: AppSpacing.section(context)),

          NewsSection(w: w, h: h),

          SizedBox(height: AppSpacing.section(context)),

          StockSection(w: w, h: h),

          SizedBox(height: AppSpacing.bottomLarge(context)),
        ],
      ),
    );
  }
}
