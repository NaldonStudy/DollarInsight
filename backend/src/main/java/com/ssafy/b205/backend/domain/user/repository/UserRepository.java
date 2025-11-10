// src/main/java/com/ssafy/b205/backend/domain/user/repository/UserRepository.java
package com.ssafy.b205.backend.domain.user.repository;

import com.ssafy.b205.backend.domain.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface UserRepository extends JpaRepository<User, Integer> {
    // 내부 공용 (소프트삭제 여부 서비스에서 판단 가능)
    Optional<User> findByUuid(UUID uuid);

    // 활성 사용자 전용
    Optional<User> findByUuidAndDeletedAtIsNull(UUID uuid);

    Optional<User> findByEmailIgnoreCaseAndDeletedAtIsNull(String email);
    boolean existsByEmailIgnoreCaseAndDeletedAtIsNull(String email);

    // 닉네임 중복 검사
    boolean existsByNicknameIgnoreCaseAndDeletedAtIsNull(String nickname);
    boolean existsByNicknameIgnoreCaseAndDeletedAtIsNullAndIdNot(String nickname, Integer id);
}
