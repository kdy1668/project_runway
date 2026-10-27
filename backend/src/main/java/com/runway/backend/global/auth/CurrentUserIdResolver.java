package com.runway.backend.global.auth;

import com.runway.backend.global.exception.ApiException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;

@Component
public class CurrentUserIdResolver {

    public static final String HEADER = "X-User-Id";

    public long requireUserId(String rawHeader) {
        if (rawHeader == null || rawHeader.isBlank()) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, "UNAUTHORIZED", "인증이 필요합니다.");
        }
        try {
            return Long.parseLong(rawHeader.trim());
        } catch (NumberFormatException ex) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, "UNAUTHORIZED", "인증이 필요합니다.");
        }
    }
}
