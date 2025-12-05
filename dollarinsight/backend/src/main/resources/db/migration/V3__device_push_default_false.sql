-- V3__device_push_default_false.sql
-- user_device.is_push_enabled 기본값 TRUE -> FALSE로 변경 + 기존 TRUE는 FALSE로 덮어씀

ALTER TABLE user_device
    ALTER COLUMN is_push_enabled SET DEFAULT FALSE;

UPDATE user_device
SET is_push_enabled = FALSE
WHERE is_push_enabled IS TRUE;
