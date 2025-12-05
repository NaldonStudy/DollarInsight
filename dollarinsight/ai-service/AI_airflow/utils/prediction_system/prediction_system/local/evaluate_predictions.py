from __future__ import annotations

import argparse
import datetime as dt
import json
import os
from pathlib import Path
from typing import Dict, Iterable, List, Optional

import numpy as np
import pandas as pd
from sklearn.metrics import balanced_accuracy_score

from prediction_system.utils.daily_predict_pipeline import run as predict_run
from prediction_system.utils.model_registry import load_metadata, update_metadata
from prediction_system.utils.stock_price_dao import fetch_prices
from prediction_system.utils.thresholds import (
    build_threshold_history_entry,
    search_balanced_accuracy_threshold,
)

CLASSIFICATION_THRESHOLDS = {
    5: float(os.getenv("PRED_CLASS_THRESH_5D", "0.003")),
    20: float(os.getenv("PRED_CLASS_THRESH_20D", "0.01")),
}
def _load_min_precision(horizon: int) -> float:
    env_specific = os.getenv(f"PRED_THRESHOLD_MIN_PRECISION_{horizon}D")
    if env_specific is not None:
        try:
            return float(env_specific)
        except ValueError:
            pass
    env_common = os.getenv("PRED_THRESHOLD_MIN_PRECISION")
    if env_common is not None:
        try:
            return float(env_common)
        except ValueError:
            pass
    return 0.5


def _compute_actual_returns(
    tickers: Iterable[str],
    start: dt.date,
    end: dt.date,
    horizons: List[int],
) -> pd.DataFrame:
    max_h = max(horizons)
    price_df = fetch_prices(
        tickers,
        start - dt.timedelta(days=2),
        end + dt.timedelta(days=max_h + 5),
    )
    if price_df.empty:
        return pd.DataFrame()

    df = price_df.copy()
    df["price_date"] = pd.to_datetime(df["price_date"])
    df.sort_values(["ticker", "price_date"], inplace=True)

    df["close"] = pd.to_numeric(df["close"], errors="coerce")

    for horizon in horizons:
        future_close = df.groupby("ticker")["close"].shift(-horizon)
        df[f"actual_return_{horizon}d"] = (
            (future_close - df["close"]) / df["close"].replace(0, np.nan)
        )
        threshold = CLASSIFICATION_THRESHOLDS.get(horizon, 0.0)
        df[f"actual_direction_{horizon}d"] = (
            df[f"actual_return_{horizon}d"] > threshold
        ).astype(float)

    return df


def _calc_classification_metrics(
    df: pd.DataFrame,
    decision_threshold: Optional[float],
    horizon: int,
    model_thresholds: Optional[Dict[int, float]] = None,
) -> Dict[str, float]:
    scores = {}
    mask = df["prob_up"].notna()
    if mask.sum() == 0:
        return {"count": 0}

    effective_threshold = decision_threshold
    if (effective_threshold is None or effective_threshold < 0) and model_thresholds:
        effective_threshold = model_thresholds.get(horizon)
    if effective_threshold is None:
        effective_threshold = 0.5

    y_pred = (df.loc[mask, "prob_up"] >= effective_threshold).astype(int)
    class_threshold = CLASSIFICATION_THRESHOLDS.get(horizon, 0.0)
    y_true = (df.loc[mask, "actual_return"] > class_threshold).astype(int)

    correct = (y_pred == y_true).sum()
    tp = ((y_pred == 1) & (y_true == 1)).sum()
    fp = ((y_pred == 1) & (y_true == 0)).sum()
    fn = ((y_pred == 0) & (y_true == 1)).sum()

    scores["count"] = int(mask.sum())
    scores["accuracy"] = float(correct / len(y_pred)) if len(y_pred) else np.nan
    scores["precision"] = float(tp / (tp + fp)) if (tp + fp) else np.nan
    scores["recall"] = float(tp / (tp + fn)) if (tp + fn) else np.nan
    scores["balanced_accuracy"] = float(balanced_accuracy_score(y_true, y_pred)) if len(y_pred) else np.nan
    return scores


