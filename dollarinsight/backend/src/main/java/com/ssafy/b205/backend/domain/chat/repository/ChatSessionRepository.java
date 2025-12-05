package com.ssafy.b205.backend.domain.chat.repository;

import com.ssafy.b205.backend.domain.chat.entity.ChatSession;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.UUID;

public interface ChatSessionRepository extends JpaRepository<ChatSession, Integer> {
    Optional<ChatSession> findByUuidAndDeletedAtIsNull(UUID uuid);

    Page<ChatSession> findByUserIdAndDeletedAtIsNull(int userId, Pageable pageable);

    @Modifying(clearAutomatically = true)
    @Query("update ChatSession s set s.updatedAt = :updatedAt where s.id = :id")
    void touchUpdatedAt(@Param("id") int sessionId, @Param("updatedAt") OffsetDateTime updatedAt);
}
