from __future__ import annotations

import datetime as dt
import json
from pathlib import Path
from typing import Any, Dict

from prediction_system.utils.build_features_pipeline import run as build_features_run
from prediction_system.utils.train_models_pipeline import run as train_models_run


def _parse_date(value: dt.date | str | None) -> dt.date | None:
    if value is None:
        return None
    if isinstance(value, dt.date):
        return value
    return dt.date.fromisoformat(value)


def run_pipeline(
    *,
    train_start: dt.date | str,
    train_end: dt.date | str,
    feature_target: dt.date | str | None = None,
    lookback_days: int = 260,
    build_features: bool = True,
    feature_output_path: str | Path | None = None,
    training_output_path: str | Path | None = None,
) -> Dict[str, Dict[str, Any]] | None:
    """
    모델 학습 파이프라인 엔트리포인트.

    - 주기: 주 1회 (또는 필요 시)
    - 기능:
        1) (선택) 지정된 날짜 기준으로 feature store 재생성
        2) 주어진 학습 구간으로 모델 학습 실행
        3) 결과를 JSON으로 저장 (경로 지정 시)
    """

    train_start_dt = _parse_date(train_start)
    train_end_dt = _parse_date(train_end)
    feature_target_dt = _parse_date(feature_target) or train_end_dt

    if train_start_dt is None or train_end_dt is None:
        raise ValueError("train_start 와 train_end 는 필수 입력입니다.")

    feature_meta: Dict[str, Any] | None = None
    if build_features and feature_target_dt is not None:
        feature_meta = build_features_run(date=feature_target_dt)
        if feature_output_path:
            path = Path(feature_output_path)
            path.parent.mkdir(parents=True, exist_ok=True)
            with path.open("w", encoding="utf-8") as fp:
                json.dump(feature_meta or {}, fp, indent=2, ensure_ascii=False, default=str)

    train_results = train_models_run(
        train_start=train_start_dt,
        train_end=train_end_dt,
        lookback_days=lookback_days,
    )

    if training_output_path:
        path = Path(training_output_path)
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open("w", encoding="utf-8") as fp:
            json.dump(train_results or {}, fp, indent=2, ensure_ascii=False, default=str)

    return train_results


__all__ = ["run_pipeline"]


