import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/chat/create_chat_dialog.dart';

class LiveChatCard extends StatelessWidget {
  final double w;
  final double h;

  const LiveChatCard({
    super.key,
    required this.w,
    required this.h,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => const CreateChatDialog(),  // ← 공용 다이얼로그 사용
        );
      },
      child: Container(
        height: h * 0.12,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            Positioned(
              left: w * 0.05,
              top: h * 0.03,
              child: const Text(
                "실시간 채팅 참여하기",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF757575),
                ),
              ),
            ),
            Positioned(
              left: w * 0.05,
              top: h * 0.066,
              child: const Text(
                "검색어를 입력해주세요",
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF757575),
                ),
              ),
            ),
            Positioned(
              right: w * 0.06,
              top: h * 0.01,
              child: Image.asset(
                "assets/images/main4.webp",
                width: w * 0.28,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
