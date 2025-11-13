-- R__seed_dev_all.sql
-- 목적: 로컬 개발용 더미 데이터 일괄 시드 (idempotent)
-- 전제: V1~V6 마이그레이션 적용 완료
-- 비밀번호: pgcrypto의 bcrypt 사용

-- 0) 확장
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1) 페르소나 UPSERT
INSERT INTO personas(code, name_ko, description_ko, prompt, is_active, is_default_on)
VALUES
    ('MINJI','Minji','안정형 투자 조언가',
     '너는 손실 회피와 분산을 중시하는 안정형 투자 조언가다. 핵심 원칙: (1) 자산배분 우선, (2) 개별 종목 비중 10% 이내, (3) 손절/리밸런싱 규칙 준수, (4) 장기 ETF/우량주 중심. 답변 시 리스크 요인과 대안 포트폴리오 비중까지 제시하고, 과도한 레버리지·테마 쏠림은 경고한다.',
     TRUE, TRUE),
    ('TAEO','Taeo','성장주 선호 애널리스트',
     '너는 고성장 섹터(반도체, AI, 클라우드 등)에 집중하는 성장주 애널리스트다. 핵심 프레임: TAM·매출성장률·영업레버리지·유저/코호트 지표. 시나리오별(보수/기준/낙관) 목표가 범위를 정량으로 제시하고, 변동성/밸류에이션 과열 시 주의점을 함께 말한다.',
     TRUE, TRUE),
    ('DUCKSU','Ducksu','가치투자 성향 분석가',
     '너는 현금흐름과 내재가치를 중시하는 가치투자 분석가다. 핵심 프레임: FCF, DCF/상대가치, 재무건전성(부채비율·이자보상배율), 자사주/배당정책. 안전마진이 충분한지 점검하고, 장기 보유 논리를 근거와 수치로 제시한다.',
     TRUE, TRUE),
    ('HEEYULE','Heeyule','리스크 관리 전문가',
     '너는 리스크 관리에 특화된 전문가다. 핵심 프레임: 포트폴리오 분산, 최대드로다운, VaR 개념 설명, 포지션 사이징. 헤지 수단(현금·단기채·인버스/풋옵션)과 실행 기준(손절/리밸런싱 트리거)을 구체적으로 제시한다.',
     TRUE, TRUE),
    ('JIYULE','Jiyule','거시/정책 이슈 브리핑',
     '너는 거시·정책 브리핑 담당이다. FOMC, CPI/PCE, 고용지표, 환율/금리·유가 흐름을 한눈에 정리하고, 자산군별(주식/채권/달러/원자재) 파급 경로를 중립 톤으로 요약한다. 중요한 일정(이벤트 캘린더)과 체크포인트를 함께 제시한다.',
     TRUE, TRUE)
ON CONFLICT (code) DO UPDATE
    SET name_ko        = EXCLUDED.name_ko,
        description_ko = EXCLUDED.description_ko,
        prompt         = EXCLUDED.prompt,
        is_active      = EXCLUDED.is_active,
        is_default_on  = EXCLUDED.is_default_on;

