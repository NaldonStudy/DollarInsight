from __future__ import annotations

import math
import os
from dataclasses import dataclass
from typing import Any, Dict, Tuple

import numpy as np

try:  # pragma: no cover - optional dependency
    import optuna  # type: ignore
except ImportError:  # pragma: no cover
    optuna = None  # type: ignore

try:  # pragma: no cover - optional dependency
    import xgboost as xgb  # type: ignore
except ImportError:  # pragma: no cover
    xgb = None  # type: ignore


@dataclass(slots=True)
class TuningResult:
    params: Dict[str, Any]
    best_score: float
    direction: str
    trials: int


_DEFAULT_COMMON_PARAMS: Dict[str, Any] = {
    "n_jobs": int(os.getenv("XGB_N_JOBS", "-1")),
    "verbosity": 0,
    "tree_method": os.getenv("XGB_TREE_METHOD", "hist"),
}


def _prepare_data(
    X: np.ndarray,
    y: np.ndarray,
    *,
    validation_ratio: float = 0.2,
    max_samples: int | None = 120_000,
) -> Tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    """시계열 특성을 고려해 최근 데이터를 검증용으로 분할한다."""

    if max_samples is not None and len(X) > max_samples:
        X = X[-max_samples:]
        y = y[-max_samples:]

    split_idx = int(len(X) * (1 - validation_ratio))
    split_idx = max(1, min(len(X) - 1, split_idx))
    X_train, X_valid = X[:split_idx], X[split_idx:]
    y_train, y_valid = y[:split_idx], y[split_idx:]
    return X_train, X_valid, y_train, y_valid


def _suggest_regression_params(trial: optuna.Trial) -> Dict[str, Any]:
    return {
        "max_depth": trial.suggest_int("max_depth", 3, 8),
        "learning_rate": trial.suggest_float("learning_rate", 0.01, 0.2, log=True),
        "n_estimators": trial.suggest_int("n_estimators", 200, 600),
        "subsample": trial.suggest_float("subsample", 0.6, 1.0),
        "colsample_bytree": trial.suggest_float("colsample_bytree", 0.6, 1.0),
        "reg_lambda": trial.suggest_float("reg_lambda", 0.1, 10.0, log=True),
        "reg_alpha": trial.suggest_float("reg_alpha", 0.0, 2.0),
        "min_child_weight": trial.suggest_float("min_child_weight", 1.0, 10.0),
        "gamma": trial.suggest_float("gamma", 0.0, 2.0),
    }


def _suggest_classification_params(trial: optuna.Trial) -> Dict[str, Any]:
    return {
        "max_depth": trial.suggest_int("max_depth", 3, 8),
        "learning_rate": trial.suggest_float("learning_rate", 0.01, 0.2, log=True),
        "n_estimators": trial.suggest_int("n_estimators", 200, 600),
        "subsample": trial.suggest_float("subsample", 0.6, 1.0),
        "colsample_bytree": trial.suggest_float("colsample_bytree", 0.6, 1.0),
        "reg_lambda": trial.suggest_float("reg_lambda", 0.1, 10.0, log=True),
        "reg_alpha": trial.suggest_float("reg_alpha", 0.0, 2.0),
        "min_child_weight": trial.suggest_float("min_child_weight", 1.0, 10.0),
        "gamma": trial.suggest_float("gamma", 0.0, 2.0),
        "scale_pos_weight": trial.suggest_float("scale_pos_weight", 0.8, 3.0),
        "max_delta_step": trial.suggest_float("max_delta_step", 0.0, 1.0),
    }


def tune_regression(
    X: np.ndarray,
    y: np.ndarray,
    *,
    n_trials: int = 25,
    random_state: int = 2024,
    folds: list[tuple[np.ndarray, np.ndarray]] | None = None,
) -> TuningResult:
    if optuna is None or xgb is None:
        raise RuntimeError("Optuna 또는 xgboost 패키지가 누락되어 회귀 튜닝을 수행할 수 없습니다.")
    use_folds = bool(folds)
    if use_folds:
        folds = [(
            np.asarray(train_idx, dtype=int),
            np.asarray(valid_idx, dtype=int),
        ) for train_idx, valid_idx in folds or [] if len(train_idx) > 0 and len(valid_idx) > 0]
        if not folds:
            use_folds = False

    if not use_folds:
        X_train, X_valid, y_train, y_valid = _prepare_data(X, y)

    def objective(trial: optuna.Trial) -> float:
        params = {
            **_DEFAULT_COMMON_PARAMS,
            "objective": "reg:squarederror",
            "eval_metric": "rmse",
            "random_state": random_state,
            **_suggest_regression_params(trial),
        }
        if use_folds and folds:
            scores = []
            for train_idx, valid_idx in folds:
                X_tr, y_tr = X[train_idx], y[train_idx]
                X_val, y_val = X[valid_idx], y[valid_idx]
                if X_tr.size == 0 or X_val.size == 0:
                    continue
                model = xgb.XGBRegressor(**params)
                model.fit(X_tr, y_tr, eval_set=[(X_val, y_val)], verbose=False)
                preds = model.predict(X_val)
                rmse = math.sqrt(((preds - y_val) ** 2).mean())
                scores.append(rmse)
            if not scores:
                return float("inf")
            return float(np.mean(scores))

        model = xgb.XGBRegressor(**params)
        model.fit(X_train, y_train, eval_set=[(X_valid, y_valid)], verbose=False)
        preds = model.predict(X_valid)
        rmse = math.sqrt(((preds - y_valid) ** 2).mean())
        return rmse

    study = optuna.create_study(direction="minimize", sampler=optuna.samplers.TPESampler(seed=random_state))
    study.optimize(objective, n_trials=n_trials, show_progress_bar=False)

    best_params = {
        **_DEFAULT_COMMON_PARAMS,
        "objective": "reg:squarederror",
        "eval_metric": "rmse",
        "random_state": random_state,
        **study.best_params,
    }
    return TuningResult(best_params, study.best_value, study.direction, len(study.trials))


