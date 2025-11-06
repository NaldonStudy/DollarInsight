-- ============================================================
-- V2 — user_session.device_id → user_device_id (rename + index)
-- ============================================================

-- 1) 컬럼명 변경
ALTER TABLE user_session
    RENAME COLUMN device_id TO user_device_id;

-- 2) 기존 인덱스명 정리 (있으면 이름만 바꿔줌)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_class WHERE relname = 'ix_user_session_device_id') THEN
    ALTER INDEX ix_user_session_device_id RENAME TO ix_user_session_user_device_id;
END IF;
END $$;

-- 3) (선택) 사용자별 세션 조회 최적화 인덱스 없으면 생성
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM   pg_class c
           JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE  c.relkind = 'i'
       AND c.relname = 'ix_user_session_user_issued'
  ) THEN
CREATE INDEX ix_user_session_user_issued
    ON user_session(user_id, issued_at DESC);
END IF;
END $$;
