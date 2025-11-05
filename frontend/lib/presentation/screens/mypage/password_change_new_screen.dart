import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/custom_back_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';
import '../../providers/password_change_provider.dart';
import '../../../../data/models/signup_form_state.dart';

class PasswordChangeNewScreen extends StatelessWidget {
  const PasswordChangeNewScreen({super.key});

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
            resizeToAvoidBottomInset: true, // ✅ 키보드 올라올 때 자동 대응
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
                      '새로운 비밀번호를\n입력해주세요',
                      style: TextStyle(
                        fontSize: w * 0.072,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),

                    SizedBox(height: h * 0.04),

                    /// ✅ 스크롤 가능 영역
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// ✅ 새 비밀번호
                            CustomTextField(
                              hintText: '새 비밀번호',
                              controller: provider.passwordController,
                              obscureText: true,
                              showPasswordToggle: true,
                              onChanged: provider.validatePassword,
                            ),
                            _validation(provider.state.password),
                            SizedBox(height: h * 0.02),

                            /// ✅ 새 비밀번호 확인
                            CustomTextField(
                              hintText: '비밀번호 확인',
                              controller: provider.passwordConfirmController,
                              obscureText: true,
                              showPasswordToggle: true,
                              onChanged: provider.validatePasswordConfirm,
                            ),
                            _validation(provider.state.passwordConfirm),

                            SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),

                    /// ✅ 하단 버튼 (회원가입과 동일 구조)
                    CustomButton(
                      text: "확인",
                      onPressed: () {
                        if (provider.validateAll()) {

                          // ✅ 라우팅: 마이페이지로 이동
                          Navigator.popUntil(
                              context, (route) => route.settings.name == 'mypage');

                          // ✅ 성공 스낵바
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("비밀번호가 변경되었습니다"),
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

  /// ✅ 회원가입 Validation UI 그대로 복사
  Widget _validation(FieldValidationState state) {
    if (!state.hasBeenTouched) return const SizedBox.shrink();

    if (state.isValid) {
      return const Padding(
        padding: EdgeInsets.only(top: 8, left: 2),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF31C275), size: 16),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 2),
      child: Text(
        state.errorMessage ?? '',
        style: const TextStyle(
          color: Color(0xFFFF0000),
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.45,
        ),
      ),
    );
  }
}
