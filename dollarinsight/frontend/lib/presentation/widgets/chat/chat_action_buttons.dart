// chat_action_buttons.dart
// 각 페이지에서 채팅 생성을 위한 버튼 위젯들

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/chat_provider.dart';

/// 기업 분석 페이지용 채팅 시작 버튼
class CompanyChatButton extends StatelessWidget {
  final String? ticker;
  final String? companyName;
  final VoidCallback? onChatCreated;

  const CompanyChatButton({
    super.key,
    this.ticker,
    this.companyName,
    this.onChatCreated,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _showCompanyChatDialog(context),
      icon: const Icon(Icons.chat_bubble_outline),
      label: const Text('AI와 분석하기'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showCompanyChatDialog(BuildContext context) {
    final defaultTitle = companyName != null && ticker != null
        ? '$companyName ($ticker) 분석'
        : ticker != null
            ? '$ticker 분석'
            : '기업 분석';

    showDialog(
      context: context,
      builder: (context) => _CompanyChatDialog(
        defaultTitle: defaultTitle,
        ticker: ticker,
        onChatCreated: onChatCreated,
      ),
    );
  }
}

/// 뉴스 페이지용 채팅 시작 버튼
class NewsChatButton extends StatelessWidget {
  final String? newsTitle;
  final int? newsId;
  final VoidCallback? onChatCreated;

  const NewsChatButton({
    super.key,
    this.newsTitle,
    this.newsId,
    this.onChatCreated,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _showNewsChatDialog(context),
      icon: const Icon(Icons.forum_outlined),
      label: const Text('뉴스 토론하기'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showNewsChatDialog(BuildContext context) {
    final defaultTitle = newsTitle != null
        ? '뉴스 토론: ${newsTitle!.length > 20 ? '${newsTitle!.substring(0, 20)}...' : newsTitle!}'
        : '뉴스 토론';

    showDialog(
      context: context,
      builder: (context) => _NewsChatDialog(
        defaultTitle: defaultTitle,
        newsId: newsId,
        onChatCreated: onChatCreated,
      ),
    );
  }
}

/// 기업 분석 채팅 생성 다이얼로그
class _CompanyChatDialog extends StatefulWidget {
  final String defaultTitle;
  final String? ticker;
  final VoidCallback? onChatCreated;

  const _CompanyChatDialog({
    required this.defaultTitle,
    this.ticker,
    this.onChatCreated,
  });

  @override
  State<_CompanyChatDialog> createState() => _CompanyChatDialogState();
}

class _CompanyChatDialogState extends State<_CompanyChatDialog> {
  late final TextEditingController _titleController;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.defaultTitle);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('기업 분석 채팅 시작'),
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
                hintText: '예: 애플 Q4 실적 분석',
              ),
              maxLength: 50,
              autofocus: true,
            ),
            if (widget.ticker != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '티커: ${widget.ticker}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _createCompanyChat,
          child: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('시작'),
        ),
      ],
    );
  }

  Future<void> _createCompanyChat() async {
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

    final response = await context.read<ChatProvider>().createCompanyChat(
      title: title,
      ticker: widget.ticker,
    );

    if (response != null && mounted) {
      Navigator.of(context).pop();
      widget.onChatCreated?.call();
      
      // 채팅방으로 이동
      context.go('/chat/${response.sessionUuid}');
    }

    if (mounted) {
      setState(() {
        _isCreating = false;
      });
    }
  }
}

/// 뉴스 채팅 생성 다이얼로그
class _NewsChatDialog extends StatefulWidget {
  final String defaultTitle;
  final int? newsId;
  final VoidCallback? onChatCreated;

  const _NewsChatDialog({
    required this.defaultTitle,
    this.newsId,
    this.onChatCreated,
  });

  @override
  State<_NewsChatDialog> createState() => _NewsChatDialogState();
}

class _NewsChatDialogState extends State<_NewsChatDialog> {
  late final TextEditingController _titleController;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.defaultTitle);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('뉴스 토론 시작'),
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
                hintText: '예: 테슬라 신모델 출시 소식',
              ),
              maxLength: 50,
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 16,
                    color: Colors.orange,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '이 뉴스에 대해 AI와 토론해보세요',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
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
          onPressed: _isCreating ? null : _createNewsChat,
          child: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('시작'),
        ),
      ],
    );
  }

  Future<void> _createNewsChat() async {
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

    final response = await context.read<ChatProvider>().createNewsChat(
      title: title,
      companyNewsId: widget.newsId,
    );

    if (response != null && mounted) {
      Navigator.of(context).pop();
      widget.onChatCreated?.call();
      
      // 채팅방으로 이동
      context.go('/chat/${response.sessionUuid}');
    }

    if (mounted) {
      setState(() {
        _isCreating = false;
      });
    }
  }
}

/// 플로팅 채팅 버튼 (어느 페이지에서나 사용 가능)
class FloatingChatButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const FloatingChatButton({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed ?? () => context.go('/chat-list'),
      backgroundColor: Theme.of(context).primaryColor,
      child: const Icon(
        Icons.chat,
        color: Colors.white,
      ),
    );
  }
}
