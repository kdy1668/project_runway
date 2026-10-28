package com.runway.backend.domain.auth.service;

import com.runway.backend.domain.auth.dto.LoginResponse;
import com.runway.backend.domain.auth.repository.AuthUserRepository;
import com.runway.backend.domain.auth.repository.AuthUserRepository.Account;
import com.runway.backend.domain.auth.repository.RefreshTokenStore;
import com.runway.backend.domain.auth.service.RefreshTokenFactory.IssuedRefreshToken;
import com.runway.backend.global.security.JwtAccessTokenService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class LoginIssuanceService {
    private final AuthUserRepository users;
    private final RefreshTokenStore store;
    private final JwtAccessTokenService accessTokens;

    public LoginIssuanceService(
            AuthUserRepository users, RefreshTokenStore store, JwtAccessTokenService accessTokens) {
        this.users = users;
        this.store = store;
        this.accessTokens = accessTokens;
    }

    @Transactional
    public LoginResponse issue(Account verified, IssuedRefreshToken refresh) {
        Account current = users.lock(verified.id()).orElseThrow(AuthErrors::invalidCredentials);
        if (!current.active() || !current.passwordHash().equals(verified.passwordHash()))
            throw AuthErrors.invalidCredentials();
        boolean onboarding = users.onboardingCompleted(current.id());
        var access = accessTokens.issue(current.id(), refresh.expiresAt());
        store.create(refresh);
        return new LoginResponse(
                new LoginResponse.User(current.id(), current.loginId()),
                access.accessToken(),
                refresh.value(),
                access.expiresInSec(),
                refresh.expiresAt(),
                onboarding);
    }
}
