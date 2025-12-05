from __future__ import annotations

import datetime as dt
from dataclasses import dataclass
from typing import Iterable, Optional

import numpy as np
from sklearn.metrics import balanced_accuracy_score, precision_score, recall_score


@dataclass
class ThresholdSearchResult:
    threshold: float
    balanced_accuracy: float
    precision: float
    recall: float
    samples: int


def search_balanced_accuracy_threshold(
    probabilities: Iterable[float],
    labels: Iterable[int],
    *,
    candidate_thresholds: Optional[Iterable[float]] = None,
    min_precision: Optional[float] = None,
) -> ThresholdSearchResult | None:
    probs = np.asarray(list(probabilities), dtype=float)
    y_true = np.asarray(list(labels), dtype=int)

    mask = np.isfinite(probs) & np.isfinite(y_true)
    probs = probs[mask]
    y_true = y_true[mask]

    if probs.size == 0 or y_true.size == 0:
        return None

    if candidate_thresholds is None:
        candidate_thresholds = np.linspace(0.25, 0.75, 51)

    best_threshold = 0.5
    best_bal = -np.inf
    best_precision = 0.0
    best_recall = 0.0

    for threshold in candidate_thresholds:
        preds = (probs >= threshold).astype(int)
        bal_acc = balanced_accuracy_score(y_true, preds)
        tp = ((preds == 1) & (y_true == 1)).sum()
        fp = ((preds == 1) & (y_true == 0)).sum()
        fn = ((preds == 0) & (y_true == 1)).sum()
        precision_val = tp / (tp + fp) if (tp + fp) else 0.0
        if min_precision is not None and precision_val < min_precision:
            continue
        if bal_acc >= best_bal:
            best_bal = bal_acc
            best_threshold = float(threshold)
            best_precision = float(precision_val)
            best_recall = recall_score(y_true, preds, zero_division=0)

    if best_bal == -np.inf:
        default_threshold = 0.5
        preds_default = (probs >= default_threshold).astype(int)
        best_threshold = default_threshold
        best_bal = balanced_accuracy_score(y_true, preds_default)
        best_precision = precision_score(y_true, preds_default, zero_division=0)
        best_recall = recall_score(y_true, preds_default, zero_division=0)

    return ThresholdSearchResult(
        threshold=best_threshold,
        balanced_accuracy=float(best_bal),
        precision=float(best_precision),
        recall=float(best_recall),
        samples=int(probs.size),
    )


def build_threshold_history_entry(
    *,
    result: ThresholdSearchResult,
    window_start: dt.date,
    window_end: dt.date,
    previous_threshold: Optional[float],
    previous_balanced_accuracy: Optional[float],
) -> dict:
    payload = {
        "computed_at": dt.datetime.utcnow().replace(microsecond=0).isoformat() + "Z",
        "threshold": result.threshold,
        "balanced_accuracy": result.balanced_accuracy,
        "precision": result.precision,
        "recall": result.recall,
        "samples": result.samples,
        "window_start": window_start.isoformat(),
        "window_end": window_end.isoformat(),
    }
    if previous_threshold is not None:
        payload["previous_threshold"] = previous_threshold
    if previous_balanced_accuracy is not None:
        payload["previous_balanced_accuracy"] = previous_balanced_accuracy
    return payload


__all__ = ["ThresholdSearchResult", "search_balanced_accuracy_threshold", "build_threshold_history_entry"]


