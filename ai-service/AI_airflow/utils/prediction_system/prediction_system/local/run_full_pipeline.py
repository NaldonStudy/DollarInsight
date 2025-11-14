from __future__ import annotations

import argparse
import datetime as dt
import json
from pathlib import Path
from typing import List

from prediction_system.utils.build_features_pipeline import run as build_features_run
from prediction_system.utils.train_models_pipeline import run as train_models_run
from prediction_system.utils.daily_predict_pipeline import run as daily_predict_run
from prediction_system.local.evaluate_predictions import run as evaluate_run


def run_pipeline(
    *,
    feature_target: dt.date,
    train_start: dt.date,
    train_end: dt.date,
    predict_date: dt.date,
    eval_start: dt.date,
    eval_end: dt.date,
    horizons: List[int],
    probability_threshold: float,
    bias_threshold: float,
    output_root: Path,
) -> None:
    feature_dir = output_root / "features"
    train_dir = output_root / "train"
    predict_dir = output_root / "predict"
    eval_dir = output_root / "eval"

    feature_dir.mkdir(parents=True, exist_ok=True)
    train_dir.mkdir(parents=True, exist_ok=True)
    predict_dir.mkdir(parents=True, exist_ok=True)
    eval_dir.mkdir(parents=True, exist_ok=True)

    feature_meta = build_features_run(date=feature_target)
    with (feature_dir / f"metadata_{feature_target:%Y%m%d}.json").open("w", encoding="utf-8") as fp:
        json.dump(feature_meta, fp, indent=2, ensure_ascii=False, default=str)

    train_results = train_models_run(
        train_start=train_start,
        train_end=train_end,
        lookback_days=260,
    )
    with (train_dir / f"train_{train_start:%Y%m%d}_{train_end:%Y%m%d}.json").open("w", encoding="utf-8") as fp:
        json.dump(train_results or {}, fp, indent=2, ensure_ascii=False, default=str)

    effective_threshold = None if probability_threshold < 0 else probability_threshold

    predictions = daily_predict_run(
        target_date=predict_date,
        lookback_days=260,
        persist=False,
    ) or []
    with (predict_dir / f"predictions_{predict_date:%Y%m%d}.json").open("w", encoding="utf-8") as fp:
        json.dump(predictions or [], fp, indent=2, ensure_ascii=False, default=str)

    classification_thresholds: dict[int, float] = {}
    if train_results:
        for task_name, info in train_results.items():
            meta = info.get("metadata", {})
            horizon = meta.get("horizon")
            decision_threshold = meta.get("decision_threshold")
            if (
                task_name.startswith("classification")
                and horizon is not None
                and decision_threshold is not None
            ):
                classification_thresholds[int(horizon)] = float(decision_threshold)

    evaluate_run(
        start_date=eval_start,
        end_date=eval_end,
        horizons=horizons,
        probability_threshold=effective_threshold,
        bias_threshold=bias_threshold,
        output_dir=eval_dir,
        model_thresholds=classification_thresholds or None,
    )


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="로컬 전체 파이프라인 실행기")
    parser.add_argument("--feature-target", required=True, type=str)
    parser.add_argument("--train-start", required=True, type=str)
    parser.add_argument("--train-end", required=True, type=str)
    parser.add_argument("--predict-date", required=True, type=str)
    parser.add_argument("--eval-start", required=True, type=str)
    parser.add_argument("--eval-end", required=True, type=str)
    parser.add_argument("--horizons", type=str, default="5,20")
    parser.add_argument(
        "--prob-threshold",
        type=float,
        default=-1.0,
        help="분류 확률 임계값(음수 입력 시 모델별 자동 임계값 사용)",
    )
    parser.add_argument("--bias-threshold", type=float, default=0.02)
    parser.add_argument(
        "--output-root",
        type=str,
        default="prediction_system/output_sample",
    )
    return parser.parse_args()


def main() -> None:
    args = _parse_args()
    run_pipeline(
        feature_target=dt.date.fromisoformat(args.feature_target),
        train_start=dt.date.fromisoformat(args.train_start),
        train_end=dt.date.fromisoformat(args.train_end),
        predict_date=dt.date.fromisoformat(args.predict_date),
        eval_start=dt.date.fromisoformat(args.eval_start),
        eval_end=dt.date.fromisoformat(args.eval_end),
        horizons=[int(h.strip()) for h in args.horizons.split(",") if h.strip()],
        probability_threshold=args.prob_threshold,
        bias_threshold=args.bias_threshold,
        output_root=Path(args.output_root),
    )


if __name__ == "__main__":
    main()
