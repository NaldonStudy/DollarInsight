from __future__ import annotations

import os
from dataclasses import dataclass, field
from typing import List, Sequence

import numpy as np
import pandas as pd
import shap  # type: ignore
import xgboost as xgb  # type: ignore

from .logger import get_logger


logger = get_logger(__name__)


@dataclass
class FeatureSelectionResult:
    selected: List[str]
    removed_by_variance: List[str] = field(default_factory=list)
    removed_by_correlation: List[str] = field(default_factory=list)
    removed_by_shap: List[str] = field(default_factory=list)
    shap_importance: dict[str, float] = field(default_factory=dict)


def _prepare_feature_matrix(
    feature_df: pd.DataFrame,
    feature_columns: Sequence[str],
    target_column: str,
) -> tuple[pd.DataFrame, np.ndarray]:
    df = feature_df.reset_index().copy()
    df.sort_values(["feature_date", "ticker"], inplace=True)
    df = df.dropna(subset=[target_column])

    matrix = df[list(feature_columns)].apply(pd.to_numeric, errors="coerce")
    matrix = matrix.dropna()
    df = df.loc[matrix.index]

    target = pd.to_numeric(df[target_column], errors="coerce").to_numpy(dtype=float)
    return matrix, target


def _variance_filter(matrix: pd.DataFrame, columns: List[str], threshold: float) -> tuple[List[str], List[str]]:
    variances = matrix.var(axis=0, ddof=0)
    keep_mask = variances > threshold
    kept = [col for col, keep in zip(columns, keep_mask) if keep]
    removed = [col for col, keep in zip(columns, keep_mask) if not keep]
    return kept, removed


def _correlation_filter(matrix: pd.DataFrame, columns: List[str], threshold: float) -> tuple[List[str], List[str]]:
    if len(columns) < 2:
        return columns, []
    corr_matrix = matrix[columns].corr().abs()
    upper = corr_matrix.where(np.triu(np.ones(corr_matrix.shape), k=1).astype(bool))
    to_drop: set[str] = set()
    for col in upper.columns:
        high_corr = upper[col][upper[col] > threshold]
        if not high_corr.empty:
            to_drop.add(col)
    kept = [col for col in columns if col not in to_drop]
    removed = [col for col in columns if col in to_drop]
    return kept, removed


def _train_shadow_model(
    X: pd.DataFrame,
    y: np.ndarray,
    *,
    task_type: str,
    random_state: int,
) -> xgb.XGBModel:
    common_kwargs = {
        "max_depth": int(os.getenv("PRED_SHAP_MAX_DEPTH", "4")),
        "learning_rate": float(os.getenv("PRED_SHAP_LEARNING_RATE", "0.05")),
        "n_estimators": int(os.getenv("PRED_SHAP_N_ESTIMATORS", "200")),
        "subsample": float(os.getenv("PRED_SHAP_SUBSAMPLE", "0.8")),
        "colsample_bytree": float(os.getenv("PRED_SHAP_COLSAMPLE", "0.8")),
        "min_child_weight": float(os.getenv("PRED_SHAP_MIN_CHILD_WEIGHT", "3.0")),
        "random_state": random_state,
        "n_jobs": int(os.getenv("PRED_SHAP_N_JOBS", "0")),
    }
    if task_type == "classification":
        model = xgb.XGBClassifier(
            objective="binary:logistic",
            eval_metric="logloss",
            **common_kwargs,
        )
    else:
        model = xgb.XGBRegressor(
            objective="reg:squarederror",
            **common_kwargs,
        )
    model.fit(X, y)
    return model


def _compute_shap_importance(
    model: xgb.XGBModel,
    X: pd.DataFrame,
    *,
    task_type: str,
) -> pd.Series:
    explainer = shap.TreeExplainer(model)
    shap_values = explainer.shap_values(X)
    if isinstance(shap_values, list):
        # binary classification returns list of arrays
        shap_matrix = shap_values[1] if len(shap_values) > 1 else shap_values[0]
    else:
        shap_matrix = shap_values
    shap_matrix = np.asarray(shap_matrix, dtype=float)
    importance = np.mean(np.abs(shap_matrix), axis=0)
    return pd.Series(importance, index=X.columns).sort_values(ascending=False)


