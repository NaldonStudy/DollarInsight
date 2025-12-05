import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/models/chat_model.dart';
import '../../widgets/main/live_chat_card.dart';
import '../../providers/chat_provider.dart';
import '../test_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadSessions();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ChatProvider>().loadMoreSessions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        return RefreshIndicator(
          onRefresh: () => chatProvider.refresh(),
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.horizontal(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: AppSpacing.section(context)),

                /// 실시간 채팅 카드 (새 채팅 생성 버튼 역할)
                LiveChatCard(w: w, h: size.height),

                SizedBox(height: AppSpacing.big(context)),

                /// 채팅 목록 or 빈 상태
                _buildChatListContent(context, chatProvider, w),

                if (chatProvider.isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),

                SizedBox(height: AppSpacing.bottomLarge(context)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatListContent(
      BuildContext context, ChatProvider chatProvider, double w) {
    switch (chatProvider.state) {
      case ChatListState.loading:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ),
        );

      case ChatListState.error:
        return _buildErrorState(context, chatProvider);

      case ChatListState.loaded:
      case ChatListState.refreshing:
        if (chatProvider.isEmpty) {
          return _buildEmptyState(context, w);
        } else {
          return _buildChatList(context, chatProvider);
        }

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildErrorState(BuildContext context, ChatProvider chatProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              chatProvider.errorMessage ?? '오류가 발생했습니다',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => chatProvider.clearError(),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, double w) {
    return Column(
      children: [
        Center(
          child: Image.asset(
            "assets/images/main3.webp",
            width: w * 0.5,
          ),
        ),
        SizedBox(height: AppSpacing.small(context)),
        const Text(
          "아직 채팅이 없습니다\n지금 시작해 보세요!",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF757575),
            fontSize: 18,
          ),
        ),
        SizedBox(height: AppSpacing.medium(context)),
        ElevatedButton.icon(
          onPressed: () => context.go('/test-chat'),
          icon: const Icon(Icons.bug_report, color: Colors.white),
          label: const Text(
            'Chat API 테스트',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatList(BuildContext context, ChatProvider chatProvider) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: chatProvider.sessions.length,
      itemBuilder: (context, index) {
        final session = chatProvider.sessions[index];
        return _buildChatListItem(context, session);
      },
    );
  }

  Widget _buildChatListItem(BuildContext context, SessionItem session) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E8EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onChatTap(context, session),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: w * 0.13,
              height: w * 0.13,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.shade100,
                image: DecorationImage(
                  image: AssetImage(session.resolvedLogoAsset),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            SizedBox(width: w * 0.04),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildTopicTypeChip(session.topicType),
                      SizedBox(width: w * 0.015),
                      Expanded(
                        child: Text(
                          session.title,
                          style: TextStyle(
                            fontSize: w * 0.042,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F1F1F),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (session.ticker != null)
                        Row(
                          children: [
                            Icon(Icons.trending_up,
                                size: w * 0.04, color: Colors.green),
                            SizedBox(width: w * 0.01),
                            Text(
                              session.ticker!,
                              style: TextStyle(
                                fontSize: w * 0.038,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  SizedBox(height: h * 0.007),

                  Text(
                    _formatDateTime(session.updatedAt),
                    style: TextStyle(
                      fontSize: w * 0.032,
                      color: const Color(0xFF9BA1A6),
                    ),
                  ),
                ],
              ),
            ),

            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (value) => _onMenuSelected(context, session, value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18),
                      SizedBox(width: 8),
                      Text('삭제'),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTopicTypeChip(TopicType topicType) {
    Color chipColor;
    String label;

    switch (topicType) {
      case TopicType.company:
        chipColor = Colors.blue;
        label = '기업';
        break;
      case TopicType.news:
        chipColor = const Color(0xFF60A4DA);
        label = '뉴스';
        break;
      case TopicType.custom:
        chipColor = Colors.purple;
        label = '일반';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: chipColor,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) return '${difference.inDays}일 전';
    if (difference.inHours > 0) return '${difference.inHours}시간 전';
    if (difference.inMinutes > 0) return '${difference.inMinutes}분 전';
    return '방금 전';
  }

  void _onChatTap(BuildContext context, SessionItem session) {
    context.push('/chat/${session.sessionUuid}');
  }

  void _onMenuSelected(
      BuildContext context, SessionItem session, String value) {
    if (value == 'delete') {
      _showDeleteConfirmDialog(context, session);
    }
  }

  void _showDeleteConfirmDialog(
      BuildContext context, SessionItem session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('채팅 삭제'),
        content: Text(
          '${session.title} 채팅을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<ChatProvider>().deleteSession(session.sessionUuid);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
