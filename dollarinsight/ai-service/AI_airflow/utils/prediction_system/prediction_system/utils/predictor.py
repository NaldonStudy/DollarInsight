"""예측 생성 모듈 스텁."""

from __future__ import annotations

import numpy as np
import pandas as pd

from .conformal import compute_conformal_intervals, load_residuals
from .model_registry import load_model


def _apply_meta_ensemble(
    probabilities: np.ndarray,
    meta_cfg: dict | None,
    horizon: int | None,
    regression_cache: dict[int, dict[str, np.ndarray]],
) -> np.ndarray:
    if not meta_cfg or horizon is None:
        return probabilities

    coefficients = np.asarray(meta_cfg.get("coefficients", []), dtype=float)
    intercept = float(meta_cfg.get("intercept", 0.0))
    feature_order = meta_cfg.get("feature_order", [])

    if coefficients.size == 0 or len(feature_order) != coefficients.size:
        return probabilities

    reg_data = regression_cache.get(int(horizon))
    if reg_data is None:
        return probabilities
    reg_point = reg_data.get("point")
    if reg_point is None or len(reg_point) != len(probabilities):
        return probabilities

    design = np.zeros((len(probabilities), coefficients.size), dtype=float)
    for idx, base_prob in enumerate(probabilities):
        for j, feature_name in enumerate(feature_order):
            if feature_name == "base_prob":
                design[idx, j] = base_prob
            elif feature_name == "reg_point":
                design[idx, j] = reg_point[idx]
            elif feature_name == "reg_abs":
                design[idx, j] = abs(reg_point[idx])
            else:
                design[idx, j] = 0.0

    logits = intercept + design.dot(coefficients)
    adjusted = 1.0 / (1.0 + np.exp(-logits))
    return adjusted


def generate_daily_predictions(
    feature_df: pd.DataFrame,
    tasks: dict[str, dict],
) -> pd.DataFrame:
    """학습된 모델을 사용해 일별 예측을 생성한다."""

    if feature_df.empty:
        return pd.DataFrame()

    rows = []
    feature_matrix = feature_df.reset_index()
    available_columns = [col for col in feature_matrix.columns if col not in {"ticker", "feature_date"}]

    regression_cache: dict[int, dict[str, np.ndarray]] = {}

    for task_name, task_cfg in tasks.items():
        try:
            model, metadata = load_model(task_name=task_name)
        except (KeyError, FileNotFoundError) as e:
            # 모델이 없으면 해당 task를 건너뜀
            continue
        task_type = metadata.get("task_type", task_cfg.get("type"))
        horizon = task_cfg.get("horizon")

        feature_names = metadata.get("feature_names") or available_columns
        missing_cols = [col for col in feature_names if col not in feature_matrix.columns]
        if missing_cols:
            raise ValueError(f"모델 '{task_name}' 예측 실패: 누락된 feature {missing_cols}")

        X_df = feature_matrix[feature_names].apply(pd.to_numeric, errors="coerce")
        X = X_df.to_numpy()

        if task_type == "regression":
            preds = model.predict(X)
            residuals = load_residuals(metadata.get("model_id", metadata.get("task_name", task_name)))
            quantile = metadata.get("quantile", task_cfg.get("quantile", 0.9))
            lower, upper = compute_conformal_intervals(preds, residuals, quantile)
            if horizon is not None:
                regression_cache[int(horizon)] = {
                    "point": np.asarray(preds, dtype=float),
                }
            for (ticker, feature_date), pred, lo, up in zip(
                feature_df.index,
                preds,
                lower,
                upper,
            ):
                rows.append(
                    {
                        "prediction_date": feature_date.date() if hasattr(feature_date, "date") else feature_date,
                        "ticker": ticker,
                        "horizon_days": horizon,
                        "point_estimate": float(pred),
                        "lower_bound": float(lo),
                        "upper_bound": float(up),
                        "prob_up": None,
                        "model_version": metadata.get("model_id"),
                        "residual_quantile": quantile,
                        "feature_window_id": task_cfg.get("feature_window_id"),
                        "task_name": task_name,
                    }
                )
        else:
            probabilities = model.predict_proba(X)[:, 1]
            meta_cfg = metadata.get("meta_ensemble")
            if meta_cfg:
                probabilities = _apply_meta_ensemble(
                    probabilities,
                    meta_cfg,
                    horizon,
                    regression_cache,
                )
            for (ticker, feature_date), prob in zip(feature_df.index, probabilities):
                rows.append(
                    {
                        "prediction_date": feature_date.date() if hasattr(feature_date, "date") else feature_date,
                        "ticker": ticker,
                        "horizon_days": horizon,
                        "point_estimate": None,
                        "lower_bound": None,
                        "upper_bound": None,
                        "prob_up": float(prob),
                        "model_version": metadata.get("model_id"),
                        "decision_threshold": metadata.get("decision_threshold"),
                        "residual_quantile": None,
                        "feature_window_id": task_cfg.get("feature_window_id"),
                        "task_name": task_name,
                    }
                )
    return pd.DataFrame(rows)


