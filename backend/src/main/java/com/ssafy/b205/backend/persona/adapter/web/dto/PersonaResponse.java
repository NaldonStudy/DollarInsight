package com.ssafy.b205.backend.persona.adapter.web.dto;

import com.ssafy.b205.backend.persona.domain.entity.Persona;

public record PersonaResponse(Integer id, String code) {
    public static PersonaResponse from(Persona persona) {
        return new PersonaResponse(persona.getId(), persona.getCode());
    }
}
