package com.ssafy.b205.backend.domain.chat.repository;

import com.ssafy.b205.backend.domain.chat.entity.ChatSession;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface ChatSessionRepository extends JpaRepository<ChatSession, Integer> {
    Optional<ChatSession> findByUuid(UUID uuid);
}
