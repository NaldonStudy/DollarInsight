package com.ssafy.b205.backend.domain.session.repository;

import com.ssafy.b205.backend.domain.session.entity.UserSession;
import com.ssafy.b205.backend.domain.user.entity.User;
import com.ssafy.b205.backend.domain.device.entity.UserDevice;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserSessionRepository extends JpaRepository<UserSession, Integer> {
    Optional<UserSession> findByRefreshTokenHash(String hash);
    List<UserSession> findByUserAndUserDevice(User user, UserDevice userDevice);
    List<UserSession> findByUser(User user);
}
