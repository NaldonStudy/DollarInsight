import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../widgets/common/custom_back_button.dart';
import '../../../widgets/common/custom_text_field.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../providers/signup_form_provider.dart';
import '../../../../data/models/signup_form_state.dart';
import '../../../providers/auth_provider.dart';


class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  void _handleSignup(BuildContext context, SignupFormProvider provider) async {
    if (!provider.validateAll()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('모든 필드를 올바르게 입력해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();

    try {
      // ✅ API 요청 발생
      await auth.signup(
        email: provider.emailController.text.trim(),
        nickname: provider.nicknameController.text.trim(),
        password: provider.passwordController.text.trim(),
        pushEnabled: true, // 기기 푸시 사용 여부, 기본 true로 설정
      );

      // ✅ 성공 시 다음 단계로 이동
      context.push('/signup/watchlist-industry');

    } catch (e) {
      // ✅ 실패 시 에러 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SignupFormProvider(),
      child: Consumer<SignupFormProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF7F8FB),
            appBar: AppBar(
              elevation: 0,
              backgroundColor: const Color(0xFFF7F8FB),
              leading: const CustomBackButton(),
            ),

            /// ✅ 버튼을 하단 고정시키기 위해 Column 재구성
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 33),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// ✅ 상단 여백 + 타이틀
                    const SizedBox(height: 20),
                    const Text(
                      '회원가입',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 32),

                    /// ✅ 입력폼은 스크롤 가능 영역
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 닉네임
                            CustomTextField(
                              hintText: '닉네임',
                              controller: provider.nicknameController,
                              onChanged: provider.validateNickname,
                            ),
                            _buildValidationFeedback(provider.state.nickname),
                            const SizedBox(height: 16),

                            // 이메일
                            CustomTextField(
                              hintText: '이메일',
                              controller: provider.emailController,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: provider.validateEmail,
                            ),
                            _buildValidationFeedback(provider.state.email),
                            const SizedBox(height: 16),

                            // 비밀번호
                            CustomTextField(
                              hintText: '비밀번호',
                              controller: provider.passwordController,
                              obscureText: true,
                              showPasswordToggle: true,
                              onChanged: provider.validatePassword,
                            ),
                            _buildValidationFeedback(provider.state.password),
                            const SizedBox(height: 16),

                            // 비밀번호 확인
                            CustomTextField(
                              hintText: '비밀번호 확인',
                              controller: provider.passwordConfirmController,
                              obscureText: true,
                              showPasswordToggle: true,
                              onChanged: provider.validatePasswordConfirm,
                            ),
                            _buildValidationFeedback(provider.state.passwordConfirm),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),

                    /// ✅ 하단 버튼 고정
                    CustomButton(
                      text: '회원가입',
                      onPressed: () => _handleSignup(context, provider),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildValidationFeedback(FieldValidationState state) {
    if (!state.hasBeenTouched) return const SizedBox.shrink();

    if (state.isValid) {
      return const Padding(
        padding: EdgeInsets.only(top: 8, left: 2),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Color(0xFF31C275),
              size: 16,
            ),
          ],
        ),
      );
    } else if (state.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8, left: 2),
        child: Text(
          state.errorMessage!,
          style: const TextStyle(
            color: Color(0xFFFF0000),
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.45,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
