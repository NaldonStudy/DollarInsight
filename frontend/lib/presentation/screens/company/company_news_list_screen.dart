import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_spacing.dart';
import '../../widgets/common/top_navigation.dart';
import '../../widgets/main/live_chat_card.dart';
import '../chat/chat_list_screen.dart';
import '../../widgets/common/scroll_fab_button.dart';
import '../../providers/company_news_provider.dart';
import 'company_news_detail_screen.dart';

/// 기업별 뉴스 리스트 화면
/// AllNewsListScreen과 동일한 포맷, Provider 활용
class CompanyNewsListScreen extends StatefulWidget {
  final String companyId;

  const CompanyNewsListScreen({
    super.key,
    required this.companyId, // ticker를 필수로 받음
  });

  @override
  State<CompanyNewsListScreen> createState() => _CompanyNewsListScreenState();
}

class _CompanyNewsListScreenState extends State<CompanyNewsListScreen> {
  bool isCompany = true;
  List<bool> isOpen = [];
  final ScrollController _scrollController = ScrollController();
  bool showFab = false;

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
        final provider = context.read<CompanyNewsProvider>();
        if (!provider.isLoadingMore && provider.hasMore) {
          provider.loadMoreNews();
        }
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
      create: (_) => CompanyNewsProvider(companyId: widget.companyId),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FB),

        // 스크롤 시 나타나는 FAB 버튼
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

  /// 기업 뉴스 영역 UI
  Widget _buildNewsBody(BuildContext context, double w, double h) {
    return Consumer<CompanyNewsProvider>(
      builder: (context, provider, child) {
        // 에러 처리
        if (provider.error != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(provider.error!)),
            );
            provider.clearError();
          });
        }

        // 로딩 중
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // isOpen 리스트 초기화 (뉴스 개수에 맞춰)
        if (isOpen.length != provider.newsList.length) {
          isOpen = List<bool>.filled(provider.newsList.length, false);
        }

        return RefreshIndicator(
          onRefresh: () => provider.refresh(),
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.horizontal(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LiveChatCard(w: w, h: h),
                SizedBox(height: AppSpacing.section(context)),

                // 기업명 표시
                Text(
                  "${provider.companyName ?? '기업'} 뉴스",
                  style: TextStyle(
                    fontSize: w * 0.06,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: AppSpacing.small(context)),

                // 뉴스가 없을 때
                if (provider.newsList.isEmpty)
                  Container(
                    padding: EdgeInsets.all(AppSpacing.big(context)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(w * 0.03),
                    ),
                    child: Center(
                      child: Text(
                        "기업 뉴스가 없습니다.",
                        style: TextStyle(
                          fontSize: w * 0.04,
                          color: const Color(0xFF757575),
                        ),
                      ),
                    ),
                  )
                else
                  // 뉴스 카드 박스
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(w * 0.03),
                    ),
                    child: Column(
                      children: [
                        ...List.generate(
                          provider.newsList.length,
                          (index) => Column(
                            children: [
                              _expandableNewsItem(
                                index: index,
                                w: w,
                                h: h,
                                news: provider.newsList[index],
                              ),
                              if (index != provider.newsList.length - 1)
                                _divider(h),
                            ],
                          ),
                        ),

                        // 무한 스크롤 로딩 인디케이터
                        if (provider.isLoadingMore)
                          Padding(
                            padding: EdgeInsets.all(AppSpacing.medium(context)),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),

                        // 더 이상 불러올 뉴스가 없을 때
                        if (!provider.hasMore && provider.newsList.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.all(AppSpacing.medium(context)),
                            child: Center(
                              child: Text(
                                "모든 뉴스를 불러왔습니다.",
                                style: TextStyle(
                                  fontSize: w * 0.035,
                                  color: const Color(0xFF757575),
                                ),
                              ),
                            ),
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

  /// ISO 8601 날짜 포맷팅
  String _formatDate(String isoDate) {
    try {
      final dateTime = DateTime.parse(isoDate);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes}분 전';
        }
        return '${difference.inHours}시간 전';
      } else if (difference.inDays == 1) {
        return '어제';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}일 전';
      } else {
        return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return isoDate;
    }
  }

  Widget _expandableNewsItem({
    required int index,
    required double w,
    required double h,
    required Map<String, String> news,
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
            // 뉴스 제목
            Text(
              news['title'] ?? '',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),

            // 날짜
            if (news['publishedAt'] != null && news['publishedAt']!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: h * 0.005),
                child: Text(
                  _formatDate(news['publishedAt']!),
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
                        // 기업 뉴스 상세 화면으로 이동
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CompanyNewsDetailScreen(
                              companyId: widget.companyId,
                              newsId: news['id'] ?? '1',
                            ),
                          ),
                        );
                      },
                    ),
                    _actionButton(
                      label: "채팅하기",
                      bgColor: const Color(0xFFAEC6F7),
                      w: w,
                      h: h,
                      onTap: () {
                        // TODO: 채팅 화면으로 이동
                        // context.push('/chat');
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
