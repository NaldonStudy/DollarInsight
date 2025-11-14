"""XGBoost 회귀 모델 래퍼 스텁."""

from __future__ import annotations

from typing import Any

import numpy as np

try:  # pragma: no cover - optional dependency
    import xgboost as xgb
except ImportError:  # pragma: no cover
    xgb = None

from sklearn.ensemble import GradientBoostingRegressor


class XGBRegressorWrapper:
    """5일/20일 수익률 예측용 회귀 모델."""

    def __init__(self, params: dict | None = None):
        default_params: dict[str, Any] = {
            "n_estimators": 300,
            "max_depth": 4,
            "learning_rate": 0.05,
            "subsample": 0.8,
            "colsample_bytree": 0.8,
            "reg_lambda": 1.0,
            "objective": "reg:squarederror",
            "n_jobs": -1,
            "verbosity": 0,
        }
        self.params = {**default_params, **(params or {})}
        self.model: Any | None = None

    def fit(self, X, y) -> None:
        """모델 학습."""

        X_arr = np.asarray(X)
        y_arr = np.asarray(y)
        if xgb is not None:
            model = xgb.XGBRegressor(**self.params)
        else:  # pragma: no cover
            gb_params = {
                key: self.params[key]
                for key in ["n_estimators", "max_depth", "learning_rate"]
                if key in self.params
            }
            model = GradientBoostingRegressor(**gb_params)
        model.fit(X_arr, y_arr)
        self.model = model

    def predict(self, X):
        """예측값 반환."""

        if self.model is None:
            raise RuntimeError("Model has not been fitted yet.")
        X_arr = np.asarray(X)
        return self.model.predict(X_arr)


