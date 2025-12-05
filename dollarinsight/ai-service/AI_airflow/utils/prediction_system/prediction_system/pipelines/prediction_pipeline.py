from __future__ import annotations

import datetime as dt
import json
from pathlib import Path
from typing import Any, Dict, List

from prediction_system.utils.build_features_pipeline import run as build_features_run
from prediction_system.utils.daily_predict_pipeline import run as daily_predict_run
from prediction_system.local.evaluate_predictions import run as evaluate_run


def _parse_date(value: dt.date | str | None) -> dt.date | None:
    if value is None:
        return None
    if isinstance(value, dt.date):
        return value
    return dt.date.fromisoformat(value)


def run_pipeline(
    *,
    target_date: dt.date | str,
    lookback_days: int = 260,
    persist_predictions: bool = True,
    build_features: bool = True,
    predictions_output_path: str | Path | None = None,
    evaluate: bool = False,
    eval_start: dt.date | str | None = None,
    eval_end: dt.date | str | None = None,
    eval_horizons: List[int] | None = None,
    eval_prob_threshold: float = -1.0,
    eval_bias_threshold: float = 0.02,
    eval_output_dir: str | Path | None = None,
) -> List[Dict[str, Any]] | None:
    """
    일별 예측 파이프라인 엔트리포인트.

    - 주기: 매일
    - 기능:
        1) (선택) 대상 날짜 기준 feature store 업데이트
        2) 학습된 모델을 사용해 일별 예측 실행
        3) (선택) 예측 결과 평가 및 리포트 저장
    """

    target_date_dt = _parse_date(target_date)
    if target_date_dt is None:
        raise ValueError("target_date 는 필수 입력입니다.")

    if build_features:
        build_features_run(date=target_date_dt)

    predictions = daily_predict_run(
        target_date=target_date_dt,
        lookback_days=lookback_days,
        persist=persist_predictions,
    )

    if predictions_output_path and predictions is not None:
        path = Path(predictions_output_path)
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open("w", encoding="utf-8") as fp:
            json.dump(predictions, fp, indent=2, ensure_ascii=False, default=str)

    if evaluate:
        eval_start_dt = _parse_date(eval_start)
        eval_end_dt = _parse_date(eval_end) or target_date_dt
        if eval_start_dt is None:
            eval_start_dt = eval_end_dt - dt.timedelta(days=20)
        horizons = eval_horizons or [5, 20]
        output_dir = Path(eval_output_dir) if eval_output_dir else Path("prediction_system/output/eval")
        evaluate_run(
            start_date=eval_start_dt,
            end_date=eval_end_dt,
            horizons=horizons,
            probability_threshold=eval_prob_threshold if eval_prob_threshold >= 0 else None,
            bias_threshold=eval_bias_threshold,
            output_dir=output_dir,
        )

    return predictions


__all__ = ["run_pipeline"]


