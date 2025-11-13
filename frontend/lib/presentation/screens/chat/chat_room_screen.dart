import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/common/custom_back_button.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _formatTime(DateTime time) {
    return DateFormat('a h:mm', 'ko_KR').format(time);
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy년 MM월 dd일', 'ko_KR').format(date);
  }

  // ✅ 메시지 리스트 (동적)
  final List<Map<String, dynamic>> messages = [];

  // ✅ AI 입력 중 상태
  bool isAITyping = false;

  // ✅ 자동 스크롤 함수
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ✅ 메시지 전송 함수
  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    final userText = _controller.text.trim();
    _controller.clear();

    // ✅ 사용자 메시지 추가
    setState(() {
      messages.add({
        "type": "me",
        "text": userText,
        "time": _formatTime(DateTime.now()),
      });
    });

    _scrollToBottom();

    // ✅ AI typing 시작
    setState(() => isAITyping = true);

    // ✅ 1.5초 뒤 AI 응답 추가 (mock)
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      setState(() {
        isAITyping = false;
        messages.add({
          "type": "ai",
          "name": "희열",
          "profile": "assets/images/heeyul.webp",
          "text": "음... 나는 아직 좀 기다릴래!",
          "time": _formatTime(DateTime.now()),
        });
      });

      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),

      // ✅ AppBar
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FB),
        elevation: 0,
        leading: const CustomBackButton(iconColor: Colors.black87),
        centerTitle: true,
        title: Text(
          _formatDate(DateTime.now()),
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF7E909A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            // ✅ 채팅 영역
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                children: [
                  _buildStartMessage(),
                  const SizedBox(height: 20),

                  // ✅ 동적 메시지 목록
                  for (var msg in messages)
                    msg["type"] == "me"
                        ? _buildMyBubble(text: msg["text"], time: msg["time"])
                        : _buildFriendBubble(
                            name: msg["name"],
                            text: msg["text"],
                            time: msg["time"],
                            profile: msg["profile"],
                          ),

                  // ✅ AI typing indicator
                  if (isAITyping)
                    _buildFriendBubble(
                      name: "희열",
                      text: "입력중 ...",
                      time: "",
                      profile: "assets/images/heeyul.webp",
                    ),
                ],
              ),
            ),

            // ✅ 입력창
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------

  Widget _buildStartMessage() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        "채팅이 시작되었습니다.",
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF757575),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ✅ 내가 보낸 메시지
  Widget _buildMyBubble({required String text, required String time}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ✅ 시간을 왼쪽에 배치
          Text(
            time,
            style: const TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
          ),
          const SizedBox(width: 6),

          // ✅ 말풍선
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFC8E2F6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Color(0xFF9BA9B0), width: 0.5),
            ),
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, color: Color(0xFF21272A)),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ 상대 말풍선
  Widget _buildFriendBubble({
    required String name,
    required String text,
    required String time,
    required String profile,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ 캐릭터 이미지
          Image.asset(profile, width: 36, height: 36),

          const SizedBox(width: 8),

          // ✅ 말풍선 + 시간 (왼쪽 정렬)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이름
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7E909A),
                  ),
                ),

                const SizedBox(height: 4),

                // ✅ 말풍선 + 시간 (열 구조)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 말풍선
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Color(0xFF9BA9B0),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        text,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF21272A),
                        ),
                      ),
                    ),

                    // 간격
                    const SizedBox(width: 6),

                    // ✅ 시간: 말풍선 하단에 정렬되도록 crossAxisAlignment.end 적용
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFBBBBBB),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ 메시지 입력창
  Widget _buildMessageInput() {
    return Container(
      color: const Color(0xFFF7F8FB),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                // ✅ 기본 한 줄
                maxLines: 5,
                // ✅ 최대 다섯 줄까지 자동 증가
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "메시지 입력",
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: Color(0xFF757575)),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
