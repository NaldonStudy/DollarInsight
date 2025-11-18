package com.ssafy.b205.backend.domain.persona.service;

import java.util.List;

public interface UserPersonaService {

    /**
     * 새로운 사용자에 대해 모든 페르소나를 활성화 상태로 연결한다.
     */
    void initializeForUser(Integer userId);

    /**
     * 사용자가 활성화할 페르소나 목록을 갱신한다.
     */
    void updateEnabledPersonas(Integer userId, List<String> personaCodes);
}
