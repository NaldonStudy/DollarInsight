import 'package:flutter/material.dart';
import '../../data/models/signup_form_state.dart';

class PasswordChangeProvider extends ChangeNotifier {
  // ✅ 회원가입 구조를 그대로 유지
  SignupFormState _state = SignupFormState.initial();

  SignupFormState get state => _state;

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmController = TextEditingController();

  @override
  void dispose() {
    passwordController.dispose();
    passwordConfirmController.dispose();
    super.dispose();
  }

  /// 비밀번호 규칙 (Signup과 동일)
  bool _isValidPassword(String password) {
    if (password.length < 8) return false;

    bool hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    bool hasNumber = RegExp(r'[0-9]').hasMatch(password);
    bool hasSpecial =
    RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

    return hasLetter && hasNumber && hasSpecial;
  }

  /// ✅ 새 비밀번호 유효성 검증
  void validatePassword(String value) {
    if (value.isEmpty) {
      _state = _state.copyWith(
        password: FieldValidationState(
          errorMessage: '비밀번호를 입력해주세요',
          isValid: false,
          hasBeenTouched: true,
        ),
      );
    } else if (!_isValidPassword(value)) {
      _state = _state.copyWith(
        password: FieldValidationState(
          errorMessage: '숫자/영어/특수문자를 필수로 넣어야 합니다',
          isValid: false,
          hasBeenTouched: true,
        ),
      );
    } else {
      _state = _state.copyWith(
        password: FieldValidationState(
          errorMessage: null,
          isValid: true,
          hasBeenTouched: true,
        ),
      );
    }

    // ✅ 비밀번호 확인란도 자동 검증
    if (passwordConfirmController.text.isNotEmpty) {
      validatePasswordConfirm(passwordConfirmController.text);
    }

    notifyListeners();
  }

  /// ✅ 새 비밀번호 확인 검증
  void validatePasswordConfirm(String value) {
    if (value.isEmpty) {
      _state = _state.copyWith(
        passwordConfirm: FieldValidationState(
          errorMessage: '비밀번호 확인을 입력해주세요',
          isValid: false,
          hasBeenTouched: true,
        ),
      );
    } else if (value != passwordController.text) {
      _state = _state.copyWith(
        passwordConfirm: FieldValidationState(
          errorMessage: '비밀번호가 일치하지 않습니다',
          isValid: false,
          hasBeenTouched: true,
        ),
      );
    } else {
      _state = _state.copyWith(
        passwordConfirm: FieldValidationState(
          errorMessage: null,
          isValid: true,
          hasBeenTouched: true,
        ),
      );
    }

    notifyListeners();
  }

  /// ✅ 모든 필드 유효성 체크 (Signup과 동일 구조)
  bool validateAll() {
    validatePassword(passwordController.text);
    validatePasswordConfirm(passwordConfirmController.text);

    return _state.password.isValid && _state.passwordConfirm.isValid;
  }
}
