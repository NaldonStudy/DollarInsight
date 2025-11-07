-- V4__chat_sessions_persona_id.sql
-- 목적: chat_sessions가 persona_id(int)와 올바른 FK들을 보장하고,
-- 과거 남아있을 수 있는 persona 컬럼을 제거한다.

-- 1) persona_id 없으면 추가
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'chat_sessions' AND column_name = 'persona_id'
  ) THEN
ALTER TABLE chat_sessions ADD COLUMN persona_id INT;
END IF;
END$$;

-- 2) 과거 persona 컬럼이 남아있다면 제거
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'chat_sessions' AND column_name = 'persona'
  ) THEN
ALTER TABLE chat_sessions DROP COLUMN persona;
END IF;
END$$;

-- 3) persona_id NOT NULL 보장
ALTER TABLE chat_sessions
    ALTER COLUMN persona_id SET NOT NULL;

-- 4) FK(chat_sessions.persona_id -> personas.id) 없으면 생성
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM   pg_constraint
    WHERE  conname = 'fk_chat_sessions_persona'
  ) THEN
ALTER TABLE chat_sessions
    ADD CONSTRAINT fk_chat_sessions_persona
        FOREIGN KEY (persona_id) REFERENCES personas(id);
END IF;
END$$;

-- 5) 복합 FK (user_id, persona_id) -> user_personas(user_id, persona_id) 없으면 생성
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM   pg_constraint
    WHERE  conname = 'fk_chat_sessions_user_persona'
  ) THEN
ALTER TABLE chat_sessions
    ADD CONSTRAINT fk_chat_sessions_user_persona
        FOREIGN KEY (user_id, persona_id)
            REFERENCES user_personas (user_id, persona_id)
            ON UPDATE CASCADE
            ON DELETE RESTRICT;
END IF;
END$$;

-- 6) 인덱스 보강 (있으면 생략)
CREATE INDEX IF NOT EXISTS ix_chat_sessions_user       ON chat_sessions(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS ix_chat_sessions_user_per   ON chat_sessions(user_id, persona_id);

-- 7) '활성화된' 유저-페르소나만 허용 트리거/함수 재정의 (idempotent)
CREATE OR REPLACE FUNCTION enforce_enabled_user_persona()
RETURNS TRIGGER AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM user_personas up
    WHERE up.user_id = NEW.user_id
      AND up.persona_id = NEW.persona_id
      AND up.enabled = TRUE
  ) THEN
    RAISE EXCEPTION 'Persona % is not enabled for user %', NEW.persona_id, NEW.user_id;
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_chat_sessions_up_enabled ON chat_sessions;

CREATE TRIGGER trg_chat_sessions_up_enabled
    BEFORE INSERT OR UPDATE ON chat_sessions
                         FOR EACH ROW
                         EXECUTE FUNCTION enforce_enabled_user_persona();
