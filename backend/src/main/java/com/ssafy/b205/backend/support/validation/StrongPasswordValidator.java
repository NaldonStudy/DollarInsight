package com.ssafy.b205.backend.support.validation;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;
import java.util.regex.Pattern;

public class StrongPasswordValidator implements ConstraintValidator<StrongPassword, String> {

    private Pattern pattern;

    @Override
    public void initialize(StrongPassword ann) {
        // 영문 + 숫자 + 특수문자 각 1자 이상, 공백 불가, 길이는 min~max
        String regex = "^(?=.*[A-Za-z])(?=.*\\d)(?=.*[^A-Za-z0-9])\\S{" + ann.min() + "," + ann.max() + "}$";
        this.pattern = Pattern.compile(regex);
    }

    @Override
    public boolean isValid(String value, ConstraintValidatorContext context) {
        if (value == null) return false;
        return pattern.matcher(value).matches();
    }
}
