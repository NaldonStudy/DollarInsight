import 'package:flutter/material.dart';
import '../../data/models/signup_form_state.dart';

/// 회원가입 폼의 유효성 검증 로직을 담당하는 Provider
class SignupFormProvider extends ChangeNotifier {
  SignupFormState _state = SignupFormState.initial();

  SignupFormState get state => _state;

  // 컨트롤러
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmController = TextEditingController();

  @override
  void dispose() {
    nicknameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    passwordConfirmController.dispose();
    super.dispose();
  }

  /// 이메일 유효성 검증 정규식
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// 비밀번호 유효성 검증 (영어, 숫자, 특수문자 필수, 8자 이상)
  bool _isValidPassword(String password) {
    if (password.length < 8) return false;

    bool hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    bool hasNumber = RegExp(r'[0-9]').hasMatch(password);
    bool hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

    return hasLetter && hasNumber && hasSpecial;
  }

  /// 닉네임 유효성 검증
  void validateNickname(String value) {
    if (value.isEmpty) {
      _state = _state.copyWith(
        nickname: FieldValidationState(
          errorMessage: '닉네임을 입력해주세요',
          isValid: false,
          hasBeenTouched: true,
        ),
      );
    } else {
      _state = _state.copyWith(
        nickname: FieldValidationState(
          errorMessage: null,
          isValid: true,
          hasBeenTouched: true,
        ),
      );
    }
    notifyListeners();
  }

  /// 이메일 유효성 검증
  void validateEmail(String value) {
    if (value.isEmpty) {
      _state = _state.copyWith(
        email: FieldValidationState(
          errorMessage: '이메일을 입력해주세요',
          isValid: false,
          hasBeenTouched: true,
        ),
      );
    } else if (!_isValidEmail(value)) {
      _state = _state.copyWith(
        email: FieldValidationState(
          errorMessage: '올바른 이메일 형식이 아닙니다',
          isValid: false,
          hasBeenTouched: true,
        ),
      );
    } else {
      _state = _state.copyWith(
        email: FieldValidationState(
          errorMessage: null,
          isValid: true,
          hasBeenTouched: true,
        ),
      );
    }
    notifyListeners();
  }

  /// 비밀번호 유효성 검증
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

    // 비밀번호 확인란이 비어있지 않으면 다시 검증
    if (passwordConfirmController.text.isNotEmpty) {
      validatePasswordConfirm(passwordConfirmController.text);
    }

    notifyListeners();
  }

  /// 비밀번호 확인 유효성 검증
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

  /// 모든 필드 유효성 검증
  bool validateAll() {
    validateNickname(nicknameController.text);
    validateEmail(emailController.text);
    validatePassword(passwordController.text);
    validatePasswordConfirm(passwordConfirmController.text);

    return _state.isAllValid;
  }

  /// 폼 초기화
  void reset() {
    nicknameController.clear();
    emailController.clear();
    passwordController.clear();
    passwordConfirmController.clear();
    _state = SignupFormState.initial();
    notifyListeners();
  }
}
