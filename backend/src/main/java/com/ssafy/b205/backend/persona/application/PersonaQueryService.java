package com.ssafy.b205.backend.persona.application;

import com.ssafy.b205.backend.persona.domain.entity.Persona;

import java.util.List;

public interface PersonaQueryService {
    List<Persona> findAll();
    List<Persona> findEnabledForUser(String userUuid);
}
