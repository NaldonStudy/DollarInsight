package com.ssafy.b205.backend.user.domain.repository;

import com.ssafy.b205.backend.user.domain.entity.User;
import com.ssafy.b205.backend.user.domain.entity.UserCredential;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserCredentialRepository extends JpaRepository<UserCredential, Integer> {
    Optional<UserCredential> findByUser(User user);
}
