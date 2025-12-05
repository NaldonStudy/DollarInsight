package com.ssafy.b205.backend.domain.persona.service;

import com.ssafy.b205.backend.domain.persona.entity.Persona;

import java.util.List;

public interface PersonaQueryService {
    List<Persona> findAll();
    List<Persona> findEnabledForUser(String userUuid);
}
