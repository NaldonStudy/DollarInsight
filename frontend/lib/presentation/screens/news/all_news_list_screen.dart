import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../widgets/common/top_navigation.dart';
import '../../widgets/main/live_chat_card.dart';
import '../chat/chat_list_screen.dart';
import '../../widgets/common/scroll_fab_button.dart'; // ✅ 추가!

class AllNewsListScreen extends StatefulWidget {
  const AllNewsListScreen({super.key});

  @override
  State<AllNewsListScreen> createState() => _AllNewsListScreenState();
}

class _AllNewsListScreenState extends State<AllNewsListScreen> {
  bool isCompany = true;

  List<String> newsList = [];
  List<bool> isOpen = [];
  final ScrollController _scrollController = ScrollController();

  bool showFab = false; // ✅ 스크롤 fab 상태 추가

  @override
  void initState() {
    super.initState();

    _addNews(
      List.generate(15, (i) => "더미 뉴스 ${i + 1}입니다. 클릭해서 펼쳐보세요."),
    );

    // ✅ 스크롤 이벤트 → FAB 표시/숨김 + 무한스크롤
    _scrollController.addListener(() {
      setState(() {
        showFab = _scrollController.offset > 40;
      });

      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreNews();
      }
    });
  }

  void _addNews(List<String> items) {
    newsList.addAll(items);
    isOpen.addAll(List<bool>.filled(items.length, false));
    setState(() {});
  }

  void _loadMoreNews() {
    final moreItems = List.generate(
      10,
          (i) => "더미 뉴스 (추가) ${newsList.length + i + 1}",
    );
    _addNews(moreItems);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),

      // ✅ 스크롤 시 나타나는 FAB 버튼
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

      body: SafeArea(
        child: Column(
          children: [
            TopNavigation(
              w: w,
              h: h,
              isCompany: isCompany,
              onTapCompany: () => setState(() => isCompany = true),
              onTapChat: () => setState(() => isCompany = false),
              onProfileTap: () => context.push('/mypage'),
            ),

            if (isCompany) SizedBox(height: AppSpacing.section(context)),

            Expanded(
              child: isCompany
                  ? _buildNewsBody(context, w, h)
                  : const ChatListScreen(),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ 전체 뉴스 영역 UI
  Widget _buildNewsBody(BuildContext context, double w, double h) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.horizontal(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LiveChatCard(w: w, h: h),
          SizedBox(height: AppSpacing.section(context)),

          Text(
            "전체 뉴스",
            style: TextStyle(
              fontSize: w * 0.06,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppSpacing.small(context)),

          // 뉴스 카드 박스
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(w * 0.03),
            ),
            child: Column(
              children: List.generate(
                newsList.length,
                    (index) => Column(
                  children: [
                    _expandableNewsItem(
                      index: index,
                      w: w,
                      h: h,
                      text: newsList[index],
                    ),
                    if (index != newsList.length - 1) _divider(h),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: AppSpacing.bottomLarge(context)),
        ],
      ),
    );
  }

  Widget _divider(double h) => Container(
    height: h * 0.0012,
    color: const Color(0xFFE0E0E0),
  );

  Widget _expandableNewsItem({
    required int index,
    required double w,
    required double h,
    required String text,
  }) {
    return InkWell(
      onTap: () => setState(() => isOpen[index] = !isOpen[index]),
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
              text,
              style: TextStyle(
                fontSize: w * 0.04,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),

            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: isOpen[index]
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: EdgeInsets.only(top: h * 0.02),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _actionButton(
                      label: "AI 요약",
                      bgColor: const Color(0xFF143D60),
                      w: w,
                      h: h,
                      onTap: () => context.push('/news/$index'),
                    ),
                    _actionButton(
                      label: "채팅하기",
                      bgColor: const Color(0xFFAEC6F7),
                      w: w,
                      h: h,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color bgColor,
    required double w,
    required double h,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.08,
          vertical: h * 0.012,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(w * 0.12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: w * 0.04,
          ),
        ),
      ),
    );
  }
}
