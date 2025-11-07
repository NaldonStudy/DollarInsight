import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_spacing.dart';
import '../../providers/company_news_detail_provider.dart';
import '../../widgets/common/top_navigation.dart';
import '../../widgets/main/live_chat_card.dart';
import '../chat/chat_list_screen.dart';
import '../../widgets/chat/chat_bubble.dart';
import '../../widgets/common/scroll_fab_button.dart';

class CompanyNewsDetailScreen extends StatefulWidget {
  final String companyId;
  final String newsId;

  const CompanyNewsDetailScreen({
    super.key,
    required this.companyId,
    required this.newsId,
  });

  @override
  State<CompanyNewsDetailScreen> createState() =>
      _CompanyNewsDetailScreenState();
}

class _CompanyNewsDetailScreenState extends State<CompanyNewsDetailScreen> {
  bool isCompany = true;

  /// ✅ FAB 제어용
  bool showFab = false;
  final ScrollController _scrollController = ScrollController();

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

    return ChangeNotifierProvider(
      create: (_) => CompanyNewsDetailProvider(
        companyId: widget.companyId,
        newsId: widget.newsId,
      ),
      child: Scaffold(
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
                child: isCompany
                    ? _buildNewsDetailBody(context, w, h)
                    : const ChatListScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ 뉴스 상세 페이지 본문
  Widget _buildNewsDetailBody(BuildContext context, double w, double h) {
    return Consumer<CompanyNewsDetailProvider>(
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

        // 데이터 로드 완료
        return RefreshIndicator(
          onRefresh: () => provider.refresh(),
          child: SingleChildScrollView(
            controller: _scrollController,
            padding:
                EdgeInsets.symmetric(horizontal: AppSpacing.horizontal(context)),
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
                    horizontal: w * 0.05,
                    vertical: w * 0.045,
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
                        provider.title ?? '',
                        style: TextStyle(
                          fontSize: w * 0.055,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF143D60),
                        ),
                      ),

                      SizedBox(height: AppSpacing.small(context)),

                      /// ✅ 날짜 및 출처
                      Text(
                        provider.publishedAt ?? '',
                        style: TextStyle(
                          fontSize: w * 0.038,
                          color: Colors.grey,
                        ),
                      ),

                      if (provider.source != null) ...[
                        SizedBox(height: AppSpacing.small(context) * 0.5),
                        Text(
                          '출처: ${provider.source}',
                          style: TextStyle(
                            fontSize: w * 0.035,
                            color: Colors.grey,
                          ),
                        ),
                      ],

                      SizedBox(height: AppSpacing.medium(context)),

                      /// ✅ 본문 텍스트
                      Text(
                        provider.content ?? '',
                        style: TextStyle(
                          fontSize: w * 0.040,
                          height: 1.5,
                          color: const Color(0xFF333333),
                        ),
                      ),

                      SizedBox(height: AppSpacing.medium(context)),

                      /// ✅ 원문보기 / 채팅하기 버튼
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (provider.url != null)
                            TextButton(
                              onPressed: () {
                                // TODO: 원문 링크 열기
                                // launchUrl(Uri.parse(provider.url!));
                              },
                              child: Text(
                                '원문보기',
                                style: TextStyle(
                                  fontSize: w * 0.035,
                                  color: const Color(0xFFA9A9A9),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          SizedBox(width: w * 0.02),
                          TextButton(
                            onPressed: () {
                              // TODO: 채팅방으로 이동
                              // context.push('/chat/${widget.newsId}');
                            },
                            child: Text(
                              '채팅하기',
                              style: TextStyle(
                                fontSize: w * 0.035,
                                color: const Color(0xFFA9A9A9),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: AppSpacing.big(context)),

                      /// ✅ AI 말풍선 리스트
                      _buildAiComments(provider, w, h),
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

  /// ✅ AI 댓글 말풍선 리스트
  Widget _buildAiComments(
      CompanyNewsDetailProvider provider, double w, double h) {
    if (provider.aiComments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(provider.aiComments.length, (index) {
        final comment = provider.aiComments[index];
        return Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.small(context)),
          child: ChatBubble(
            text: comment['text'] ?? '',
            imagePath: comment['imagePath'] ?? '',
            w: w,
            h: h,
          ),
        );
      }),
    );
  }
}
