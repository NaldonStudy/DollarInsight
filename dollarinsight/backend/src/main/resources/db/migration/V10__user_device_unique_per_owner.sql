-- 사용자별(device_id) 중복을 허용하기 위해 기존 UNIQUE(device_id)를 제거하고
-- 사용자+디바이스 조합으로 유일성을 보장한다.

ALTER TABLE user_device
    DROP CONSTRAINT IF EXISTS user_device_device_id_key;

ALTER TABLE user_device
    ADD CONSTRAINT uq_user_device_user_and_device UNIQUE (user_id, device_id);
