"""모델 학습 파이프라인 스텁."""

from __future__ import annotations

import datetime as dt
import os
from typing import Any, Dict

import numpy as np
from sklearn.calibration import CalibratedClassifierCV
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import balanced_accuracy_score, f1_score

from .model_registry import register_model
from .xgb_classifier import XGBClassifierWrapper
from .xgb_regressor import XGBRegressorWrapper
from .conformal import update_residual_store


def train_models(datasets: dict, config: dict) -> dict[str, dict]:
    """회귀/분류 모델을 학습하고 결과 메타데이터를 반환한다."""

    task_configs: dict[str, Any] = config.get("tasks", {})
    trained: dict[str, dict] = {}
    trained_at = dt.datetime.utcnow().isoformat()

    trained_context: dict[str, dict[str, Any]] = {}

    for task_name, payload in datasets.items():
        X_train = payload.get("X_train", payload.get("X"))
        y_train = payload.get("y_train", payload.get("y"))
        X_cal = payload.get("X_cal")
        y_cal = payload.get("y_cal")

        if X_train is None or X_train.size == 0:
            continue

        task_cfg = task_configs.get(task_name, {})
        task_type = task_cfg.get("type", "regression" if "regression" in task_name else "classification")
        params: Dict[str, Any] = task_cfg.get("params") or {}
        tuning_meta = task_cfg.get("tuning_summary") or {}
        horizon = task_cfg.get("horizon")

        walk_folds = payload.get("walk_folds") or []
        walk_meta = None
        if walk_folds:
            try:
                first_valid = walk_folds[0][1]
                walk_meta = {
                    "folds": len(walk_folds),
                    "valid_length": int(first_valid.size),
                }
            except Exception:  # pragma: no cover - defensive
                walk_meta = {"folds": len(walk_folds)}

        if task_type == "regression":
            model = XGBRegressorWrapper(params)
            model.fit(X_train, y_train)
            preds = model.predict(X_train)
            residuals = np.asarray(y_train, dtype=float) - np.asarray(preds, dtype=float)
            metadata = {
                "task_name": task_name,
                "task_type": task_type,
                "trained_at": trained_at,
                "feature_names": payload.get("feature_names"),
                "train_size": int(y_train.shape[0]),
                "quantile": task_cfg.get("quantile", 0.9),
                "hyperparameters": params,
                "tuning": tuning_meta,
                "horizon": horizon,
            }
            if walk_meta:
                metadata["walk_forward"] = walk_meta
            model_id = register_model(model, metadata)
            metadata_with_id = {**metadata, "model_id": model_id}
            update_residual_store(residuals, model_id)
            trained[task_name] = {
                "model_id": model_id,
                "metadata": metadata_with_id,
            }
            trained_context[task_name] = {
                "model": model,
                "X_cal": X_cal,
            }
        else:
            model = XGBClassifierWrapper(params)
            model.fit(X_train, y_train)

            calibrated = False
            best_threshold = None
            best_f1 = None
            best_bal_acc = None
            prob_calibrated: np.ndarray | None = None
            calibration_method = os.getenv("PRED_CALIBRATION_METHOD", "sigmoid").lower()
            if calibration_method not in {"sigmoid", "isotonic"}:
                calibration_method = "sigmoid"
            min_precision = os.getenv("PRED_THRESHOLD_MIN_PRECISION")
            if horizon is not None:
                horizon_env = os.getenv(f"PRED_THRESHOLD_MIN_PRECISION_{int(horizon)}D")
                if horizon_env is not None:
                    min_precision = horizon_env
            try:
                min_precision_value = float(min_precision) if min_precision is not None else 0.5
            except ValueError:
                min_precision_value = 0.5

            if (
                X_cal is not None
                and y_cal is not None
                and isinstance(X_cal, np.ndarray)
                and len(X_cal) > 100
                and len(np.unique(y_cal)) == 2
            ):
                try:
                    calibrator = CalibratedClassifierCV(model.model, method=calibration_method, cv="prefit")
                    calibrator.fit(X_cal, y_cal)
                    model.model = calibrator
                    prob_calibrated = calibrator.predict_proba(X_cal)[:, 1]
                    thresholds = np.linspace(0.35, 0.8, 46)
                    best_threshold = 0.5
                    best_bal_acc = 0.0
                    best_f1 = 0.0
                    for th in thresholds:
                        preds_bin = (prob_calibrated >= th).astype(int)
                        tp = ((preds_bin == 1) & (y_cal == 1)).sum()
                        fp = ((preds_bin == 1) & (y_cal == 0)).sum()
                        fn = ((preds_bin == 0) & (y_cal == 1)).sum()
                        precision_val = tp / (tp + fp) if (tp + fp) else 0.0
                        if precision_val < min_precision_value:
                            continue
                        bal_acc = balanced_accuracy_score(y_cal, preds_bin)
                        f1_val = f1_score(y_cal, preds_bin, zero_division=0)
                        if bal_acc > best_bal_acc:
                            best_bal_acc = bal_acc
                            best_threshold = float(th)
                            best_f1 = f1_val
                    calibrated = True
                except Exception:  # pragma: no cover
                    best_threshold = None
                    best_bal_acc = None
                    best_f1 = None
                    calibrated = False
                    prob_calibrated = None

            meta_info: dict[str, Any] | None = None
            meta_probs: np.ndarray | None = None
            if (
                prob_calibrated is not None
                and X_cal is not None
                and y_cal is not None
                and len(np.unique(y_cal)) >= 2
            ):
                reg_task_name = f"regression_{horizon}d" if horizon is not None else None
                reg_ctx = trained_context.get(reg_task_name) if reg_task_name else None
                if reg_ctx and reg_ctx.get("model") is not None:
                    try:
                        reg_model = reg_ctx["model"]
                        reg_preds_cal = reg_model.predict(X_cal)
                        feature_matrix = np.column_stack(
                            [prob_calibrated, reg_preds_cal, np.abs(reg_preds_cal)]
                        )
                        meta_clf = LogisticRegression(max_iter=300, class_weight="balanced")
                        meta_clf.fit(feature_matrix, y_cal)
                        meta_probs = meta_clf.predict_proba(feature_matrix)[:, 1]
                        meta_info = {
                            "coefficients": meta_clf.coef_[0].tolist(),
                            "intercept": float(meta_clf.intercept_[0]),
                            "feature_order": ["base_prob", "reg_point", "reg_abs"],
                            "trained_samples": int(len(y_cal)),
                        }
                    except Exception:  # pragma: no cover - meta fallback
                        meta_info = None
                        meta_probs = None

            prob_for_threshold = meta_probs if meta_probs is not None else prob_calibrated
            if prob_for_threshold is not None and y_cal is not None:
                thresholds = np.linspace(0.35, 0.8, 46)
                current_best_threshold = best_threshold or 0.5
                best_bal_metric = -np.inf
                best_meta_f1 = 0.0
                for th in thresholds:
                    preds_bin = (prob_for_threshold >= th).astype(int)
                    tp = ((preds_bin == 1) & (y_cal == 1)).sum()
                    fp = ((preds_bin == 1) & (y_cal == 0)).sum()
                    fn = ((preds_bin == 0) & (y_cal == 1)).sum()
                    precision_val = tp / (tp + fp) if (tp + fp) else 0.0
                    if precision_val < min_precision_value:
                        continue
                    bal_acc = balanced_accuracy_score(y_cal, preds_bin)
                    f1_val = f1_score(y_cal, preds_bin, zero_division=0)
                    if bal_acc > best_bal_metric:
                        best_bal_metric = bal_acc
                        current_best_threshold = float(th)
                        best_meta_f1 = f1_val
                best_threshold = current_best_threshold
                best_bal_acc = best_bal_metric if best_bal_metric != -np.inf else best_bal_acc
                best_f1 = best_meta_f1

            metadata = {
                "task_name": task_name,
                "task_type": task_type,
                "trained_at": trained_at,
                "feature_names": payload.get("feature_names"),
                "train_size": int(y_train.shape[0]),
                "hyperparameters": params,
                "tuning": tuning_meta,
                "horizon": horizon,
            }
            if walk_meta:
                metadata["walk_forward"] = walk_meta
            if calibrated:
                metadata["calibration"] = {
                    "method": "isotonic",
                    "samples": int(len(X_cal)),
                    "best_balanced_accuracy": best_bal_acc,
                    "best_f1": best_f1,
                }
            if best_threshold is not None:
                metadata["decision_threshold"] = best_threshold
            if meta_info:
                metadata["meta_ensemble"] = meta_info
            model_id = register_model(model, metadata)
            metadata_with_id = {**metadata, "model_id": model_id}
            trained[task_name] = {
                "model_id": model_id,
                "metadata": metadata_with_id,
            }
    return trained


