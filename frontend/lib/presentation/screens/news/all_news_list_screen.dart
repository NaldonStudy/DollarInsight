import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../widgets/common/top_navigation.dart';
import '../../widgets/main/live_chat_card.dart';
import '../chat/chat_list_screen.dart';

class AllNewsListScreen extends StatefulWidget {
  const AllNewsListScreen({super.key});

  @override
  State<AllNewsListScreen> createState() => _AllNewsListScreenState();
}

class _AllNewsListScreenState extends State<AllNewsListScreen> {
  bool isCompany = true;

  /// ✅ 뉴스 리스트
  List<String> newsList = [];

  /// ✅ 각 뉴스의 펼침 상태 (newsList와 1:1 대응)
  List<bool> isOpen = [];

  /// ✅ 스크롤 컨트롤러 (무한스크롤)
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    /// ✅ 초기 데이터 15개
    _addNews(List.generate(15, (i) => "더미 뉴스 ${i + 1}입니다. 클릭해서 펼쳐보세요."));

    /// ✅ 스크롤 감지 → 끝에서 200px 남았을 때 로딩
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreNews();
      }
    });
  }

  /// ✅ 뉴스 데이터를 추가할 때마다 펼침 상태도 추가
  void _addNews(List<String> items) {
    newsList.addAll(items);
    isOpen.addAll(List<bool>.filled(items.length, false));
    setState(() {});
  }

  /// ✅ 무한스크롤 → 10개씩 추가
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

            /// ✅ 화면 전환 (기업분석 / 채팅)
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

  /// ✅ 전체 뉴스 본문
  Widget _buildNewsBody(BuildContext context, double w, double h) {
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

          const Text(
            "전체 뉴스",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),

          SizedBox(height: AppSpacing.small(context)),

          /// ✅ 뉴스 카드 컨테이너
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
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
                    if (index != newsList.length - 1) _divider(),
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

  /// ✅ Divider
  Widget _divider() => Container(
    height: 1,
    color: const Color(0xFFE0E0E0),
  );

  /// ✅ 확장형 뉴스 아이템 (추천 뉴스 스타일 적용)
  Widget _expandableNewsItem({
    required int index,
    required double w,
    required double h,
    required String text,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          isOpen[index] = !isOpen[index];
        });
      },
      child: Container(
        width: double.infinity,
        alignment: Alignment.centerLeft, // ✅ 텍스트를 확실히 좌측 정렬
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.04,
          vertical: h * 0.018,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ✅ 뉴스 제목 (좌측 정렬)
            Text(
              text,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),

            /// ✅ 펼쳐지는 UI + 애니메이션
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
                    ),
                    _actionButton(
                      label: "채팅하기",
                      bgColor: const Color(0xFFAEC6F7),
                      w: w,
                      h: h,
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

  /// ✅ 버튼 공통 위젯
  Widget _actionButton({
    required String label,
    required Color bgColor,
    required double w,
    required double h,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: w * 0.08,
        vertical: h * 0.012,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
