import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF7F8FB),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(), // ✅ 이전 화면으로 돌아가기
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '로그인',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: height * 0.04),

            /// 이메일 입력
            TextField(
              decoration: InputDecoration(
                hintText: '이메일',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              keyboardType: TextInputType.emailAddress, // ✅ 키보드 자동 이메일 형식
            ),
            SizedBox(height: height * 0.02),

            /// 비밀번호 입력
            TextField(
              decoration: InputDecoration(
                hintText: '비밀번호',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              obscureText: true, // ✅ 비밀번호 가리기
            ),
            SizedBox(height: height * 0.05),

            /// 로그인 버튼
            SizedBox(
              width: double.infinity,
              height: height * 0.065,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF143D60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  // ✅ 로그인 처리 후 페이지 쌓기
                  context.push('/persona-intro');
                },
                child: const Text(
                  '로그인',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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
