package com.ssafy.b205.backend.domain.persona.service;

public interface UserPersonaService {

    /**
     * 새로운 사용자에 대해 모든 페르소나를 활성화 상태로 연결한다.
     */
    void initializeForUser(Integer userId);
}
