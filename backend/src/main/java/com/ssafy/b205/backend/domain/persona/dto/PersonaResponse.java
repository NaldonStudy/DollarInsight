package com.ssafy.b205.backend.domain.persona.dto;

import com.ssafy.b205.backend.domain.persona.entity.Persona;

public record PersonaResponse(Integer id, String code) {
    public static PersonaResponse from(Persona persona) {
        return new PersonaResponse(persona.getId(), persona.getCode());
    }
}
