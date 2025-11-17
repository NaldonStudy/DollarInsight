package com.ssafy.b205.backend.domain.persona.service;

import com.ssafy.b205.backend.domain.persona.entity.Persona;
import com.ssafy.b205.backend.domain.persona.entity.UserPersona;
import com.ssafy.b205.backend.domain.persona.repository.PersonaRepository;
import com.ssafy.b205.backend.domain.persona.repository.UserPersonaRepository;
import com.ssafy.b205.backend.support.error.AppException;
import com.ssafy.b205.backend.support.error.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

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

    @Override
    @Transactional
    public void updateEnabledPersonas(Integer userId, List<String> personaCodes) {
        if (personaCodes == null || personaCodes.isEmpty()) {
            throw new AppException(ErrorCode.BAD_REQUEST, "활성화할 페르소나를 1개 이상 지정하세요.");
        }

        final boolean hasBlank = personaCodes.stream().anyMatch(code -> code == null || code.isBlank());
        if (hasBlank) {
            throw new AppException(ErrorCode.BAD_REQUEST, "페르소나 코드는 공백일 수 없습니다.");
        }

        final List<String> normalizedCodes = personaCodes.stream()
                .map(String::trim)
                .toList();
        final List<String> distinctCodes = new ArrayList<>(new LinkedHashSet<>(normalizedCodes));

        final List<Persona> personas = personaRepository.findAllByCodeIn(distinctCodes);
        final Map<String, Persona> personaByCode = personas.stream()
                .collect(Collectors.toMap(Persona::getCode, Function.identity()));

        final List<String> missing = distinctCodes.stream()
                .filter(code -> !personaByCode.containsKey(code))
                .toList();
        if (!missing.isEmpty()) {
            throw new AppException(ErrorCode.BAD_REQUEST, "존재하지 않는 페르소나 코드: " + missing);
        }

        final Set<Integer> desiredPersonaIds = personaByCode.values().stream()
                .map(Persona::getId)
                .collect(Collectors.toCollection(HashSet::new));

        final var existingLinks = userPersonaRepository.findByUserId(userId);
        final Set<Integer> pending = new HashSet<>(desiredPersonaIds);

        existingLinks.forEach(link -> {
            final boolean shouldEnable = desiredPersonaIds.contains(link.getPersonaId());
            if (link.isEnabled() != shouldEnable) {
                link.changeEnabled(shouldEnable);
            }
            if (shouldEnable) {
                pending.remove(link.getPersonaId());
            }
        });

        if (!pending.isEmpty()) {
            final List<UserPersona> newLinks = pending.stream()
                    .map(pid -> UserPersona.of(userId, pid, true))
                    .toList();
            userPersonaRepository.saveAll(newLinks);
        }

        log.info("[UserPersonaSvc-11] 사용자 페르소나 갱신 userId={}, enabledCodes={}", userId, distinctCodes);
    }
}
