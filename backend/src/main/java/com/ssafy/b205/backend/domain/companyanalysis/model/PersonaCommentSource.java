package com.ssafy.b205.backend.domain.companyanalysis.model;

/**
 * Common projection for Mongo documents that embed persona-specific comments.
 */
public interface PersonaCommentSource {

    String getPersonaDeoksu();

    String getPersonaHeuyeol();

    String getPersonaJiyul();

    String getPersonaMinji();

    String getPersonaTeo();
}

