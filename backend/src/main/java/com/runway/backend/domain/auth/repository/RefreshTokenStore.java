package com.runway.backend.domain.auth.repository;

import com.runway.backend.domain.auth.service.AuthErrors;
import com.runway.backend.domain.auth.service.RefreshTokenFactory.IssuedRefreshToken;
import java.util.List;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.core.io.ClassPathResource;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.script.DefaultRedisScript;
import org.springframework.stereotype.Repository;

@Repository
public class RefreshTokenStore {
    private final StringRedisTemplate redis;
    private final DefaultRedisScript<Long> create = script("create-login-family.lua");
    private final DefaultRedisScript<Long> revoke = script("revoke-undelivered-family.lua");

    public RefreshTokenStore(@Qualifier("authenticationRedisTemplate") StringRedisTemplate redis) {
        this.redis = redis;
    }

    public void create(IssuedRefreshToken token) {
        try {
            Long result =
                    redis.execute(
                            create,
                            List.of(familyKey(token.familyId()), userKey(token.userId())),
                            token.familyId(),
                            Long.toString(token.userId()),
                            token.hash(),
                            Long.toString(token.createdAt().getEpochSecond()),
                            Long.toString(token.expiresAt().getEpochSecond()));
            if (!Long.valueOf(1).equals(result)) throw AuthErrors.unavailable();
        } catch (RuntimeException exception) {
            throw AuthErrors.unavailable();
        }
    }

    /** Best effort compensation: no token material or driver exception enters logs. */
    public boolean revokeUndelivered(IssuedRefreshToken token) {
        try {
            return Long.valueOf(1)
                    .equals(
                            redis.execute(
                                    revoke,
                                    List.of(familyKey(token.familyId())),
                                    Long.toString(token.userId()),
                                    token.hash()));
        } catch (RuntimeException exception) {
            return false;
        }
    }

    public static String familyKey(String family) {
        return "runway:auth:family:" + family;
    }

    public static String userKey(long user) {
        return "runway:auth:user:" + user + ":families";
    }

    private static DefaultRedisScript<Long> script(String name) {
        var result = new DefaultRedisScript<Long>();
        result.setLocation(new ClassPathResource("auth/" + name));
        result.setResultType(Long.class);
        return result;
    }
}
