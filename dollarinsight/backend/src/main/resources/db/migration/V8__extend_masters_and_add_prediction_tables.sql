-- V8__extend_masters_and_add_prediction_tables.sql
-- 1) stocks_master / etf_master 컬럼 확장
-- 2) etf_metrics_daily / stock_predictions_daily 신규 테이블 생성

-- ============================================================
-- 1. stocks_master 컬럼 추가 (존재하지 않을 때만)
-- ============================================================

ALTER TABLE stocks_master
    ADD COLUMN IF NOT EXISTS dividend_yield_annualized NUMERIC(12,6);

ALTER TABLE stocks_master
    ADD COLUMN IF NOT EXISTS roe NUMERIC(12,6);

ALTER TABLE stocks_master
    ADD COLUMN IF NOT EXISTS psr NUMERIC(12,6);

-- ============================================================
-- 2. etf_master 컬럼 추가
-- ============================================================

ALTER TABLE etf_master
    ADD COLUMN IF NOT EXISTS market_cap_latest NUMERIC(20,2);

ALTER TABLE etf_master
    ADD COLUMN IF NOT EXISTS total_assets_latest NUMERIC(20,2);

ALTER TABLE etf_master
    ADD COLUMN IF NOT EXISTS nav_latest NUMERIC(18,6);

ALTER TABLE etf_master
    ADD COLUMN IF NOT EXISTS premium_discount_latest NUMERIC(9,6);

ALTER TABLE etf_master
    ADD COLUMN IF NOT EXISTS dividend_yield_latest NUMERIC(9,6);

ALTER TABLE etf_master
    ADD COLUMN IF NOT EXISTS metrics_updated_at TIMESTAMPTZ;

-- ============================================================
-- 3. etf_metrics_daily 테이블 생성
-- ============================================================

CREATE TABLE IF NOT EXISTS etf_metrics_daily (
    as_of_date        DATE        NOT NULL,
    ticker            VARCHAR(16) NOT NULL REFERENCES etf_master(ticker),
    market_cap        NUMERIC(20,2),
    dividend_yield    NUMERIC(9,6),
    total_assets      NUMERIC(20,2),
    nav               NUMERIC(18,6),
    premium_discount  NUMERIC(9,6),
    expense_ratio     NUMERIC(6,4),
    data_source       VARCHAR(20),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (as_of_date, ticker)
);

CREATE INDEX IF NOT EXISTS ix_etf_metrics_daily_ticker_date
    ON etf_metrics_daily (ticker, as_of_date DESC);

-- ============================================================
-- 4. stock_predictions_daily 테이블 생성
-- ============================================================

CREATE TABLE IF NOT EXISTS stock_predictions_daily (
    prediction_date   DATE        NOT NULL,
    ticker            VARCHAR(16) NOT NULL REFERENCES stocks_master(ticker),
    horizon_days      SMALLINT    NOT NULL,
    point_estimate    NUMERIC(18,6),
    lower_bound       NUMERIC(18,6),
    upper_bound       NUMERIC(18,6),
    prob_up           NUMERIC(6,5),
    model_version     VARCHAR(64),
    residual_quantile NUMERIC(6,5),
    feature_window_id VARCHAR(64),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (prediction_date, ticker, horizon_days)
);

CREATE INDEX IF NOT EXISTS ix_stock_predictions_daily_model
    ON stock_predictions_daily (model_version, prediction_date DESC);


