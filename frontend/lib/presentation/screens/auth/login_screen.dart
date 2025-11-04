import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/common/custom_back_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF7F8FB),
        leading: const CustomBackButton(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 33),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // 로그인 타이틀
              const Text(
                '로그인',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 32),

              // 이메일 입력
              CustomTextField(
                hintText: '이메일',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // 비밀번호 입력
              CustomTextField(
                hintText: '비밀번호',
                controller: passwordController,
                obscureText: true,
                showPasswordToggle: true,
              ),

              const Spacer(), // 🔽 남는 공간을 채워서 버튼을 아래로 밀어냄

              // 로그인 버튼
              CustomButton(
                text: '로그인',
                onPressed: () {
                  context.push('/persona-intro');
                },
              ),
              const SizedBox(height: 32), // 하단 여백
            ],
          ),
        ),
      ),
    );
  }
}
