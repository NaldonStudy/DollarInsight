"""XGBoost 분류 모델 래퍼 스텁."""

from __future__ import annotations

from typing import Any

import numpy as np

try:  # pragma: no cover - optional dependency
    import xgboost as xgb
except ImportError:  # pragma: no cover
    xgb = None

from sklearn.ensemble import GradientBoostingClassifier


class XGBClassifierWrapper:
    """상승 확률 예측용 분류 모델."""

    def __init__(self, params: dict | None = None):
        default_params: dict[str, Any] = {
            "n_estimators": 300,
            "max_depth": 4,
            "learning_rate": 0.05,
            "subsample": 0.8,
            "colsample_bytree": 0.8,
            "objective": "binary:logistic",
            "eval_metric": "logloss",
            "n_jobs": -1,
            "verbosity": 0,
        }
        self.params = {**default_params, **(params or {})}
        self.model: Any | None = None

    def fit(self, X, y) -> None:
        X_arr = np.asarray(X)
        y_arr = np.asarray(y)
        if xgb is not None:
            model = xgb.XGBClassifier(**self.params)
        else:  # pragma: no cover
            gb_params = {
                key: self.params[key]
                for key in ["n_estimators", "learning_rate", "max_depth"]
                if key in self.params
            }
            model = GradientBoostingClassifier(**gb_params)
        model.fit(X_arr, y_arr)
        self.model = model

    def predict_proba(self, X):
        if self.model is None:
            raise RuntimeError("Model has not been fitted yet.")
        X_arr = np.asarray(X)
        return self.model.predict_proba(X_arr)

    def predict(self, X):
        if self.model is None:
            raise RuntimeError("Model has not been fitted yet.")
        X_arr = np.asarray(X)
        return self.model.predict(X_arr)


