-- ============================================================
-- DollarIn$ight - Initial Schema (PostgreSQL)
-- ============================================================

-- 0) Extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1) ENUM Types
CREATE TYPE chat_topic_type   AS ENUM ('COMPANY', 'NEWS', 'CUSTOM');
CREATE TYPE chat_role         AS ENUM ('USER', 'ASSISTANT');
CREATE TYPE user_status       AS ENUM ('ACTIVE', 'SUSPENDED', 'WITHDRAWN');
CREATE TYPE platform_type     AS ENUM ('ANDROID', 'IOS');
CREATE TYPE provider_type     AS ENUM ('GOOGLE', 'KAKAO');
CREATE TYPE notification_type AS ENUM ('PRICE_SPIKE', 'PRICE_DROP', 'NEWS', 'SYSTEM');

-- ============================================================
-- 선행 마스터/참조 (다른 테이블 FK 대상)
-- ============================================================

-- 권리유형 마스터
CREATE TABLE right_types (
                             code        VARCHAR(10) PRIMARY KEY,
                             name        VARCHAR(50) NOT NULL,
                             description TEXT,
                             created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 모든 자산 공통 심볼 허브
CREATE TABLE assets_master (
                               ticker     VARCHAR(16) PRIMARY KEY,
                               asset_type VARCHAR(10) NOT NULL CHECK (asset_type IN ('stock','etf','index')),
                               created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
                               updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 종목 뉴스 (세션에서 참조)
CREATE TABLE company_news (
                              id           BIGSERIAL PRIMARY KEY,
                              ticker       VARCHAR(16) REFERENCES assets_master(ticker),
                              uuid         UUID NOT NULL DEFAULT gen_random_uuid(),
                              title        TEXT NOT NULL,
                              source       VARCHAR(128) NOT NULL,
                              published_at TIMESTAMPTZ NOT NULL,
                              summary      TEXT,
                              url          TEXT NOT NULL UNIQUE,
                              created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
                              updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 개별 자산 마스터
CREATE TABLE stocks_master (
                               ticker             VARCHAR(16) PRIMARY KEY REFERENCES assets_master(ticker),
                               name               VARCHAR(120) NOT NULL,
                               name_eng           VARCHAR(120),
                               exchange           VARCHAR(16),
                               exchange_name      VARCHAR(50),
                               currency           VARCHAR(8)  NOT NULL DEFAULT 'USD',
                               currency_name      VARCHAR(50) DEFAULT 'US dollar',
                               currency_precision INT,
                               country_code       VARCHAR(3)  DEFAULT 'US',
                               country_name       VARCHAR(50) DEFAULT 'United States',
                               sector_code        VARCHAR(20),
                               sector_name        VARCHAR(100),
                               industry           VARCHAR(100),
                               listed_at          DATE,
                               shares_outstanding BIGINT,
                               market_code        VARCHAR(10),
                               isin_code          VARCHAR(12),
                               sedol_no           VARCHAR(7),
                               bloomberg_ticker   VARCHAR(20),
                               lot_size           INT,
                               tick_size          NUMERIC(10,4),
                               par_value          NUMERIC(20,6),
                               is_tradable        BOOLEAN NOT NULL,
                               is_delisted        BOOLEAN NOT NULL,
                               delist_date        DATE,
                               website            VARCHAR(200),
                               created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
                               updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE etf_master (
                            ticker          VARCHAR(16) PRIMARY KEY REFERENCES assets_master(ticker),
                            name            VARCHAR(200) NOT NULL,
                            exchange        VARCHAR(10)  NOT NULL,
                            exchange_name   VARCHAR(50),
                            currency        VARCHAR(3) NOT NULL DEFAULT 'USD',
                            currency_name   VARCHAR(50) DEFAULT 'US Dollar',
                            expense_ratio   NUMERIC(6,3),
                            is_leverage     BOOLEAN NOT NULL,
                            leverage_factor NUMERIC(5,2),
                            created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
                            updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE index_master (
                              ticker     VARCHAR(16) PRIMARY KEY REFERENCES assets_master(ticker),
                              name       VARCHAR(200) NOT NULL,
                              provider   VARCHAR(100),
                              base_value NUMERIC(20,4),
                              created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
                              updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================

-- ============================================================

-- users (같은 이메일 재가입 허용: 아래 부분 유니크 인덱스 참고)
CREATE TABLE users (
                       id         SERIAL PRIMARY KEY,
                       uuid       UUID NOT NULL DEFAULT gen_random_uuid(),
                       email      VARCHAR(256) NOT NULL,
                       nickname   TEXT NOT NULL,
                       status     user_status NOT NULL DEFAULT 'ACTIVE',
                       deleted_at TIMESTAMPTZ,
                       created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
                       updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- user_oauth_account
CREATE TABLE user_oauth_account (
                                    id                SERIAL PRIMARY KEY,
                                    uuid              UUID NOT NULL DEFAULT gen_random_uuid(),
                                    user_id           INT  NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                                    provider          provider_type NOT NULL,
                                    provider_user_id  TEXT NOT NULL,
                                    email_at_provider VARCHAR(256),
                                    linked_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
                                    UNIQUE (provider, provider_user_id)
);

-- user_credential (로컬 로그인)
CREATE TABLE user_credential (
                                 id            SERIAL PRIMARY KEY,
                                 uuid          UUID NOT NULL DEFAULT gen_random_uuid(),
                                 user_id       INT  NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                                 password_hash TEXT NOT NULL,
                                 UNIQUE (user_id)
);

-- user_device
CREATE TABLE user_device (
                             id               SERIAL PRIMARY KEY,
                             uuid             UUID NOT NULL DEFAULT gen_random_uuid(),
                             user_id          INT  NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                             device_id        VARCHAR(128) NOT NULL UNIQUE,
                             platform         platform_type NOT NULL,
                             push_token       TEXT,
                             is_push_enabled  BOOLEAN NOT NULL DEFAULT TRUE,
                             last_activate_at TIMESTAMPTZ,
                             created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- user_session
CREATE TABLE user_session (
                              id                 SERIAL PRIMARY KEY,
                              uuid               UUID NOT NULL DEFAULT gen_random_uuid(),
                              user_id            INT  NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                              device_id          INT  NOT NULL REFERENCES user_device(id) ON DELETE CASCADE,
                              refresh_token_hash TEXT NOT NULL,
                              issued_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
                              expires_at         TIMESTAMPTZ,
                              revoked_at         TIMESTAMPTZ,
                              revoke_reason      TEXT,
                              UNIQUE (refresh_token_hash)
);

-- notifications
CREATE TABLE notifications (
                               id           SERIAL PRIMARY KEY,
                               user_id      INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                               ticker       VARCHAR(16) REFERENCES assets_master(ticker),
                               title        VARCHAR(255) NOT NULL,
                               content      TEXT,
                               type         notification_type NOT NULL,
                               is_delivered BOOLEAN NOT NULL DEFAULT FALSE,
                               delivered_at TIMESTAMPTZ,
                               is_read      BOOLEAN NOT NULL DEFAULT FALSE,
                               read_at      TIMESTAMPTZ,
                               created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
                               CONSTRAINT chk_notifications_ticker_type
                                   CHECK (type = 'SYSTEM' OR ticker IS NOT NULL)
);

-- personas  (예: Minji, Taeo, Ducksu, Heeyule, Jiyule)
CREATE TABLE personas (
                          id             SERIAL PRIMARY KEY,
                          code           TEXT NOT NULL UNIQUE,
                          name_ko        TEXT NOT NULL,
                          description_ko TEXT NOT NULL,
                          prompt         TEXT NOT NULL,
                          is_active      BOOLEAN NOT NULL DEFAULT TRUE,
                          is_default_on  BOOLEAN NOT NULL DEFAULT TRUE,
                          created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
                          updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- user_personas (유저가 보유/활성화한 페르소나)
CREATE TABLE user_personas (
                               id         SERIAL PRIMARY KEY,
                               user_id    INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                               persona_id INT NOT NULL REFERENCES personas(id),
                               enabled    BOOLEAN NOT NULL,
                               UNIQUE (user_id, persona_id)
);

-- chat_sessions
--  - persona_id는 personas를 직접 참조
--  - 동시에 (user_id, persona_id) → user_personas 로 조합 FK (유저가 가진 페르소나만 허용)
--  - NEWS 삭제 시 세션 유지: company_news_id ON DELETE SET NULL
CREATE TABLE chat_sessions (
                               id               SERIAL PRIMARY KEY,
                               ticker           VARCHAR(16) REFERENCES assets_master(ticker),
                               uuid             UUID NOT NULL DEFAULT gen_random_uuid(),
                               user_id          INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                               topic_type       chat_topic_type NOT NULL,
                               company_news_id  BIGINT REFERENCES company_news(id) ON DELETE SET NULL,
                               title            VARCHAR(256),
                               persona_id       INT NOT NULL REFERENCES personas(id),
                               max_user_msgs    INT NOT NULL DEFAULT 20,
                               user_msg_count   INT NOT NULL DEFAULT 0,
                               last_user_msg_at TIMESTAMPTZ,
                               created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
                               updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
                               CONSTRAINT fk_chat_sessions_user_persona
                                   FOREIGN KEY (user_id, persona_id)
                                       REFERENCES user_personas (user_id, persona_id)
                                       ON UPDATE CASCADE
                                       ON DELETE RESTRICT,
                               CONSTRAINT chk_chat_sessions_ticker_required
                                   CHECK (topic_type <> 'COMPANY' OR ticker IS NOT NULL)
);

-- chat_messages
CREATE TABLE chat_messages (
                               id         SERIAL PRIMARY KEY,
                               session_id INT  NOT NULL REFERENCES chat_sessions(id) ON DELETE CASCADE,
                               role       chat_role NOT NULL,
                               content    TEXT NOT NULL,
                               created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- stocks_persona
CREATE TABLE stocks_persona (
                                id         BIGSERIAL PRIMARY KEY,
                                ticker     VARCHAR(16) NOT NULL REFERENCES stocks_master(ticker),
                                persona_id INT NOT NULL REFERENCES personas(id),
                                comment    TEXT NOT NULL,
                                created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
                                UNIQUE (ticker, persona_id)
);

-- etf_persona
CREATE TABLE etf_persona (
                             id         BIGSERIAL PRIMARY KEY,
                             ticker     VARCHAR(16) NOT NULL REFERENCES etf_master(ticker),
                             persona_id INT NOT NULL REFERENCES personas(id),
                             comment    TEXT NOT NULL,
                             created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
                             UNIQUE (ticker, persona_id)
);

-- ============================================================
-- 나머지 도메인
-- ============================================================

-- 유저 워치리스트
CREATE TABLE user_watchlist (
                                id         SERIAL PRIMARY KEY,
                                user_id    INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                                ticker     VARCHAR(16) NOT NULL REFERENCES assets_master(ticker),
                                created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
                                UNIQUE (user_id, ticker)
);

-- 주가(일별)
CREATE TABLE stock_price_daily (
                                   price_date    DATE NOT NULL,
                                   ticker        VARCHAR(16) NOT NULL REFERENCES stocks_master(ticker),
                                   open          NUMERIC(18,4) NOT NULL,
                                   high          NUMERIC(18,4) NOT NULL,
                                   low           NUMERIC(18,4) NOT NULL,
                                   close         NUMERIC(18,4) NOT NULL,
                                   adj_close     NUMERIC(18,4),
                                   volume        BIGINT,
                                   amount        NUMERIC(20,2),
                                   change        FLOAT,
                                   change_pct    FLOAT,
                                   change_sign   VARCHAR(1),
                                   bid           NUMERIC(18,4),
                                   ask           NUMERIC(18,4),
                                   bid_size      BIGINT,
                                   ask_size      BIGINT,
                                   source_vendor VARCHAR(20) DEFAULT 'KIS',
                                   created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
                                   PRIMARY KEY (price_date, ticker)
);

-- ETF 가격(일별)
CREATE TABLE etf_price_daily (
                                 price_date DATE NOT NULL,
                                 ticker     VARCHAR(16) NOT NULL REFERENCES etf_master(ticker),
                                 open       NUMERIC(18,4),
                                 high       NUMERIC(18,4),
                                 low        NUMERIC(18,4),
                                 close      NUMERIC(18,4) NOT NULL,
                                 volume     BIGINT,
                                 created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
                                 PRIMARY KEY (price_date, ticker)
);

-- 지수 가격(일별)
CREATE TABLE index_price_daily (
                                   price_date DATE NOT NULL,
                                   ticker     VARCHAR(16) NOT NULL REFERENCES index_master(ticker),
                                   close      NUMERIC(18,4) NOT NULL,
                                   change_pct FLOAT,
                                   created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
                                   PRIMARY KEY (price_date, ticker)
);

-- 액면분할/병합
CREATE TABLE stocks_splits (
                               split_date    DATE NOT NULL,
                               ticker        VARCHAR(16) NOT NULL REFERENCES stocks_master(ticker),
                               split_ratio   NUMERIC(10,4) NOT NULL,
                               source_vendor VARCHAR(20) DEFAULT 'KIS',
                               created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
                               PRIMARY KEY (split_date, ticker)
);

-- 배당/권리
CREATE TABLE stocks_dividends (
                                  id                    BIGSERIAL PRIMARY KEY,
                                  ticker                VARCHAR(16) NOT NULL REFERENCES stocks_master(ticker),
                                  code                  VARCHAR(10) NOT NULL REFERENCES right_types(code),
                                  basis_date            DATE NOT NULL,
                                  dividend_per_share    NUMERIC(20,4) NOT NULL,
                                  currency_code         VARCHAR(3) NOT NULL,
                                  is_confirmed          BOOLEAN NOT NULL DEFAULT TRUE,
                                  basis_date_local      DATE,
                                  subscription_start    DATE,
                                  subscription_end      DATE,
                                  cash_allocation_rate  NUMERIC(10,4),
                                  stock_allocation_rate NUMERIC(10,4),
                                  source_vendor         VARCHAR(20) DEFAULT 'KIS',
                                  created_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 기술적 지표(일별)
CREATE TABLE stock_metrics_daily (
                                     metric_date    DATE NOT NULL,
                                     ticker         VARCHAR(16) NOT NULL REFERENCES stocks_master(ticker),
                                     mom_1m         FLOAT,
                                     mom_3m         FLOAT,
                                     mom_6m         FLOAT,
                                     volatility_20  FLOAT,
                                     beta_60        FLOAT,
                                     pos_52w        FLOAT,
                                     turnover       FLOAT,
                                     rsi_14         FLOAT,
                                     ma20           FLOAT,
                                     ma60           FLOAT,
                                     price_to_ma20  FLOAT,
                                     created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
                                     updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
                                     PRIMARY KEY (metric_date, ticker)
);

-- 종합 스코어(일별)
CREATE TABLE stock_scores_daily (
                                    score_date      DATE NOT NULL,
                                    ticker          VARCHAR(16) NOT NULL REFERENCES stocks_master(ticker),
                                    score_momentum  FLOAT,
                                    score_valuation FLOAT,
                                    score_growth    FLOAT,
                                    score_flow      FLOAT,
                                    score_risk      FLOAT,
                                    total_score     FLOAT,
                                    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
                                    PRIMARY KEY (score_date, ticker)
);

-- ETF 보유종목
CREATE TABLE etf_holdings (
                              id               BIGSERIAL PRIMARY KEY,
                              ticker           VARCHAR(16) NOT NULL REFERENCES etf_master(ticker),
                              component_ticker VARCHAR(16) NOT NULL REFERENCES stocks_master(ticker),
                              weight           NUMERIC(6,3) NOT NULL,
                              shares           BIGINT,
                              as_of_date       DATE,
                              source_vendor    VARCHAR(20) DEFAULT 'yfinance',
                              created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 재무제표
CREATE TABLE stocks_financial_statements (
                                             period                 VARCHAR(20) NOT NULL,
                                             period_type            VARCHAR(10) NOT NULL,   -- 'annual' | 'quarterly'
                                             ticker                 VARCHAR(16) NOT NULL REFERENCES stocks_master(ticker),
                                             revenue                NUMERIC(20,2),
                                             cost_of_revenue        NUMERIC(20,2),
                                             gross_profit           NUMERIC(20,2),
                                             operating_expenses     NUMERIC(20,2),
                                             operating_income       NUMERIC(20,2),
                                             interest_expense       NUMERIC(20,2),
                                             pretax_income          NUMERIC(20,2),
                                             tax_provision          NUMERIC(20,2),
                                             net_income             NUMERIC(20,2),
                                             total_assets           NUMERIC(20,2),
                                             cash_and_equivalents   NUMERIC(20,2),
                                             current_assets         NUMERIC(20,2),
                                             total_liabilities      NUMERIC(20,2),
                                             current_liabilities    NUMERIC(20,2),
                                             long_term_debt         NUMERIC(20,2),
                                             total_equity           NUMERIC(20,2),
                                             operating_cashflow     NUMERIC(20,2),
                                             investing_cashflow     NUMERIC(20,2),
                                             financing_cashflow     NUMERIC(20,2),
                                             capex                  NUMERIC(20,2),
                                             free_cashflow          NUMERIC(20,2),
                                             dividends_paid         NUMERIC(20,2),
                                             stock_repurchase       NUMERIC(20,2),
                                             operating_margin       NUMERIC(20,2),
                                             net_margin             NUMERIC(10,4),
                                             debt_to_equity         NUMERIC(10,4),
                                             current_ratio          NUMERIC(10,4),
                                             roa                    NUMERIC(10,4),
                                             roe                    NUMERIC(10,4),
                                             fcf_yield              NUMERIC(10,4),
                                             revenue_growth_yoy     NUMERIC(10,4),
                                             net_income_growth_yoy  NUMERIC(10,4),
                                             source_vendor          VARCHAR(20) DEFAULT 'yfinance',
                                             created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
                                             PRIMARY KEY (ticker, period, period_type)
);

-- 거시지표
CREATE TABLE macro_economic_indicators (
                                           indicator_code   VARCHAR(20) NOT NULL,
                                           date             DATE NOT NULL,
                                           value            NUMERIC(20,4) NOT NULL,
                                           unit             VARCHAR(20),
                                           seasonal_adjustment VARCHAR(10),
                                           change_mom       NUMERIC(10,4),
                                           change_yoy       NUMERIC(10,4),
                                           release_id       VARCHAR(50),
                                           source           VARCHAR(50),
                                           source_vendor    VARCHAR(20) DEFAULT 'FRED',
                                           created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
                                           PRIMARY KEY (indicator_code, date)
);

-- ============================================================
-- 인덱스/운영 최적화
-- ============================================================

-- 이메일: 활성(삭제 안됨) 사용자만 유니크 → 같은 이메일 재가입 허용(과거 soft-delete 전제)
CREATE UNIQUE INDEX uq_users_email_active
    ON users (lower(email))
    WHERE deleted_at IS NULL;
CREATE INDEX ix_users_email_lower ON users (lower(email));

-- 세션/채팅 조회
CREATE INDEX ix_user_device_user_id      ON user_device(user_id);
CREATE INDEX ix_user_session_user_id     ON user_session(user_id);
CREATE INDEX ix_user_session_device_id   ON user_session(device_id);
CREATE INDEX ix_user_personas_user       ON user_personas(user_id, persona_id) INCLUDE(enabled);
CREATE INDEX ix_chat_sessions_user       ON chat_sessions(user_id, created_at DESC);
CREATE INDEX ix_chat_sessions_user_per   ON chat_sessions(user_id, persona_id);
CREATE INDEX ix_chat_messages_session    ON chat_messages(session_id, created_at);

-- 시계열 조회
CREATE INDEX ix_stock_price_ticker_dt    ON stock_price_daily (ticker, price_date DESC);
CREATE INDEX ix_etf_price_ticker_dt      ON etf_price_daily   (ticker, price_date DESC);
CREATE INDEX ix_index_price_ticker_dt    ON index_price_daily (ticker, price_date DESC);
CREATE INDEX ix_company_news_ticker_pub  ON company_news (ticker, published_at DESC);

-- 알림 조회
CREATE INDEX ix_notifications_user       ON notifications(user_id, is_read, created_at DESC);

-- ============================================================
-- 체크/트리거: chat_sessions는 '활성화된' 유저-페르소나만 허용
-- ============================================================
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

-- ============================================================
-- updated_at 자동 갱신 트리거 (updated_at 보유 테이블)
-- ============================================================
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at := now();
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_assets_master_updated_at    BEFORE UPDATE ON assets_master    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_company_news_updated_at     BEFORE UPDATE ON company_news     FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_stocks_master_updated_at    BEFORE UPDATE ON stocks_master    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_etf_master_updated_at       BEFORE UPDATE ON etf_master       FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_index_master_updated_at     BEFORE UPDATE ON index_master     FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_users_updated_at            BEFORE UPDATE ON users            FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_personas_updated_at         BEFORE UPDATE ON personas         FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_chat_sessions_updated_at    BEFORE UPDATE ON chat_sessions    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_stock_metrics_updated_at    BEFORE UPDATE ON stock_metrics_daily FOR EACH ROW EXECUTE FUNCTION set_updated_at();
