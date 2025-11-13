package com.ssafy.b205.backend.domain.persona.service;

import com.ssafy.b205.backend.domain.persona.entity.Persona;
import com.ssafy.b205.backend.domain.persona.entity.UserPersona;
import com.ssafy.b205.backend.domain.persona.repository.PersonaRepository;
import com.ssafy.b205.backend.domain.persona.repository.UserPersonaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class UserPersonaServiceImpl implements UserPersonaService {

    private final PersonaRepository personaRepository;
    private final UserPersonaRepository userPersonaRepository;

    @Override
    @Transactional
    public void initializeForUser(Integer userId) {
        final var personas = personaRepository.findAll();
        if (personas.isEmpty()) {
            log.warn("[UserPersonaSvc-01] 등록된 페르소나 없음 → 초기화 스킵 userId={}", userId);
            return;
        }

        final var links = personas.stream()
                .map(Persona::getId)
                .map(pid -> UserPersona.of(userId, pid, true))
                .toList();
        userPersonaRepository.saveAll(links);
        log.info("[UserPersonaSvc-02] 사용자 페르소나 초기화 완료 userId={}, personaCount={}", userId, links.size());
    }
}
