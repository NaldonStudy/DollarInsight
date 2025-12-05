import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../widgets/common/custom_back_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';
import '../../providers/auth_provider.dart';

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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF7F8FB),
        leading: const CustomBackButton(),
      ),

      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.091),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: h * 0.025),

              Text(
                '로그인',
                style: TextStyle(
                  fontSize: w * 0.083,
                  fontWeight: FontWeight.w700,
                ),
              ),

              SizedBox(height: h * 0.04),

              // ✅ 이메일 입력
              CustomTextField(
                hintText: '이메일',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
              ),

              SizedBox(height: h * 0.02),

              // ✅ 비밀번호 입력
              CustomTextField(
                hintText: '비밀번호',
                controller: passwordController,
                obscureText: true,
                showPasswordToggle: true,
              ),

              const Spacer(),

              // ✅ 로그인 버튼
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return CustomButton(
                    text: auth.isLoading ? '로그인 중...' : '로그인',
                    onPressed: auth.isLoading
                        ? null
                        : () async {
                      try {
                        await auth.login(
                          email: emailController.text.trim(),
                          password: passwordController.text.trim(),
                        );

                        // ✅ 로그인 성공 → 메인 이동
                        context.go('/main');

                      } catch (e) {
                        // ✅ 로그인 실패 팝업
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  );
                },
              ),

              SizedBox(height: h * 0.04),
            ],
          ),
        ),
      ),
    );
  }
}
