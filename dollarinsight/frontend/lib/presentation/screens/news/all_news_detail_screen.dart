import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_spacing.dart';
import '../../widgets/common/top_navigation.dart';
import '../../widgets/main/live_chat_card.dart';
import '../chat/chat_list_screen.dart';
import '../../widgets/chat/chat_bubble.dart';
import '../../widgets/common/scroll_fab_button.dart';
import '../../providers/all_news_detail_provider.dart';
import '../../providers/chat_provider.dart';

class AllNewsDetailScreen extends StatefulWidget {
  final String newsId;

  const AllNewsDetailScreen({
    super.key,
    required this.newsId,
  });

  @override
  State<AllNewsDetailScreen> createState() => _AllNewsDetailScreenState();
}

class _AllNewsDetailScreenState extends State<AllNewsDetailScreen> {
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

  /// URL 열기 함수
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('링크를 열 수 없습니다')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return ChangeNotifierProvider(
      create: (_) => AllNewsDetailProvider(newsId: widget.newsId),
      child: Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),

      body: SafeArea(
        child: Stack(
          children: [
            Column(
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
            
            /// ✅ 스크롤 업 FAB
            Positioned(
              right: w * 0.05,
              bottom: w * 0.05,
              child: ScrollFabButton(
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
            ),
          ],
        ),
      ),
      ),
    );
  }

  /// 뉴스 상세 페이지 본문
  Widget _buildNewsDetailBody(BuildContext context, double w, double h) {
    return Consumer<AllNewsDetailProvider>(
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
      controller: _scrollController, // ✅ 반드시 연결
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
                /// 뉴스 제목
                Text(
                  provider.title ?? '',
                  style: TextStyle(
                    fontSize: w * 0.055,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF143D60),
                  ),
                ),

                SizedBox(height: AppSpacing.small(context)),

                /// 날짜
                Text(
                  provider.publishedAt ?? '',
                  style: TextStyle(fontSize: w * 0.038, color: Colors.grey),
                ),

                SizedBox(height: AppSpacing.medium(context)),

                /// 요약 텍스트 (summary)
                Text(
                  provider.summary ?? '',
                  style: TextStyle(
                    fontSize: w * 0.040,
                    height: 1.5,
                    color: const Color(0xFF333333),
                  ),
                ),

                SizedBox(height: AppSpacing.medium(context)),

                /// 원문보기 / 채팅하기 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (provider.url != null)
                      TextButton(
                        onPressed: () => _launchUrl(provider.url!),
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
                      onPressed: () async {
                        // 뉴스 기반 채팅 세션 생성
                        final chatProvider = context.read<ChatProvider>();
                        
                        // 로딩 표시
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                        
                        try {
                          final response = await chatProvider.createNewsChat(
                            title: provider.title ?? '뉴스 채팅',
                            companyNewsId: int.tryParse(widget.newsId),
                          );
                          
                          if (!mounted) return;
                          Navigator.pop(context); // 로딩 닫기
                          
                          if (response != null) {
                            // 세션 생성 성공 - 자동 메시지와 함께 채팅방으로 이동
                            final newsTitle = provider.title ?? '뉴스';
                            final autoMessage = '$newsTitle 뉴스에 대해 어떻게 생각해?';
                            
                            // URI 인코딩하여 전달
                            final encodedMessage = Uri.encodeComponent(autoMessage);
                            context.push('/chat/${response.sessionUuid}?autoMessage=$encodedMessage');
                          } else {
                            // 세션 생성 실패
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('채팅방 생성에 실패했습니다.'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (!mounted) return;
                          Navigator.pop(context); // 로딩 닫기
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('오류가 발생했습니다: $e'),
                            ),
                          );
                        }
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

                /// AI 멤버별 반응 섹션
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

  /// AI 댓글 말풍선 리스트
  Widget _buildAiComments(
      AllNewsDetailProvider provider, double w, double h) {
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
