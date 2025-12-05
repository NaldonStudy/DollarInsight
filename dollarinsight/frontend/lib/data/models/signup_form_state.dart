/// 각 필드의 유효성 검증 상태를 나타내는 모델
///
class FieldValidationState {
  final String? errorMessage;
  final bool isValid;
  final bool hasBeenTouched;

  FieldValidationState({
    this.errorMessage,
    this.isValid = false,
    this.hasBeenTouched = false,
  });

  FieldValidationState copyWith({
    String? errorMessage,
    bool? isValid,
    bool? hasBeenTouched,
  }) {
    return FieldValidationState(
      errorMessage: errorMessage,
      isValid: isValid ?? this.isValid,
      hasBeenTouched: hasBeenTouched ?? this.hasBeenTouched,
    );
  }
}

/// 회원가입 폼 전체의 상태를 나타내는 모델
class SignupFormState {
  final FieldValidationState nickname;
  final FieldValidationState email;
  final FieldValidationState password;
  final FieldValidationState passwordConfirm;

  SignupFormState({
    required this.nickname,
    required this.email,
    required this.password,
    required this.passwordConfirm,
  });

  factory SignupFormState.initial() {
    return SignupFormState(
      nickname: FieldValidationState(),
      email: FieldValidationState(),
      password: FieldValidationState(),
      passwordConfirm: FieldValidationState(),
    );
  }

  bool get isAllValid =>
      nickname.isValid &&
      email.isValid &&
      password.isValid &&
      passwordConfirm.isValid;

  SignupFormState copyWith({
    FieldValidationState? nickname,
    FieldValidationState? email,
    FieldValidationState? password,
    FieldValidationState? passwordConfirm,
  }) {
    return SignupFormState(
      nickname: nickname ?? this.nickname,
      email: email ?? this.email,
      password: password ?? this.password,
      passwordConfirm: passwordConfirm ?? this.passwordConfirm,
    );
  }
}
