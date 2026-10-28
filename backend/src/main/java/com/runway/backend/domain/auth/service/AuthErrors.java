package com.runway.backend.domain.auth.service;

import com.runway.backend.global.exception.ApiException;
import org.springframework.http.HttpStatus;

public final class AuthErrors {
    private AuthErrors() {}

    public static ApiException invalidCredentials() {
        return new ApiException(
                HttpStatus.UNAUTHORIZED, "INVALID_CREDENTIALS", "아이디 또는 비밀번호가 올바르지 않습니다.");
    }

    public static ApiException unavailable() {
        return new ApiException(
                HttpStatus.SERVICE_UNAVAILABLE, "SERVICE_UNAVAILABLE", "일시적으로 처리할 수 없습니다.");
    }
}
