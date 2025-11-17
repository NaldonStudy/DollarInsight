package com.ssafy.b205.backend.domain.persona.service;

import com.ssafy.b205.backend.domain.persona.entity.Persona;
import com.ssafy.b205.backend.domain.persona.repository.PersonaRepository;
import com.ssafy.b205.backend.domain.user.repository.UserRepository;
import com.ssafy.b205.backend.support.error.AppException;
import com.ssafy.b205.backend.support.error.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PersonaQueryServiceImpl implements PersonaQueryService {

    private final PersonaRepository personaRepository;
    private final UserRepository userRepository;

    private static final Sort DEFAULT_SORT = Sort.by(Sort.Direction.ASC, "id");

    @Override
    public List<Persona> findAll() {
        return personaRepository.findAll(DEFAULT_SORT);
    }

    @Override
    public List<Persona> findEnabledForUser(String userUuid) {
        final var user = userRepository.findByUuidAndDeletedAtIsNull(UUID.fromString(userUuid))
                .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND, "[PersonaSvc-E01] UUID로 사용자 없음: " + userUuid));
        return personaRepository.findEnabledByUserId(user.getId());
    }
}
