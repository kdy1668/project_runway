package com.runway.backend.domain.auth.service;

import com.runway.backend.domain.auth.dto.LoginResponse;
import com.runway.backend.domain.auth.repository.AuthUserRepository;
import com.runway.backend.domain.auth.repository.RefreshTokenStore;
import com.runway.backend.global.exception.ApiException;
import java.time.Clock;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Service;

@Service
public class LoginService {
    private static final Logger log = LoggerFactory.getLogger(LoginService.class);
    private final AuthUserRepository users;
    private final MemberPasswordHasher passwords;
    private final RefreshTokenFactory tokens;
    private final LoginIssuanceService issuance;
    private final RefreshTokenStore store;
    private final Clock clock;

    public LoginService(
            AuthUserRepository users,
            MemberPasswordHasher passwords,
            RefreshTokenFactory tokens,
            LoginIssuanceService issuance,
            RefreshTokenStore store,
            Clock clock) {
        this.users = users;
        this.passwords = passwords;
        this.tokens = tokens;
        this.issuance = issuance;
        this.store = store;
        this.clock = clock;
    }

    public LoginResponse login(String loginId, String password) {
        try {
            var found = users.findByLoginId(loginId);
            if (found.isEmpty() || !found.get().active()) {
                passwords.verifyDummy(password);
                throw AuthErrors.invalidCredentials();
            }
            var account = found.get();
            if (!passwords.matches(password, account.passwordHash()))
                throw AuthErrors.invalidCredentials();
            var refresh = tokens.create(account.id(), clock.instant());
            try {
                return issuance.issue(account, refresh);
            } catch (RuntimeException exception) {
                if (!store.revokeUndelivered(refresh)) log.warn("전달되지 않은 로그인 권한의 폐기를 확인하지 못했습니다.");
                if (exception instanceof ApiException api) throw api;
                throw AuthErrors.unavailable();
            }
        } catch (DataAccessException exception) {
            throw AuthErrors.unavailable();
        }
    }
}
