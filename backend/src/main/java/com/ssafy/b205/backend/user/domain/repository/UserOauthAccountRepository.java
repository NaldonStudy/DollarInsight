package com.ssafy.b205.backend.user.domain.repository;

import com.ssafy.b205.backend.user.domain.entity.ProviderType;
import com.ssafy.b205.backend.user.domain.entity.UserOauthAccount;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserOauthAccountRepository extends JpaRepository<UserOauthAccount, Integer> {
    Optional<UserOauthAccount> findByProviderAndProviderUserId(ProviderType provider, String providerUserId);
}
