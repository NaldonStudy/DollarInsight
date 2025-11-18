import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/chat_model.dart';
import '../../providers/chat_provider.dart';

class CreateChatDialog extends StatefulWidget {
  const CreateChatDialog({super.key});

  @override
  State<CreateChatDialog> createState() => _CreateChatDialogState();
}

class _CreateChatDialogState extends State<CreateChatDialog> {
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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '채팅 제목',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '기업 분석이나 뉴스 관련 채팅은 해당 페이지에서 시작해주세요.',
            style: TextStyle(fontSize: 12),
          )
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _createChat,
          child: _isCreating
              ? const CircularProgressIndicator()
              : const Text('생성'),
        ),
      ],
    );
  }

  Future<void> _createChat() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isCreating = true);

    final response = await context.read<ChatProvider>().createSession(
      topicType: TopicType.custom,
      title: title,
    );

    if (response != null && mounted) {
      Navigator.pop(context);
      context.push('/chat/${response.sessionUuid}');
    }
  }
}
