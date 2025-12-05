import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WithdrawalCompleteScreen extends StatelessWidget {
  const WithdrawalCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      body: SafeArea(
        child: Stack(
          children: [
            /// ✅ 중앙 이미지 (회원가입 완료와 동일한 방식)
            Positioned(
              left: w * 0.105,
              top: h * 0.18,
              child: Container(
                width: w * 0.79,
                height: w * 0.79,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/main9.webp"),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            /// ✅ 텍스트
            Positioned(
              top: h * 0.60,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    "다시 만나요",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: w * 0.075,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  SizedBox(height: h * 0.015),
                  Text(
                    "회원탈퇴가 완료되었습니다",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF757575),
                      fontSize: w * 0.045,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              ),
            ),

            /// ✅ 확인 버튼
            Positioned(
              bottom: h * 0.04,
              left: w * 0.09,
              right: w * 0.09,
              child: GestureDetector(
                onTap: () {
                  /// ✅ 탈퇴 완료 → 로그인 화면으로 이동
                  context.go('/login');
                },
                child: Container(
                  height: h * 0.065,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF143D60),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    "확인",
                    style: TextStyle(
                      color: const Color(0xFFF7F8FB),
                      fontSize: w * 0.045,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
