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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        height: 335,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: const Color(0xFFF7F8FB),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 33, vertical: 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '새 채팅 생성',
                style: TextStyle(
                  color: Color(0xFF5A5A5A),
                  fontSize: 20,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  height: 1.40,
                ),
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                height: 62,
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(
                      width: 1,
                      color: Color(0xFFD9D9D9),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: TextField(
                  controller: _titleController,
                  style: const TextStyle(
                    color: Color(0xFF5A5A5A),
                    fontSize: 20,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                    height: 1.40,
                    letterSpacing: 0.60,
                  ),
                  decoration: const InputDecoration(
                    hintText: '채팅제목을 입력해주세요',
                    hintStyle: TextStyle(
                      color: Color(0xFF757575),
                      fontSize: 20,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                      height: 1.40,
                      letterSpacing: 0.60,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.fromLTRB(15, 17, 15, 17),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                '기업분석이나 뉴스 관련 채팅은\n해당 페이지에서 시작해주세요',
                style: TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 15,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                  height: 1.40,
                  letterSpacing: 0.45,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _isCreating ? null : () => Navigator.pop(context),
                    child: Container(
                      width: 100,
                      height: 30,
                      alignment: Alignment.center,
                      child: const Text(
                        '취소',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF60A4DA),
                          fontSize: 16,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                          height: 1.40,
                          letterSpacing: 0.48,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _isCreating ? null : _createChat,
                    child: Container(
                      width: 100,
                      height: 30,
                      decoration: ShapeDecoration(
                        color: const Color(0xFF60A4DA),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: _isCreating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF7F8FB)),
                              ),
                            )
                          : const Text(
                              '채팅시작',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFF7F8FB),
                                fontSize: 16,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w700,
                                height: 1.40,
                                letterSpacing: 0.48,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