def _calc_regression_metrics(df: pd.DataFrame, bias_threshold: float) -> Dict[str, float]:
    errors = df["point_estimate"] - df["actual_return"]
    metrics = {
        "count": int(len(errors)),
        "mae": float(np.mean(np.abs(errors))) if len(errors) else np.nan,
        "rmse": float(np.sqrt(np.mean(np.square(errors)))) if len(errors) else np.nan,
        "bias": float(np.mean(errors)) if len(errors) else np.nan,
        "mape": float(
            np.mean(
                np.abs(errors / df["actual_return"].replace(0, np.nan))
            )
        )
        if len(errors) else np.nan,
        "coverage": float(
            np.mean(
                (df["lower_bound"].notna())
                & (df["upper_bound"].notna())
                & (df["actual_return"] >= df["lower_bound"])
                & (df["actual_return"] <= df["upper_bound"])
            )
        )
        if len(errors) else np.nan,
    }
    metrics["bias_flagged"] = (
        abs(metrics["bias"]) > bias_threshold if not np.isnan(metrics["bias"]) else False
    )
    return metrics


def run(
    *,
    start_date: dt.date,
    end_date: dt.date,
    horizons: List[int],
    probability_threshold: Optional[float],
    bias_threshold: float,
    output_dir: Path,
    model_thresholds: Optional[Dict[int, float]] = None,
) -> Path | None:
    evaluation_dates = pd.bdate_range(start_date, end_date)
    predictions: List[dict] = []

    for target_date in evaluation_dates:
        pred_records = predict_run(
            target_date=target_date.date(),
            lookback_days=260,
            persist=False,
        )
        if pred_records:
            predictions.extend(pred_records)

    if not predictions:
        return None

    pred_df = pd.DataFrame(predictions)
    pred_df["prediction_date"] = pd.to_datetime(pred_df["prediction_date"])

    tickers = pred_df["ticker"].unique().tolist()
    actual_df = _compute_actual_returns(
        tickers,
        start_date,
        end_date,
        horizons,
    )

    if actual_df.empty:
        return None

    results = {}
    detailed_rows: List[dict] = []

    dynamic_updates: Dict[int, dict] = {}

    for horizon in horizons:
        horizon_df = pred_df[pred_df["horizon_days"] == horizon].copy()
        horizon_df.rename(columns={
            "point_estimate": "point_estimate",
            "lower_bound": "lower_bound",
            "upper_bound": "upper_bound",
            "prob_up": "prob_up",
        }, inplace=True)

        actual_slice = actual_df[[
            "ticker",
            "price_date",
            f"actual_return_{horizon}d",
            f"actual_direction_{horizon}d",
        ]].rename(columns={
            "price_date": "prediction_date",
            f"actual_return_{horizon}d": "actual_return",
            f"actual_direction_{horizon}d": "actual_direction",
        })

        merged = horizon_df.merge(
            actual_slice,
            on=["ticker", "prediction_date"],
            how="inner",
        ).dropna(subset=["actual_return"])

        if merged.empty:
            continue

        reg_metrics = _calc_regression_metrics(merged, bias_threshold)
        cls_metrics = _calc_classification_metrics(
            merged,
            probability_threshold,
            horizon,
            model_thresholds=model_thresholds,
        )
        results[horizon] = {
            "regression": reg_metrics,
            "classification": cls_metrics,
        }

        detailed_rows.extend(merged.to_dict("records"))

        model_versions = merged["model_version"].dropna().unique()
        if len(model_versions) == 1:
            model_version = model_versions[0]
            try:
                metadata = load_metadata(model_id=model_version)
            except Exception:
                metadata = None
            if metadata:
                probs = merged["prob_up"].astype(float)
                actual_dir = merged["actual_direction"].astype(int)
                min_precision = _load_min_precision(horizon)
                threshold_search = search_balanced_accuracy_threshold(
                    probs,
                    actual_dir,
                    candidate_thresholds=np.linspace(0.25, 0.75, 51),
                    min_precision=min_precision,
                )
                if threshold_search:
                    current_threshold = metadata.get("decision_threshold")
                    previous_bal = None
                    if current_threshold is not None:
                        prev_preds = (probs >= float(current_threshold)).astype(int)
                        previous_bal = balanced_accuracy_score(actual_dir, prev_preds)
                    improvement = (
                        threshold_search.balanced_accuracy - previous_bal
                        if previous_bal is not None
                        else None
                    )
                    min_gain = float(os.getenv("PRED_DYNAMIC_THRESHOLD_MIN_GAIN", "0.0"))
                    should_update = current_threshold is None or (
                        improvement is not None and improvement > min_gain
                    )
                    if should_update:
                        history = metadata.get("threshold_history", [])
                        entry = build_threshold_history_entry(
                            result=threshold_search,
                            window_start=start_date,
                            window_end=end_date,
                            previous_threshold=current_threshold,
                            previous_balanced_accuracy=previous_bal,
                        )
                        history.append(entry)
                        updates = {
                            "decision_threshold": threshold_search.threshold,
                            "threshold_history": history,
                        }
                        try:
                            update_metadata(model_version, updates)
                            dynamic_updates[horizon] = {
                                "model_id": model_version,
                                "threshold": threshold_search.threshold,
                                "balanced_accuracy": threshold_search.balanced_accuracy,
                                "precision": threshold_search.precision,
                                "recall": threshold_search.recall,
                                "previous_threshold": current_threshold,
                                "previous_balanced_accuracy": previous_bal,
                                "improvement": improvement,
                            }
                            results[horizon]["classification"]["dynamic_threshold"] = dynamic_updates[horizon]
                        except Exception:
                            pass


    if not results:
        return None

    output_dir.mkdir(parents=True, exist_ok=True)
    summary_path = output_dir / f"evaluation_{start_date:%Y%m%d}_{end_date:%Y%m%d}.json"
    with summary_path.open("w", encoding="utf-8") as fp:
        json.dump(
            {
                "start_date": start_date.isoformat(),
                "end_date": end_date.isoformat(),
                "horizons": horizons,
                "prob_threshold": probability_threshold,
                "bias_threshold": bias_threshold,
                "metrics": results,
                "dynamic_threshold_updates": dynamic_updates,
            },
            fp,
            indent=2,
            ensure_ascii=False,
            default=str,
        )

    detail_path = output_dir / f"evaluation_details_{start_date:%Y%m%d}_{end_date:%Y%m%d}.json"
    with detail_path.open("w", encoding="utf-8") as fp:
        json.dump(detailed_rows, fp, indent=2, ensure_ascii=False, default=str)

    return summary_path


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="로컬 예측 평가 스크립트")
    parser.add_argument("--start-date", required=True, type=str)
    parser.add_argument("--end-date", required=True, type=str)
    parser.add_argument(
        "--horizons",
        type=str,
        default="5,20",
        help="평가할 horizon 목록 (콤마 구분)",
    )
    parser.add_argument(
        "--prob-threshold",
        type=float,
        default=-1.0,
        help="분류 확률 임계값(음수 입력 시 모델별 자동 임계값 사용)",
    )
    parser.add_argument("--bias-threshold", type=float, default=0.02)
    parser.add_argument(
        "--output-dir",
        type=str,
        default="prediction_system/output_sample/eval",
    )
    return parser.parse_args()


def main() -> None:
    args = _parse_args()
    start_date = dt.date.fromisoformat(args.start_date)
    end_date = dt.date.fromisoformat(args.end_date)
    horizons = [int(x.strip()) for x in args.horizons.split(",") if x.strip()]

    run(
        start_date=start_date,
        end_date=end_date,
        horizons=horizons,
        probability_threshold=args.prob_threshold if args.prob_threshold >= 0 else None,
        bias_threshold=args.bias_threshold,
        output_dir=Path(args.output_dir),
    )


if __name__ == "__main__":
    main()
