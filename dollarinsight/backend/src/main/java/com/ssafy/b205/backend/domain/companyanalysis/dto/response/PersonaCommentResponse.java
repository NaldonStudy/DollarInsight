package com.ssafy.b205.backend.domain.companyanalysis.dto.response;

import lombok.Getter;

@Getter
public class PersonaCommentResponse {

    private final String personaCode;
    private final String personaName;
    private final String comment;

    public PersonaCommentResponse(String personaCode, String personaName, String comment) {
        this.personaCode = personaCode;
        this.personaName = personaName;
        this.comment = comment;
    }
}
