-- V9__stocks_master_valuation_columns.sql
-- 목적: 기업 분석 화면에서 요구하는 지표(시가총액, PBR, PER)를 stocks_master에 추가

ALTER TABLE stocks_master
    ADD COLUMN IF NOT EXISTS market_cap NUMERIC(20,2);

ALTER TABLE stocks_master
    ADD COLUMN IF NOT EXISTS pbr NUMERIC(12,6);

ALTER TABLE stocks_master
    ADD COLUMN IF NOT EXISTS per NUMERIC(12,6);
