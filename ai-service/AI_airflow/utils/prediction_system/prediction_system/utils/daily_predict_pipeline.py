"""일일 예측 파이프라인 스텁."""

from __future__ import annotations

import datetime as dt
from typing import Dict, Tuple

import os
import pandas as pd

from pipelines.watchlists import METRIC_STOCKS

from .prediction_dao import upsert_predictions
from .stock_price_dao import fetch_latest_price_date
from .feature_store_builder import build_feature_store
from .predictor import generate_daily_predictions
from .logger import get_logger

logger = get_logger(__name__)

MIN_REQUIRED_LOOKBACK = 260

_TASK_DEFINITIONS: Dict[str, Dict] = {
    "regression_5d": {"type": "regression", "horizon": 5, "quantile": 0.9},
    "classification_5d": {"type": "classification", "horizon": 5},
    "regression_20d": {"type": "regression", "horizon": 20, "quantile": 0.9},
    "classification_20d": {"type": "classification", "horizon": 20},
}


def _is_trading_day(target: dt.date) -> bool:
    return target.weekday() < 5


def _combine_predictions(raw_df: pd.DataFrame) -> list[dict]:
    combined: dict[Tuple[str, int], dict] = {}
    for record in raw_df.to_dict("records"):
        key = (record["ticker"], record["horizon_days"])
        entry = combined.setdefault(
            key,
            {
                "prediction_date": record["prediction_date"],
                "ticker": record["ticker"],
                "horizon_days": record["horizon_days"],
                "point_estimate": None,
                "lower_bound": None,
                "upper_bound": None,
                "prob_up": None,
                "model_version": record.get("model_version"),
                "classification_model_version": None,
                "regression_model_version": None,
                "decision_threshold": None,
                "residual_quantile": record.get("residual_quantile"),
                "feature_window_id": record.get("feature_window_id"),
                "signal_up": None,
                "high_confidence_signal": None,
                "joint_high_confidence_signal": None,
            },
        )
        point_estimate = record.get("point_estimate")
        if point_estimate is not None and not pd.isna(point_estimate):
            entry["point_estimate"] = point_estimate
            entry["lower_bound"] = record.get("lower_bound")
            entry["upper_bound"] = record.get("upper_bound")
            entry["regression_model_version"] = record.get("model_version")
            if entry.get("model_version") is None:
                entry["model_version"] = record.get("model_version")
            residual_quantile = record.get("residual_quantile")
            if residual_quantile is not None and not pd.isna(residual_quantile):
                entry["residual_quantile"] = residual_quantile

        prob_up = record.get("prob_up")
        if prob_up is not None and not pd.isna(prob_up):
            entry["prob_up"] = prob_up
            entry["classification_model_version"] = record.get("model_version")
            entry["model_version"] = record.get("model_version")
            if record.get("decision_threshold") is not None:
                entry["decision_threshold"] = record.get("decision_threshold")
    return list(combined.values())


def _annotate_signals(records: list[dict]) -> None:
    high_thresholds = {
        5: float(os.getenv("PRED_HIGH_CONF_THRESHOLD_5D", "0.55")),
        20: float(os.getenv("PRED_HIGH_CONF_THRESHOLD_20D", "0.52")),
    }
    grouped: dict[tuple, dict[int, dict]] = {}
    for rec in records:
        key = (rec["prediction_date"], rec["ticker"])
        grouped.setdefault(key, {})[rec["horizon_days"]] = rec
        horizon = rec["horizon_days"]
        prob = rec.get("prob_up")
        if prob is not None:
            threshold = rec.get("decision_threshold") or 0.5
            rec["signal_up"] = bool(prob >= threshold)
            high_th = high_thresholds.get(horizon, threshold)
            rec["high_confidence_signal"] = bool(prob >= high_th)
        else:
            rec["signal_up"] = None
            rec["high_confidence_signal"] = None
    for items in grouped.values():
        high_5 = items.get(5, {}).get("high_confidence_signal")
        high_20 = items.get(20, {}).get("high_confidence_signal")
        joint = None
        if high_5 is not None and high_20 is not None:
            joint = bool(high_5 and high_20)
        if joint is not None:
            if 5 in items:
                items[5]["joint_high_confidence_signal"] = joint
            if 20 in items:
                items[20]["joint_high_confidence_signal"] = joint


def run(
    target_date: dt.date | None = None,
    *,
    lookback_days: int = 260,
    persist: bool = True,
) -> list[dict] | None:
    """일별 예측 파이프라인 엔트리포인트."""

    resolved_date = target_date or fetch_latest_price_date()
    if resolved_date is None:
        logger.warning("예측 대상 날짜를 결정할 수 없어 종료합니다.")
        return None

    if not _is_trading_day(resolved_date):
        logger.info("%s 는 비거래일이므로 예측을 건너뜁니다.", resolved_date)
        return None

    resolved_ts = pd.Timestamp(resolved_date)

    effective_lookback = max(lookback_days, MIN_REQUIRED_LOOKBACK)
    start_date = resolved_ts.date() - dt.timedelta(days=effective_lookback)
    logger.info(
        "일별 예측 시작: target=%s, window=%s~%s, universe=%d종",
        resolved_ts.date(),
        start_date,
        resolved_ts.date(),
        len(METRIC_STOCKS),
    )

    features = build_feature_store((start_date, resolved_ts.date()), METRIC_STOCKS)
    if features.empty:
        logger.warning("예측을 위한 feature가 비어 있습니다.")
        return None

    try:
        feature_slice = features.xs(resolved_ts, level="feature_date")
    except KeyError:
        logger.warning("대상 날짜 %s 의 feature가 존재하지 않습니다.", resolved_ts.date())
        return None

    feature_slice.index = pd.MultiIndex.from_product([feature_slice.index, [resolved_ts]], names=["ticker", "feature_date"])
    for cfg in _TASK_DEFINITIONS.values():
        cfg["feature_window_id"] = f"{start_date:%Y%m%d}_{resolved_ts:%Y%m%d}"

    raw_predictions = generate_daily_predictions(feature_slice, _TASK_DEFINITIONS)
    if raw_predictions.empty:
        logger.warning("생성된 예측 데이터가 없습니다.")
        return None

    combined_records = _combine_predictions(raw_predictions)
    if not combined_records:
        logger.warning("결합된 예측 레코드가 없습니다.")
        return None

    _annotate_signals(combined_records)

    if persist:
        upsert_predictions(combined_records)
        logger.info("예측 저장 완료: records=%d", len(combined_records))
    return combined_records


