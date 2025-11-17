import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/chat_model.dart';
import '../../../presentation/providers/chat_provider.dart';

class CreateChatDialog extends StatefulWidget {
  const CreateChatDialog({super.key});

  @override
  State<CreateChatDialog> createState() => _CreateChatDialogState();
}

class _CreateChatDialogState extends State<CreateChatDialog> {
  final TextEditingController _titleController = TextEditingController();
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
