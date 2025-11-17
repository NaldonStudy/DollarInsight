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
    
    // 화면 진입 시 세션 목록 로드
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
      // 스크롤이 끝에서 200px 전에 도달하면 더 로드
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
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.horizontal(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: AppSpacing.section(context)),

                /// ✅ 실시간 채팅카드
                LiveChatCard(w: w, h: size.height),

                SizedBox(height: AppSpacing.big(context)),

                /// 새 채팅 생성 버튼
                _buildCreateChatButton(context),

                SizedBox(height: AppSpacing.medium(context)),

                /// ✅ 채팅 목록 또는 빈 상태
                _buildChatListContent(context, chatProvider, w),

                /// ✅ 로딩 더보기 인디케이터
                if (chatProvider.isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(),
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

  Widget _buildCreateChatButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showCreateChatDialog(context),
          icon: const Icon(Icons.add_comment, color: Colors.white),
          label: const Text(
            '새 채팅 시작하기',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4285F4),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
      ),
    );
  }


  Widget _buildChatListContent(BuildContext context, ChatProvider chatProvider, double w) {
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

      case ChatListState.initial:
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
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              chatProvider.errorMessage ?? '오류가 발생했습니다',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
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
        /// ✅ 빈 채팅 이미지
        Center(
          child: Image.asset(
            "assets/images/main3.webp",
            width: w * 0.5,
          ),
        ),

        SizedBox(height: AppSpacing.small(context)),

        /// ✅ 안내 텍스트
        const Center(
          child: Text(
            "아직 채팅이 없습니다\n지금 시작해 보세요!",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF757575),
              fontSize: 18,
            ),
          ),
        ),

        SizedBox(height: AppSpacing.medium(context)),

        /// 🚀 Chat API 테스트 버튼 (개발용)
        Center(
          child: ElevatedButton.icon(
            onPressed: () {
              // GoRouter로 테스트 화면 이동
              context.go('/test-chat');
            },
            icon: const Icon(Icons.bug_report, color: Colors.white),
            label: const Text(
              'Chat API 테스트',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
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
    /// 화면 크기 비율 가져오기
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
            /// ------------------------
            /// 왼쪽 기업 로고 (원형)
            /// ------------------------
            Container(
              width: w * 0.13,  // 반응형: 52 → 화면 비율
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

            SizedBox(width: w * 0.04), // 반응형 간격

            /// ------------------------
            /// 오른쪽 텍스트 영역
            /// ------------------------
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// --------------------------
                  /// 1줄: Chip + 제목 + 티커
                  /// --------------------------
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildTopicTypeChip(session.topicType),

                      SizedBox(width: w * 0.015),

                      /// ✔ 제목
                      Expanded(
                        child: Text(
                          session.title,
                          style: TextStyle(
                            fontSize: w * 0.042, // 반응형 텍스트
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F1F1F),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      /// ✔ 티커 (오른쪽 정렬)
                      if (session.ticker != null)
                        Row(
                          children: [
                            SizedBox(width: w * 0.015),

                            Icon(
                              Icons.trending_up,
                              size: w * 0.04,
                              color: Colors.green,
                            ),

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

                  /// --------------------------
                  /// 2줄: 날짜
                  /// --------------------------
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


            /// ------------------------
            /// 메뉴 버튼
            /// ------------------------
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (value) =>
                  _onMenuSelected(context, session, value),
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
        chipColor = const Color(0xFF60A4DA);   // 🔥 뉴스만 지정한 색상
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
        color: chipColor.withOpacity(0.1),  // 배경
        borderRadius: BorderRadius.circular(12),
        // 테두리 제거했으면 border 삭제됨
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

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  void _onChatTap(BuildContext context, SessionItem session) {
    // 채팅 화면으로 이동
    context.go('/chat/${session.sessionUuid}');
  }

  void _onMenuSelected(BuildContext context, SessionItem session, String value) {
    switch (value) {
      case 'delete':
        _showDeleteConfirmDialog(context, session);
        break;
    }
  }

  void _showDeleteConfirmDialog(BuildContext context, SessionItem session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('채팅 삭제'),
        content: Text('${session.title} 채팅을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
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

  void _showCreateChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _CreateChatDialog(),
    );
  }
}

class _CreateChatDialog extends StatefulWidget {
  @override
  State<_CreateChatDialog> createState() => _CreateChatDialogState();
}

class _CreateChatDialogState extends State<_CreateChatDialog> {
  final _titleController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('새 채팅 생성'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '채팅 제목',
                border: OutlineInputBorder(),
                hintText: '예: 내 투자 전략 상담',
              ),
              maxLength: 50,
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '기업 분석이나 뉴스 관련 채팅은 해당 페이지에서 시작해주세요.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _createChat,
          child: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('생성'),
        ),
      ],
    );
  }

  Future<void> _createChat() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('채팅 제목을 입력해주세요')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    // 채팅 리스트에서 생성하는 채팅은 항상 CUSTOM 유형
    final response = await context.read<ChatProvider>().createSession(
      topicType: TopicType.custom,
      title: title,
    );

    if (response != null && mounted) {
      Navigator.of(context).pop();
      // 채팅방으로 이동
      context.push('/chat/${response.sessionUuid}');
    }

    if (mounted) {
      setState(() {
        _isCreating = false;
      });
    }
  }
}
