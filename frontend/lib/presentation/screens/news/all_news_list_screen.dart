import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_spacing.dart';
import '../../widgets/common/top_navigation.dart';
import '../../widgets/main/live_chat_card.dart';
import '../chat/chat_list_screen.dart';
import '../../widgets/common/scroll_fab_button.dart';
import '../../providers/all_news_list_provider.dart';
import '../../../core/utils/date_formatter.dart';

class AllNewsListScreen extends StatefulWidget {
  const AllNewsListScreen({super.key});

  @override
  State<AllNewsListScreen> createState() => _AllNewsListScreenState();
}

class _AllNewsListScreenState extends State<AllNewsListScreen> {
  bool isCompany = true;
  final ScrollController _scrollController = ScrollController();
  bool showFab = false;
  List<bool> isOpen = []; // 펼침 상태 관리

  @override
  void initState() {
    super.initState();

    // 스크롤 이벤트 → FAB 표시/숨김 + 무한스크롤
    _scrollController.addListener(() {
      setState(() {
        showFab = _scrollController.offset > 40;
      });

      // 무한 스크롤 트리거
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        final provider = context.read<AllNewsListProvider>();
        provider.loadMoreNews();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return ChangeNotifierProvider(
      create: (_) => AllNewsListProvider(),
      child: Scaffold(
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
      ),
    );
  }

  // 전체 뉴스 영역 UI
  Widget _buildNewsBody(BuildContext context, double w, double h) {
    return Consumer<AllNewsListProvider>(
      builder: (context, provider, child) {
        // 로딩 중
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // 에러 발생
        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  provider.error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.medium(context)),
                ElevatedButton(
                  onPressed: () => provider.refresh(),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        }

        // isOpen 리스트 초기화 (뉴스 개수에 맞춰)
        if (isOpen.length != provider.newsList.length) {
          isOpen = List<bool>.filled(provider.newsList.length, false);
        }

        // 데이터 로드 완료
        return RefreshIndicator(
          onRefresh: () => provider.refresh(),
          child: SingleChildScrollView(
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
          if (provider.newsList.isEmpty)
            Container(
              padding: EdgeInsets.all(w * 0.1),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(w * 0.03),
              ),
              child: const Center(
                child: Text(
                  '뉴스가 없습니다',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(w * 0.03),
              ),
              child: Column(
                children: [
                  ...List.generate(
                    provider.newsList.length,
                    (index) {
                      final news = provider.newsList[index];
                      return Column(
                        children: [
                          _expandableNewsItem(
                            index: index,
                            news: news,
                            w: w,
                            h: h,
                          ),
                          if (index != provider.newsList.length - 1) _divider(h),
                        ],
                      );
                    },
                  ),
                  // 로딩 인디케이터 (더 불러오는 중)
                  if (provider.isLoadingMore)
                    Padding(
                      padding: EdgeInsets.all(w * 0.04),
                      child: const CircularProgressIndicator(),
                    ),
                ],
              ),
            ),

          SizedBox(height: AppSpacing.bottomLarge(context)),
        ],
      ),
          ),
        );
      },
    );
  }

  Widget _divider(double h) => Container(
    height: h * 0.0012,
    color: const Color(0xFFE0E0E0),
  );

  Widget _expandableNewsItem({
    required int index,
    required news,
    required double w,
    required double h,
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
            // 제목
            Text(
              news.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),

            // 날짜
            Padding(
              padding: EdgeInsets.only(top: h * 0.005),
              child: Text(
                DateFormatter.formatToKorean(news.publishedAt),
                style: TextStyle(
                  fontSize: w * 0.03,
                  color: const Color(0xFF757575),
                ),
              ),
            ),

            // 확장 가능한 버튼 영역
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
                      onTap: () {
                        // 뉴스 상세 화면으로 이동
                        context.push('/news/${news.id}');
                      },
                    ),
                    _actionButton(
                      label: "채팅하기",
                      bgColor: const Color(0xFFAEC6F7),
                      w: w,
                      h: h,
                      onTap: () {
                        // TODO: 채팅 화면으로 이동
                        context.push('/chat/:id');
                      },
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
