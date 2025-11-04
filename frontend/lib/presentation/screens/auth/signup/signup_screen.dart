import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/common/custom_back_button.dart';
import '../../../widgets/common/custom_text_field.dart';
import '../../../widgets/common/custom_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  // 유효성 검증 상태
  String? _nicknameError;
  bool _nicknameValid = false;
  String? _emailError;
  bool _emailValid = false;
  String? _passwordError;
  bool _passwordValid = false;
  String? _passwordConfirmError;
  bool _passwordConfirmValid = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  // 이메일 유효성 검증
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // 비밀번호 유효성 검증 (영어, 숫자, 특수문자 필수)
  bool _isValidPassword(String password) {
    if (password.length < 8) return false;

    // 영어 포함 여부
    bool hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    // 숫자 포함 여부
    bool hasNumber = RegExp(r'[0-9]').hasMatch(password);
    // 특수문자 포함 여부
    bool hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

    return hasLetter && hasNumber && hasSpecial;
  }

  // 닉네임 유효성 검증
  void _validateNickname(String value) {
    setState(() {
      if (value.isEmpty) {
        _nicknameError = '닉네임을 입력해주세요';
        _nicknameValid = false;
      }
      else {
        _nicknameError = null;
        _nicknameValid = true;
      }
    });
  }

  // 이메일 유효성 검증
  void _validateEmail(String value) {
    setState(() {
      if (value.isEmpty) {
        _emailError = '이메일을 입력해주세요';
        _emailValid = false;
      } else if (!_isValidEmail(value)) {
        _emailError = '올바른 이메일 형식이 아닙니다';
        _emailValid = false;
      } else {
        _emailError = '사용 가능한 이메일입니다';
        _emailValid = true;
      }
    });
  }

  // 비밀번호 유효성 검증
  void _validatePassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _passwordError = '비밀번호를 입력해주세요';
        _passwordValid = false;
      } else if (!_isValidPassword(value)) {
        _passwordError = '숫자/영어/특수문자를 필수로 넣어야 합니다';
        _passwordValid = false;
      } else {
        _passwordError = null;
        _passwordValid = true;
      }

      // 비밀번호 확인란이 비어있지 않으면 다시 검증
      if (_passwordConfirmController.text.isNotEmpty) {
        _validatePasswordConfirm(_passwordConfirmController.text);
      }
    });
  }

  // 비밀번호 확인 유효성 검증
  void _validatePasswordConfirm(String value) {
    setState(() {
      if (value.isEmpty) {
        _passwordConfirmError = '비밀번호 확인을 입력해주세요';
        _passwordConfirmValid = false;
      } else if (value != _passwordController.text) {
        _passwordConfirmError = '비밀번호가 일치하지 않습니다';
        _passwordConfirmValid = false;
      } else {
        _passwordConfirmError = '비밀번호가 일치합니다';
        _passwordConfirmValid = true;
      }
    });
  }

  // 회원가입 처리
  void _handleSignup() {
    // 모든 필드 유효성 검증
    _validateNickname(_nicknameController.text);
    _validateEmail(_emailController.text);
    _validatePassword(_passwordController.text);
    _validatePasswordConfirm(_passwordConfirmController.text);

    // 모든 필드가 유효한 경우에만 다음 페이지로 이동
    if (_nicknameValid && _emailValid && _passwordValid && _passwordConfirmValid) {
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
                controller: _nicknameController,
                onChanged: _validateNickname,
              ),
              if (_nicknameError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 2),
                  child: Text(
                    _nicknameError!,
                    style: TextStyle(
                      color: _nicknameValid ? const Color(0xFF31C275) : const Color(0xFFFF0000),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.45,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // 이메일 입력
              CustomTextField(
                hintText: '이메일',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: _validateEmail,
              ),
              if (_emailError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 2),
                  child: Text(
                    _emailError!,
                    style: TextStyle(
                      color: _emailValid ? const Color(0xFF31C275) : const Color(0xFFFF0000),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.45,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // 비밀번호 입력
              CustomTextField(
                hintText: '비밀번호',
                controller: _passwordController,
                obscureText: true,
                showPasswordToggle: true,
                onChanged: _validatePassword,
              ),
              if (_passwordError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 2),
                  child: Text(
                    _passwordError!,
                    style: TextStyle(
                      color: _passwordValid ? const Color(0xFF31C275) : const Color(0xFFFF0000),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.45,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // 비밀번호 확인 입력
              CustomTextField(
                hintText: '비밀번호 확인',
                controller: _passwordConfirmController,
                obscureText: true,
                showPasswordToggle: true,
                onChanged: _validatePasswordConfirm,
              ),
              if (_passwordConfirmError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 2),
                  child: Text(
                    _passwordConfirmError!,
                    style: TextStyle(
                      color: _passwordConfirmValid ? const Color(0xFF31C275) : const Color(0xFFFF0000),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.45,
                    ),
                  ),
                ),
              const SizedBox(height: 56),

              // 회원가입 버튼
              CustomButton(
                text: '회원가입',
                onPressed: _handleSignup,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}