def tune_classification(
    X: np.ndarray,
    y: np.ndarray,
    *,
    n_trials: int = 25,
    random_state: int = 2024,
    folds: list[tuple[np.ndarray, np.ndarray]] | None = None,
) -> TuningResult:
    if optuna is None or xgb is None:
        raise RuntimeError("Optuna 또는 xgboost 패키지가 누락되어 분류 튜닝을 수행할 수 없습니다.")
    use_folds = bool(folds)
    if use_folds:
        folds = [(
            np.asarray(train_idx, dtype=int),
            np.asarray(valid_idx, dtype=int),
        ) for train_idx, valid_idx in folds or [] if len(train_idx) > 0 and len(valid_idx) > 0]
        if not folds:
            use_folds = False

    if not use_folds:
        X_train, X_valid, y_train, y_valid = _prepare_data(X, y)

    # validation 데이터가 단일 클래스로 구성된 경우 대비
    if not use_folds and len(np.unique(y_valid)) < 2:
        unique = np.unique(y)
        if len(unique) < 2:
            raise ValueError("분류 튜닝에 필요한 클래스 다양성이 부족합니다.")
        # 검증 세트에 양쪽 클래스가 존재하도록 단순 분할 조정
        split_idx = int(len(X) * 0.8)
        split_idx = max(1, min(len(X) - 1, split_idx))
        X_train, X_valid = X[:split_idx], X[split_idx:]
        y_train, y_valid = y[:split_idx], y[split_idx:]

    def objective(trial: optuna.Trial) -> float:
        params = {
            **_DEFAULT_COMMON_PARAMS,
            "objective": "binary:logistic",
            "eval_metric": "logloss",
            "random_state": random_state,
            "use_label_encoder": False,
            **_suggest_classification_params(trial),
        }
        if use_folds and folds:
            scores = []
            for train_idx, valid_idx in folds:
                X_tr, y_tr = X[train_idx], y[train_idx]
                X_val, y_val = X[valid_idx], y[valid_idx]
                if X_tr.size == 0 or X_val.size == 0:
                    continue
                if len(np.unique(y_val)) < 2 or len(np.unique(y_tr)) < 2:
                    continue
                model = xgb.XGBClassifier(**params)
                model.fit(X_tr, y_tr, eval_set=[(X_val, y_val)], verbose=False)
                prob = model.predict_proba(X_val)[:, 1]
                try:
                    from sklearn.metrics import roc_auc_score

                    score = roc_auc_score(y_val, prob)
                except Exception:
                    from sklearn.metrics import balanced_accuracy_score

                    score = balanced_accuracy_score(y_val, (prob > 0.5).astype(int))
                scores.append(score)
            if not scores:
                return 0.0
            return float(np.mean(scores))

        model = xgb.XGBClassifier(**params)
        model.fit(X_train, y_train, eval_set=[(X_valid, y_valid)], verbose=False)
        prob = model.predict_proba(X_valid)[:, 1]
        # ROC AUC 최대화
        # fallback: balanced accuracy
        try:
            from sklearn.metrics import roc_auc_score  # lazy import

            score = roc_auc_score(y_valid, prob)
        except Exception:
            from sklearn.metrics import balanced_accuracy_score

            score = balanced_accuracy_score(y_valid, (prob > 0.5).astype(int))
        return score

    study = optuna.create_study(direction="maximize", sampler=optuna.samplers.TPESampler(seed=random_state))
    study.optimize(objective, n_trials=n_trials, show_progress_bar=False)

    best_params = {
        **_DEFAULT_COMMON_PARAMS,
        "objective": "binary:logistic",
        "eval_metric": "logloss",
        "random_state": random_state,
        "use_label_encoder": False,
        **study.best_params,
    }
    return TuningResult(best_params, study.best_value, study.direction, len(study.trials))


def tune_hyperparameters(
    *,
    task_name: str,
    task_type: str,
    X: np.ndarray,
    y: np.ndarray,
    n_trials: int = 25,
    random_state: int = 2024,
    folds: list[tuple[np.ndarray, np.ndarray]] | None = None,
) -> TuningResult:
    X = np.asarray(X, dtype=float)
    y = np.asarray(y)
    if task_type == "regression":
        return tune_regression(X, y, n_trials=n_trials, random_state=random_state, folds=folds)
    if task_type == "classification":
        return tune_classification(X, y, n_trials=n_trials, random_state=random_state, folds=folds)
    raise ValueError(f"지원하지 않는 task_type: {task_type}")
