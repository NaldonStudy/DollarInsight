package com.ssafy.b205.backend.domain.session.repository;

import com.ssafy.b205.backend.domain.session.entity.UserSession;
import com.ssafy.b205.backend.domain.user.entity.User;
import com.ssafy.b205.backend.domain.device.entity.UserDevice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserSessionRepository extends JpaRepository<UserSession, Integer> {

    Optional<UserSession> findByRefreshTokenHash(String hash);

    List<UserSession> findByUserAndUserDevice(User user, UserDevice userDevice);

    List<UserSession> findByUser(User user);

    Optional<UserSession> findByUuid(UUID uuid);

    List<UserSession> findByUserOrderByIssuedAtDesc(User user);

    // N+1 방지: userSession -> userDevice fetch join + 최신순
    @Query("""
           select s
           from UserSession s
           join fetch s.userDevice d
           where s.user = :user
           order by s.issuedAt desc
           """)
    List<UserSession> findAllByUserWithDeviceOrderByIssuedAtDesc(@Param("user") User user);

    // 소유자 검증을 한 번에 (UUID + User)
    Optional<UserSession> findByUuidAndUser(UUID uuid, User user);
}
