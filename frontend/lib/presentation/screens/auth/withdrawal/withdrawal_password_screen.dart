import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/common/custom_back_button.dart';
import '../../../widgets/common/custom_text_field.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../providers/password_change_provider.dart';
import 'package:go_router/go_router.dart';

class WithdrawalPasswordScreen extends StatelessWidget {
  const WithdrawalPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PasswordChangeProvider(),
      child: Consumer<PasswordChangeProvider>(
        builder: (context, provider, child) {
          final size = MediaQuery.of(context).size;
          final w = size.width;
          final h = size.height;

          return Scaffold(
            resizeToAvoidBottomInset: true,
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

                    /// ✅ 제목
                    Text(
                      '현재 비밀번호를\n입력해주세요',
                      style: TextStyle(
                        fontSize: w * 0.072,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),

                    SizedBox(height: h * 0.04),

                    /// ✅ 입력 영역
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextField(
                              hintText: '비밀번호',
                              controller: provider.passwordController,
                              obscureText: true,
                              showPasswordToggle: true,
                              onChanged: provider.validatePassword,
                            ),
                            if (provider.passwordError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8, left: 2),
                                child: Text(
                                  provider.passwordError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),

                    /// ✅ 확인 버튼
                    CustomButton(
                      text: "확인",
                      onPressed: () {
                        if (provider.passwordError == null &&
                            provider.passwordController.text.isNotEmpty) {
                          // ✅ 실제 탈퇴 API 자리
                          // TODO: provider.withdrawal(password)
                          context.push('/withdrawal/complete');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("비밀번호를 올바르게 입력해주세요"),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),

                    SizedBox(height: h * 0.04),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