def select_feature_columns(
    feature_df: pd.DataFrame,
    *,
    target_column: str,
    base_feature_columns: Sequence[str],
    task_type: str,
) -> FeatureSelectionResult:
    variance_threshold = float(os.getenv("PRED_FS_VARIANCE_THRESHOLD", "1e-8"))
    corr_threshold = float(os.getenv("PRED_FS_CORR_THRESHOLD", "0.97"))
    shap_top_k_env = os.getenv("PRED_SHAP_TOP_K")
    shap_top_k = int(shap_top_k_env) if shap_top_k_env else None
    shap_min_importance = float(os.getenv("PRED_SHAP_MIN_IMPORTANCE", "0.0"))
    shap_sample_size = int(os.getenv("PRED_SHAP_SAMPLE_SIZE", "4000"))
    min_features = int(os.getenv("PRED_SHAP_MIN_FEATURES", "20"))
    random_state = int(os.getenv("PRED_SHAP_RANDOM_STATE", "2025"))

    base_columns = list(base_feature_columns)
    if not base_columns:
        return FeatureSelectionResult(selected=[])

    matrix, target = _prepare_feature_matrix(feature_df, base_columns, target_column)
    if matrix.empty or len(target) == 0:
        logger.warning("Feature selection skipped: insufficient data (matrix=%d, target=%d)", len(matrix), len(target))
        return FeatureSelectionResult(selected=list(base_columns))

    working_matrix = matrix.copy()
    columns = list(base_columns)

    columns, removed_var = _variance_filter(working_matrix, columns, variance_threshold)
    working_matrix = working_matrix[columns]

    columns, removed_corr = _correlation_filter(working_matrix, columns, corr_threshold)
    working_matrix = working_matrix[columns]

    if len(columns) <= min_features:
        logger.info(
            "Skipping SHAP pruning because feature count (%d) <= min_features (%d).",
            len(columns),
            min_features,
        )
        return FeatureSelectionResult(
            selected=columns,
            removed_by_variance=removed_var,
            removed_by_correlation=removed_corr,
        )

    sample_count = min(len(working_matrix), shap_sample_size)
    if sample_count < min_features:
        logger.info(
            "Skipping SHAP pruning because sample_count (%d) < min_features (%d).",
            sample_count,
            min_features,
        )
        return FeatureSelectionResult(
            selected=columns,
            removed_by_variance=removed_var,
            removed_by_correlation=removed_corr,
        )

    sampled_indices = np.random.RandomState(random_state).choice(
        len(working_matrix),
        size=sample_count,
        replace=False,
    )
    X_sampled = working_matrix.iloc[sampled_indices]
    y_sampled = target[sampled_indices]

    try:
        shadow_model = _train_shadow_model(
            X_sampled,
            y_sampled,
            task_type=task_type,
            random_state=random_state,
        )
        shap_importance = _compute_shap_importance(
            shadow_model,
            X_sampled,
            task_type=task_type,
        )
    except Exception as exc:  # pragma: no cover - defensive
        logger.warning("SHAP feature pruning 실패: %s", exc)
        return FeatureSelectionResult(
            selected=columns,
            removed_by_variance=removed_var,
            removed_by_correlation=removed_corr,
        )

    if shap_top_k is None:
        shap_top_k = max(min_features, int(len(columns) * 0.6))
    shap_top_k = max(min_features, min(len(columns), shap_top_k))

    ranked = shap_importance[shap_importance >= shap_min_importance]
    if ranked.empty:
        ranked = shap_importance
    top_features = ranked.index.tolist()[:shap_top_k]
    selected_set = set(top_features)
    selected_columns = [col for col in columns if col in selected_set]
    if len(selected_columns) < min_features:
        fallback = shap_importance.index.tolist()[:min_features]
        selected_set = set(fallback)
        selected_columns = [col for col in columns if col in selected_set]

    removed_shap = [col for col in columns if col not in selected_set]

    return FeatureSelectionResult(
        selected=selected_columns,
        removed_by_variance=removed_var,
        removed_by_correlation=removed_corr,
        removed_by_shap=removed_shap,
        shap_importance={col: float(val) for col, val in shap_importance.items()},
    )


__all__ = ["FeatureSelectionResult", "select_feature_columns"]

