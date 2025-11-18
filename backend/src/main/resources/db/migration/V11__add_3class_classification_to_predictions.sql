-- V11__add_3class_classification_to_predictions.sql
-- stock_predictions_daily 테이블에 3-class classification 컬럼 추가
-- (초과수익률 기반 top/mid/bottom 분류 결과 저장)

-- ============================================================
-- stock_predictions_daily 테이블에 3-class classification 컬럼 추가
-- ============================================================

ALTER TABLE stock_predictions_daily
    ADD COLUMN IF NOT EXISTS prob_top NUMERIC(6,5);

ALTER TABLE stock_predictions_daily
    ADD COLUMN IF NOT EXISTS prob_mid NUMERIC(6,5);

ALTER TABLE stock_predictions_daily
    ADD COLUMN IF NOT EXISTS prob_bottom NUMERIC(6,5);

ALTER TABLE stock_predictions_daily
    ADD COLUMN IF NOT EXISTS predicted_class VARCHAR(10);

-- predicted_class에 CHECK 제약조건 추가 (top, mid, bottom만 허용)
ALTER TABLE stock_predictions_daily
    DROP CONSTRAINT IF EXISTS chk_stock_predictions_predicted_class;

ALTER TABLE stock_predictions_daily
    ADD CONSTRAINT chk_stock_predictions_predicted_class
    CHECK (predicted_class IS NULL OR predicted_class IN ('top', 'mid', 'bottom'));

-- 인덱스 추가 (predicted_class로 필터링 시 성능 향상)
CREATE INDEX IF NOT EXISTS ix_stock_predictions_daily_class
    ON stock_predictions_daily (prediction_date DESC, predicted_class)
    WHERE predicted_class IS NOT NULL;

-- 코멘트 추가
COMMENT ON COLUMN stock_predictions_daily.prob_top IS '상위 30% 클래스 확률 (초과수익률 기반)';
COMMENT ON COLUMN stock_predictions_daily.prob_mid IS '중간 40% 클래스 확률 (초과수익률 기반)';
COMMENT ON COLUMN stock_predictions_daily.prob_bottom IS '하위 30% 클래스 확률 (초과수익률 기반)';
COMMENT ON COLUMN stock_predictions_daily.predicted_class IS '예측된 클래스 (top/mid/bottom)';

