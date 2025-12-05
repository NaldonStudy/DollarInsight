-- V5__chat_session_personas.sql
-- 1) 링크 테이블 생성
CREATE TABLE IF NOT EXISTS chat_session_personas (
                                                     id          SERIAL PRIMARY KEY,
                                                     session_id  INT NOT NULL REFERENCES chat_sessions(id) ON DELETE CASCADE,
    persona_id  INT NOT NULL REFERENCES personas(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (session_id, persona_id)
    );

CREATE INDEX IF NOT EXISTS ix_csp_session ON chat_session_personas(session_id);

-- 2) '세션의 유저'가 가진 '활성' 페르소나만 매핑 허용 트리거
CREATE OR REPLACE FUNCTION enforce_csp_enabled_for_owner()
RETURNS TRIGGER AS $$
DECLARE
v_user_id INT;
BEGIN
SELECT user_id INTO v_user_id FROM chat_sessions WHERE id = NEW.session_id;
IF NOT EXISTS (
    SELECT 1
      FROM user_personas up
     WHERE up.user_id = v_user_id
       AND up.persona_id = NEW.persona_id
       AND up.enabled = TRUE
  ) THEN
    RAISE EXCEPTION 'Persona % is not enabled for session owner %', NEW.persona_id, v_user_id;
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_csp_enabled ON chat_session_personas;
CREATE TRIGGER trg_csp_enabled
    BEFORE INSERT OR UPDATE ON chat_session_personas
                         FOR EACH ROW EXECUTE FUNCTION enforce_csp_enabled_for_owner();

-- 3) 기존 데이터 이관 (있을 때만)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
              WHERE table_name='chat_sessions' AND column_name='persona_id') THEN
    INSERT INTO chat_session_personas(session_id, persona_id)
SELECT id, persona_id FROM chat_sessions
    ON CONFLICT DO NOTHING;
END IF;
END$$;

-- 4) 기존 복합 FK/인덱스/컬럼 제거 (있을 때만)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname='fk_chat_sessions_user_persona') THEN
ALTER TABLE chat_sessions DROP CONSTRAINT fk_chat_sessions_user_persona;
END IF;
  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname='fk_chat_sessions_persona') THEN
ALTER TABLE chat_sessions DROP CONSTRAINT fk_chat_sessions_persona;
END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns
              WHERE table_name='chat_sessions' AND column_name='persona_id') THEN
ALTER TABLE chat_sessions DROP COLUMN persona_id;
END IF;
  IF EXISTS (SELECT 1 FROM pg_class WHERE relname='ix_chat_sessions_user_per') THEN
DROP INDEX ix_chat_sessions_user_per;
END IF;
END$$;
