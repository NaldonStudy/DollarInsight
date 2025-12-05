import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/common/custom_back_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';
import '../../providers/password_change_provider.dart';

class PasswordChangeNewScreen extends StatelessWidget {
  const PasswordChangeNewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final oldPassword = GoRouterState.of(context).extra as String;

    return ChangeNotifierProvider(
      create: (_) => PasswordChangeProvider(),
      child: Consumer<PasswordChangeProvider>(
        builder: (context, provider, child) {
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
                      '새로운 비밀번호를\n입력해주세요',
                      style: TextStyle(
                        fontSize: w * 0.072,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: h * 0.04),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            CustomTextField(
                              hintText: '새 비밀번호',
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
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            SizedBox(height: h * 0.02),
                            CustomTextField(
                              hintText: '비밀번호 확인',
                              controller: provider.passwordConfirmController,
                              obscureText: true,
                              showPasswordToggle: true,
                              onChanged: provider.validatePasswordConfirm,
                            ),
                            if (provider.passwordConfirmError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8, left: 2),
                                child: Text(
                                  provider.passwordConfirmError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    provider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : CustomButton(
                      text: "확인",
                      onPressed: () async {
                        if (!provider.validateAll()) return;
                        try {
                          await provider.changePassword(
                            oldPassword,
                            provider.passwordController.text,
                          );

                          // ✅ 성공 시 마이페이지로 이동
                          Navigator.popUntil(
                            context,
                                (route) => route.settings.name == 'mypage',
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("비밀번호가 변경되었습니다."),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } catch (_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("비밀번호 변경에 실패했습니다."),
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
