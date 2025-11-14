import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // 추가
import '../../../core/constants/app_spacing.dart';
import '../../widgets/main/live_chat_card.dart';
import '../test_chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final size = MediaQuery.of(context).size;
    final w = size.width;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.horizontal(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: AppSpacing.section(context)),

          /// ✅ 실시간 채팅카드
          LiveChatCard(w: w, h: size.height),

          SizedBox(height: AppSpacing.big(context)),

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

          SizedBox(height: AppSpacing.bottomLarge(context)),
        ],
      ),
    );
  }
}