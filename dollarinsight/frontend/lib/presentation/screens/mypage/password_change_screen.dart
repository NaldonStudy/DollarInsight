import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/common/custom_back_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';

class PasswordChangeScreen extends StatelessWidget {
  const PasswordChangeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                '현재 비밀번호를\n입력해주세요',
                style: TextStyle(
                  fontSize: w * 0.072,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              SizedBox(height: h * 0.04),
              CustomTextField(
                hintText: '비밀번호',
                controller: passwordController,
                obscureText: true,
                showPasswordToggle: true,
              ),
              const Spacer(),
              CustomButton(
                text: '다음',
                onPressed: () {
                  if (passwordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("비밀번호를 입력해주세요")),
                    );
                    return;
                  }
                  // ✅ oldPassword를 다음 화면으로 전달
                  context.push(
                    '/mypage/password-change/password-change-new',
                    extra: passwordController.text,
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
