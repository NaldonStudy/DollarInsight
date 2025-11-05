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

    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),

      // ✅ 앱바 반응형
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF7F8FB),
        leading: const CustomBackButton(),
      ),

      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.091), // 33/360
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              SizedBox(height: h * 0.025), // 20px

              // ✅ 로그인 타이틀 (30px → 반응형)
              Text(
                '로그인',
                style: TextStyle(
                  fontSize: w * 0.083, // 30px 기준
                  fontWeight: FontWeight.w700,
                ),
              ),

              SizedBox(height: h * 0.04), // 32px

              // ✅ 이메일 입력
              CustomTextField(
                hintText: '이메일',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
              ),

              SizedBox(height: h * 0.02), // 16px

              // ✅ 비밀번호 입력
              CustomTextField(
                hintText: '비밀번호',
                controller: passwordController,
                obscureText: true,
                showPasswordToggle: true,
              ),

              const Spacer(),

              // ✅ 로그인 버튼 (너비는 내부에서 처리)
              CustomButton(
                text: '로그인',
                onPressed: () {
                  context.push('/persona-intro');
                },
              ),

              SizedBox(height: h * 0.04), // 32px
            ],
          ),
        ),
      ),
    );
  }
}
