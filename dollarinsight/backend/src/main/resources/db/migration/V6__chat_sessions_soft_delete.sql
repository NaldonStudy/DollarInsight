-- V6__chat_sessions_soft_delete.sql
-- 목적: 세션 소프트 삭제 컬럼 추가 및 조회 최적화 인덱스 구성
-- - DELETE 대신 deleted_at을 세팅하여 '활성' 세션만 기본 조회
-- - 목록(사용자별, 최신순) 및 UUID 단건 조회를 가속

-- 1) 컬럼 추가 (idempotent)
ALTER TABLE chat_sessions
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

COMMENT ON COLUMN chat_sessions.deleted_at IS '소프트 삭제 시각(NULL이면 활성)';

-- 2) 활성 세션 목록(사용자별 최신순) 조회 최적화: partial index
--    기존 V4에서 만든 user+created_at 인덱스가 있어도, 활성 전용 partial index가 더 유리
CREATE INDEX IF NOT EXISTS ix_chat_sessions_active_user_created
    ON chat_sessions(user_id, created_at DESC)
    WHERE deleted_at IS NULL;

-- 3) UUID 조회 최적화
CREATE INDEX IF NOT EXISTS ix_chat_sessions_uuid
    ON chat_sessions(uuid);

-- 4) title 수정 등 업데이트 시 updated_at 자동 반영 트리거(안전 재생성)
CREATE OR REPLACE FUNCTION set_chat_sessions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at := now();
RETURN NEW;
END
$$ LANGUAGE plpgsql;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_chat_sessions_updated_at') THEN
CREATE TRIGGER trg_chat_sessions_updated_at
    BEFORE UPDATE ON chat_sessions
    FOR EACH ROW
    EXECUTE FUNCTION set_chat_sessions_updated_at();
END IF;
END
$$;

-- 참고:
-- 애플리케이션에서는 DELETE 대신
--   UPDATE chat_sessions SET deleted_at = now() WHERE uuid = :sid AND user_id = :uid
-- 형태로 동작시켜야 하며,
-- 조회 기본 WHERE 조건에 "deleted_at IS NULL"을 포함하세요.
