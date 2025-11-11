package com.ssafy.b205.backend.domain.user.repository;

import com.ssafy.b205.backend.domain.user.entity.ProviderType;
import com.ssafy.b205.backend.domain.user.entity.UserOauthAccount;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserOauthAccountRepository extends JpaRepository<UserOauthAccount, Integer> {
    Optional<UserOauthAccount> findByProviderAndProviderUserId(ProviderType provider, String providerUserId);
}
