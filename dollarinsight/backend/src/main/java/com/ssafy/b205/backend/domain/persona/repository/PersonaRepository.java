package com.ssafy.b205.backend.domain.persona.repository;

import com.ssafy.b205.backend.domain.persona.entity.Persona;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;

public interface PersonaRepository extends JpaRepository<Persona, Integer> {

    // code로 조회 (기존에 쓰고 있던 메서드 유지)
    java.util.Optional<Persona> findByCode(String code);

    List<Persona> findAllByCodeIn(Collection<String> codes);

    // ✅ 유저의 활성 페르소나 전부 조회 (이름/코드 모두 쓰려고 엔티티 반환)
    @Query(value = """
        SELECT p.*
        FROM personas p
        JOIN user_personas up ON up.persona_id = p.id
        WHERE up.user_id = :userId
          AND up.enabled = true
        ORDER BY p.id
        """, nativeQuery = true)
    List<Persona> findEnabledByUserId(@Param("userId") Integer userId);
}
