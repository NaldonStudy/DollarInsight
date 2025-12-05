-- V7__fix_persona_trigger.sql
-- 기존 chat_sessions 트리거/함수 제거 → chat_session_personas로 이관

-- 1) 오래된 트리거/함수 제거(있으면만)
DROP TRIGGER IF EXISTS trg_chat_sessions_up_enabled ON chat_sessions;
DROP FUNCTION IF EXISTS enforce_enabled_user_persona();

-- 2) 새 함수: 세션의 user_id를 join해서, 해당 persona가 '활성화'되어 있는지 검사
CREATE OR REPLACE FUNCTION enforce_enabled_user_persona_v2()
    RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM chat_sessions cs
                 JOIN user_personas up
                      ON up.user_id = cs.user_id
                          AND up.persona_id = NEW.persona_id
                          AND up.enabled = TRUE
        WHERE cs.id = NEW.session_id
    ) THEN
        RAISE EXCEPTION 'Persona % is not enabled for the user of session %', NEW.persona_id, NEW.session_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3) 새 트리거: chat_session_personas에 부착
DROP TRIGGER IF EXISTS trg_csp_enabled ON chat_session_personas;

CREATE TRIGGER trg_csp_enabled
    BEFORE INSERT OR UPDATE ON chat_session_personas
    FOR EACH ROW
EXECUTE FUNCTION enforce_enabled_user_persona_v2();