DO $$
    DECLARE
        -- users
        u1_id INT; u2_id INT;

        -- devices
        d1_id INT; d2_id INT;

        -- personas
        p_minji   INT;
        p_taeo    INT;
        p_ducksu  INT;
        p_heeyule INT;
        p_jiyule  INT;

        -- sessions
        s1_company_aapl INT;  -- demo1 COMPANY(AAPL)
        s2_news_aapl    INT;  -- demo1 NEWS(AAPL)
        s3_custom       INT;  -- demo1 CUSTOM
        s4_company_nvda INT;  -- demo2 COMPANY(NVDA)

        -- news
        n1_aapl BIGINT;
    BEGIN
        ---------------------------------------------------------------------------
        -- 2) 페르소나 ID 확보
        ---------------------------------------------------------------------------
        SELECT id INTO p_minji   FROM personas WHERE code='MINJI';
        SELECT id INTO p_taeo    FROM personas WHERE code='TAEO';
        SELECT id INTO p_ducksu  FROM personas WHERE code='DUCKSU';
        SELECT id INTO p_heeyule FROM personas WHERE code='HEEYULE';
        SELECT id INTO p_jiyule  FROM personas WHERE code='JIYULE';

        ---------------------------------------------------------------------------
        -- 3) Users (이메일 기준 UPSERT 유사)
        ---------------------------------------------------------------------------
        SELECT id INTO u1_id FROM users WHERE email='demo1@dollarinsight.dev' LIMIT 1;
        IF u1_id IS NULL THEN
            INSERT INTO users(email, nickname) VALUES ('demo1@dollarinsight.dev', 'Demo One')
            RETURNING id INTO u1_id;
        ELSE
            UPDATE users SET nickname='Demo One' WHERE id=u1_id;
        END IF;

        SELECT id INTO u2_id FROM users WHERE email='demo2@dollarinsight.dev' LIMIT 1;
        IF u2_id IS NULL THEN
            INSERT INTO users(email, nickname) VALUES ('demo2@dollarinsight.dev', 'Demo Two')
            RETURNING id INTO u2_id;
        ELSE
            UPDATE users SET nickname='Demo Two' WHERE id=u2_id;
        END IF;

        ---------------------------------------------------------------------------
        -- 4) 비밀번호 자격증명 (bcrypt)
        ---------------------------------------------------------------------------
        IF EXISTS (SELECT 1 FROM user_credential WHERE user_id = u1_id) THEN
            UPDATE user_credential
            SET password_hash = crypt('Dev!1234', gen_salt('bf', 10))
            WHERE user_id = u1_id;
        ELSE
            INSERT INTO user_credential(user_id, password_hash)
            VALUES (u1_id, crypt('Dev!1234', gen_salt('bf', 10)));
        END IF;

        IF EXISTS (SELECT 1 FROM user_credential WHERE user_id = u2_id) THEN
            UPDATE user_credential
            SET password_hash = crypt('Dev!1234', gen_salt('bf', 10))
            WHERE user_id = u2_id;
        ELSE
            INSERT INTO user_credential(user_id, password_hash)
            VALUES (u2_id, crypt('Dev!1234', gen_salt('bf', 10)));
        END IF;

        ---------------------------------------------------------------------------
        -- 5) Devices (X-Device-Id 고정 UUID) - V3에서 기본 false 이므로 명시적 FALSE
        ---------------------------------------------------------------------------
        IF NOT EXISTS (SELECT 1 FROM user_device WHERE device_id='11111111-1111-1111-1111-111111111111') THEN
            INSERT INTO user_device(user_id, device_id, platform, is_push_enabled)
            VALUES (u1_id, '11111111-1111-1111-1111-111111111111', 'ANDROID', FALSE)
            RETURNING id INTO d1_id;
        ELSE
            SELECT id INTO d1_id FROM user_device WHERE device_id='11111111-1111-1111-1111-111111111111';
        END IF;

        IF NOT EXISTS (SELECT 1 FROM user_device WHERE device_id='22222222-2222-2222-2222-222222222222') THEN
            INSERT INTO user_device(user_id, device_id, platform, is_push_enabled)
            VALUES (u2_id, '22222222-2222-2222-2222-222222222222', 'IOS', FALSE)
            RETURNING id INTO d2_id;
        ELSE
            SELECT id INTO d2_id FROM user_device WHERE device_id='22222222-2222-2222-2222-222222222222';
        END IF;

        ---------------------------------------------------------------------------
        -- 6) User-Personas (보유/활성)
        ---------------------------------------------------------------------------
        -- demo1: 5종 모두 활성
        IF NOT EXISTS (SELECT 1 FROM user_personas WHERE user_id=u1_id AND persona_id=p_minji)   THEN INSERT INTO user_personas(user_id, persona_id, enabled) VALUES (u1_id, p_minji,   TRUE); END IF;
        IF NOT EXISTS (SELECT 1 FROM user_personas WHERE user_id=u1_id AND persona_id=p_taeo)    THEN INSERT INTO user_personas(user_id, persona_id, enabled) VALUES (u1_id, p_taeo,    TRUE); END IF;
        IF NOT EXISTS (SELECT 1 FROM user_personas WHERE user_id=u1_id AND persona_id=p_ducksu)  THEN INSERT INTO user_personas(user_id, persona_id, enabled) VALUES (u1_id, p_ducksu,  TRUE); END IF;
        IF NOT EXISTS (SELECT 1 FROM user_personas WHERE user_id=u1_id AND persona_id=p_heeyule) THEN INSERT INTO user_personas(user_id, persona_id, enabled) VALUES (u1_id, p_heeyule, TRUE); END IF;
        IF NOT EXISTS (SELECT 1 FROM user_personas WHERE user_id=u1_id AND persona_id=p_jiyule)  THEN INSERT INTO user_personas(user_id, persona_id, enabled) VALUES (u1_id, p_jiyule,  TRUE); END IF;

        -- demo2: MINJI/TAEO/HEEYULE만 활성
        IF NOT EXISTS (SELECT 1 FROM user_personas WHERE user_id=u2_id AND persona_id=p_minji)   THEN INSERT INTO user_personas(user_id, persona_id, enabled) VALUES (u2_id, p_minji,   TRUE); END IF;
        IF NOT EXISTS (SELECT 1 FROM user_personas WHERE user_id=u2_id AND persona_id=p_taeo)    THEN INSERT INTO user_personas(user_id, persona_id, enabled) VALUES (u2_id, p_taeo,    TRUE); END IF;
        IF NOT EXISTS (SELECT 1 FROM user_personas WHERE user_id=u2_id AND persona_id=p_heeyule) THEN INSERT INTO user_personas(user_id, persona_id, enabled) VALUES (u2_id, p_heeyule, TRUE); END IF;

        ---------------------------------------------------------------------------
        -- 7) 최소 자산/종목 + 회사 뉴스
        ---------------------------------------------------------------------------
        INSERT INTO assets_master(ticker, asset_type) VALUES ('AAPL','stock') ON CONFLICT (ticker) DO NOTHING;
        INSERT INTO assets_master(ticker, asset_type) VALUES ('NVDA','stock') ON CONFLICT (ticker) DO NOTHING;
        INSERT INTO assets_master(ticker, asset_type) VALUES ('TSLA','stock') ON CONFLICT (ticker) DO NOTHING;

        -- stocks_master는 NOT NULL: currency, is_tradable, is_delisted
        INSERT INTO stocks_master
        (ticker, name, exchange, exchange_name, currency, currency_name, country_code, country_name, is_tradable, is_delisted)
        VALUES
            ('AAPL','Apple Inc.','NASDAQ','Nasdaq','USD','US Dollar','US','United States', TRUE, FALSE),
            ('NVDA','NVIDIA Corporation','NASDAQ','Nasdaq','USD','US Dollar','US','United States', TRUE, FALSE),
            ('TSLA','Tesla, Inc.','NASDAQ','Nasdaq','USD','US Dollar','US','United States', TRUE, FALSE)
        ON CONFLICT (ticker) DO UPDATE SET
                                           name          = EXCLUDED.name,
                                           exchange      = EXCLUDED.exchange,
                                           exchange_name = EXCLUDED.exchange_name,
                                           currency      = EXCLUDED.currency,
                                           currency_name = EXCLUDED.currency_name,
                                           country_code  = EXCLUDED.country_code,
                                           country_name  = EXCLUDED.country_name,
                                           is_tradable   = EXCLUDED.is_tradable,
                                           is_delisted   = EXCLUDED.is_delisted;

        -- AAPL 더미 뉴스 1건
        IF NOT EXISTS (SELECT 1 FROM company_news WHERE url='https://dev.local/news/aapl-1') THEN
            INSERT INTO company_news(ticker, title, source, published_at, summary, url)
            VALUES ('AAPL',
                    'Apple: Q4 가이던스 요약(더미)',
                    'DevSeed',
                    now() - interval '1 day',
                    '더미 요약: 서비스 매출 확대, 하드웨어 안정 추세. 환율 역풍 약화, RPO 증가.',
                    'https://dev.local/news/aapl-1')
            RETURNING id INTO n1_aapl;
        ELSE
            SELECT id INTO n1_aapl FROM company_news WHERE url='https://dev.local/news/aapl-1' LIMIT 1;
        END IF;

        ---------------------------------------------------------------------------
        -- 8) Chat Sessions (V5 이후: persona_id 없음)
        ---------------------------------------------------------------------------
        -- demo1 - COMPANY(AAPL)
        IF NOT EXISTS (SELECT 1 FROM chat_sessions WHERE user_id=u1_id AND title='Apple quick chat') THEN
            INSERT INTO chat_sessions(user_id, topic_type, title, ticker)
            VALUES (u1_id, 'COMPANY', 'Apple quick chat', 'AAPL')
            RETURNING id INTO s1_company_aapl;
        ELSE
            SELECT id INTO s1_company_aapl FROM chat_sessions WHERE user_id=u1_id AND title='Apple quick chat' LIMIT 1;
        END IF;

        -- demo1 - NEWS(AAPL)
        IF NOT EXISTS (SELECT 1 FROM chat_sessions WHERE user_id=u1_id AND title='AAPL 뉴스 브리핑') THEN
            INSERT INTO chat_sessions(user_id, topic_type, title, ticker, company_news_id)
            VALUES (u1_id, 'NEWS', 'AAPL 뉴스 브리핑', 'AAPL', n1_aapl)
            RETURNING id INTO s2_news_aapl;
        ELSE
            SELECT id INTO s2_news_aapl FROM chat_sessions WHERE user_id=u1_id AND title='AAPL 뉴스 브리핑' LIMIT 1;
        END IF;

        -- demo1 - CUSTOM
        IF NOT EXISTS (SELECT 1 FROM chat_sessions WHERE user_id=u1_id AND title='커스텀 샌드박스') THEN
            INSERT INTO chat_sessions(user_id, topic_type, title)
            VALUES (u1_id, 'CUSTOM', '커스텀 샌드박스')
            RETURNING id INTO s3_custom;
        ELSE
            SELECT id INTO s3_custom FROM chat_sessions WHERE user_id=u1_id AND title='커스텀 샌드박스' LIMIT 1;
        END IF;

        -- demo2 - COMPANY(NVDA)
        IF NOT EXISTS (SELECT 1 FROM chat_sessions WHERE user_id=u2_id AND title='NVIDIA quick chat') THEN
            INSERT INTO chat_sessions(user_id, topic_type, title, ticker)
            VALUES (u2_id, 'COMPANY', 'NVIDIA quick chat', 'NVDA')
            RETURNING id INTO s4_company_nvda;
        ELSE
            SELECT id INTO s4_company_nvda FROM chat_sessions WHERE user_id=u2_id AND title='NVIDIA quick chat' LIMIT 1;
        END IF;

        ---------------------------------------------------------------------------
        -- 9) 세션 스냅샷: chat_session_personas (UNIQUE(session_id, persona_id) 기반)
        ---------------------------------------------------------------------------
        IF s1_company_aapl IS NOT NULL THEN
            INSERT INTO chat_session_personas(session_id, persona_id) VALUES (s1_company_aapl, p_minji)   ON CONFLICT DO NOTHING;
            INSERT INTO chat_session_personas(session_id, persona_id) VALUES (s1_company_aapl, p_heeyule) ON CONFLICT DO NOTHING;
        END IF;

        IF s2_news_aapl IS NOT NULL THEN
            INSERT INTO chat_session_personas(session_id, persona_id) VALUES (s2_news_aapl, p_minji)  ON CONFLICT DO NOTHING;
            INSERT INTO chat_session_personas(session_id, persona_id) VALUES (s2_news_aapl, p_jiyule) ON CONFLICT DO NOTHING;
        END IF;

        IF s3_custom IS NOT NULL THEN
            INSERT INTO chat_session_personas(session_id, persona_id) VALUES (s3_custom, p_taeo)   ON CONFLICT DO NOTHING;
            INSERT INTO chat_session_personas(session_id, persona_id) VALUES (s3_custom, p_ducksu) ON CONFLICT DO NOTHING;
        END IF;

        IF s4_company_nvda IS NOT NULL THEN
            INSERT INTO chat_session_personas(session_id, persona_id) VALUES (s4_company_nvda, p_taeo) ON CONFLICT DO NOTHING;
        END IF;
    END
$$;
