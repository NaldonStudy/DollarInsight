"""Conformal prediction 스텁."""

from __future__ import annotations

import os
from pathlib import Path

import numpy as np

from .model_registry import _REGISTRY_DIR  # reuse registry directory

_RESIDUAL_DIR = _REGISTRY_DIR / "residuals"


def compute_conformal_intervals(
    preds: np.ndarray,
    residuals: np.ndarray,
    quantile: float,
) -> tuple[np.ndarray, np.ndarray]:
    """예측값과 잔차를 이용해 하한/상한 구간을 계산한다."""

    if residuals.size == 0:
        return preds, preds
    radius = np.quantile(np.abs(residuals), quantile)
    lower = preds - radius
    upper = preds + radius
    return lower, upper


def update_residual_store(residuals: np.ndarray, model_id: str) -> None:
    """모델별 잔차 기록을 갱신한다."""

    _RESIDUAL_DIR.mkdir(parents=True, exist_ok=True)
    target_path = _RESIDUAL_DIR / f"{model_id}_residuals.npy"
    np.save(target_path, residuals.astype(float))


def load_residuals(model_id: str) -> np.ndarray:
    """저장된 잔차를 로드한다."""

    target_path = _RESIDUAL_DIR / f"{model_id}_residuals.npy"
    if not target_path.exists():
        return np.array([])
    return np.load(target_path)


