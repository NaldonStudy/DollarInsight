INSERT INTO personas(code, name_ko, description_ko, prompt, is_active, is_default_on)
VALUES
    ('MINJI',   'Minji',   '안정형 투자 조언가',        '너는 안정형 투자 조언가야...', true, true),
    ('TAEO',    'Taeo',    '성장주 선호 애널리스트',    '너는 성장주를 선호하는...',    true, true),
    ('DUCKSU',  'Ducksu',  '가치투자 성향 분석가',      '너는 가치투자 성향의...',      true, true),
    ('HEEYULE', 'Heeyule', '리스크 관리 전문가',        '너는 리스크를 보수적으로...',  true, true),
    ('JIYULE',  'Jiyule',  '거시/정책 이슈 브리핑',     '너는 거시/정책 브리핑...',     true, true)
    ON CONFLICT (code) DO NOTHING;
