package com.ssafy.b205.backend.domain.chat.repository;

import com.ssafy.b205.backend.domain.chat.entity.ChatSessionPersona;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface ChatSessionPersonaRepository extends JpaRepository<ChatSessionPersona, Integer> {

    @Query("""
        select csp.personaId
          from ChatSessionPersona csp
         where csp.sessionId = :sessionId
        """)
    List<Integer> findPersonaIdsBySessionId(Integer sessionId);
}
