package com.ssafy.b205.backend.persona.domain.repository;

import com.ssafy.b205.backend.persona.domain.entity.UserPersona;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface UserPersonaRepository extends JpaRepository<UserPersona, Integer> {

    java.util.List<UserPersona> findByUserId(Integer userId);

    @Query("""
        select (count(up) > 0)
          from UserPersona up
         where up.userId = :userId
           and up.personaId = :personaId
           and up.enabled = true
        """)
    boolean existsEnabledForUser(Integer userId, Integer personaId);
}
