import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../widgets/common/custom_back_button.dart';
import '../../../widgets/common/custom_text_field.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../providers/signup_form_provider.dart';
import '../../../../data/models/signup_form_state.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  void _handleSignup(BuildContext context, SignupFormProvider provider) {
    // 모든 필드 유효성 검증
    if (provider.validateAll()) {
      context.push('/signup/watchlist');
    } else {
      // 유효하지 않은 경우 스낵바로 안내
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('모든 필드를 올바르게 입력해주세요'),
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
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 33),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // 회원가입 타이틀
                    const Text(
                      '회원가입',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 닉네임 입력
                    CustomTextField(
                      hintText: '닉네임',
                      controller: provider.nicknameController,
                      onChanged: provider.validateNickname,
                    ),
                    _buildValidationFeedback(provider.state.nickname),
                    const SizedBox(height: 16),

                    // 이메일 입력
                    CustomTextField(
                      hintText: '이메일',
                      controller: provider.emailController,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: provider.validateEmail,
                    ),
                    _buildValidationFeedback(provider.state.email),
                    const SizedBox(height: 16),

                    // 비밀번호 입력
                    CustomTextField(
                      hintText: '비밀번호',
                      controller: provider.passwordController,
                      obscureText: true,
                      showPasswordToggle: true,
                      onChanged: provider.validatePassword,
                    ),
                    _buildValidationFeedback(provider.state.password),
                    const SizedBox(height: 16),

                    // 비밀번호 확인 입력
                    CustomTextField(
                      hintText: '비밀번호 확인',
                      controller: provider.passwordConfirmController,
                      obscureText: true,
                      showPasswordToggle: true,
                      onChanged: provider.validatePasswordConfirm,
                    ),
                    _buildValidationFeedback(provider.state.passwordConfirm),
                    const SizedBox(height: 56),

                    // 회원가입 버튼
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

  /// 유효성 검증 피드백을 표시하는 위젯
  Widget _buildValidationFeedback(FieldValidationState state) {
    // 입력을 시작하지 않았거나 유효한 경우에는 아무것도 표시하지 않음
    if (!state.hasBeenTouched) {
      return const SizedBox.shrink();
    }

    if (state.isValid) {
      // 유효한 경우 초록색 체크 아이콘 표시
      return Padding(
        padding: const EdgeInsets.only(top: 8, left: 2),
        child: Row(
          children: const [
            Icon(
              Icons.check_circle,
              color: Color(0xFF31C275),
              size: 16,
            ),
          ],
        ),
      );
    } else if (state.errorMessage != null) {
      // 유효하지 않은 경우 빨간색 에러 메시지 표시
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