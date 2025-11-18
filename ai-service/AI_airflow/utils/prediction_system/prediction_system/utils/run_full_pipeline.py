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
    target_date: dt.date,
    train_start: dt.date,
    train_end: dt.date,
    lookback_days: int,
    persist_predictions: bool,
    eval_start: dt.date | None,
    eval_end: dt.date | None,
    horizons: List[int],
    probability_threshold: float,
    bias_threshold: float,
    output_dir: Path,
) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)

    feature_meta = build_features_run(date=target_date, lookback_days=lookback_days)
    with (output_dir / f"metadata_{target_date:%Y%m%d}.json").open("w", encoding="utf-8") as fp:
        json.dump(feature_meta, fp, indent=2, ensure_ascii=False)

    train_results = train_models_run(
        train_start=train_start,
        train_end=train_end,
        lookback_days=lookback_days,
    )
    with (output_dir / f"train_{train_start:%Y%m%d}_{train_end:%Y%m%d}.json").open("w", encoding="utf-8") as fp:
        json.dump(train_results or {}, fp, indent=2, ensure_ascii=False)

    predictions = daily_predict_run(
        target_date=target_date,
        lookback_days=lookback_days,
        persist=persist_predictions,
    )
    with (output_dir / f"predictions_{target_date:%Y%m%d}.json").open("w", encoding="utf-8") as fp:
        json.dump(predictions or [], fp, indent=2, ensure_ascii=False)

    if eval_start and eval_end:
        classification_thresholds: dict[int, float] = {}
        if train_results:
            for task_name, info in train_results.items():
                meta = (info or {}).get("metadata", {})
                horizon = meta.get("horizon")
                decision_threshold = meta.get("decision_threshold")
                task_type = meta.get("task_type") or ("classification" if "classification" in task_name else None)
                if (
                    task_type == "classification"
                    and horizon is not None
                    and decision_threshold is not None
                ):
                    classification_thresholds[int(horizon)] = float(decision_threshold)

        evaluate_run(
            start_date=eval_start,
            end_date=eval_end,
            horizons=horizons,
            probability_threshold=probability_threshold,
            bias_threshold=bias_threshold,
            output_dir=output_dir / "eval",
            model_thresholds=classification_thresholds or None,
        )


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="서버용 전체 파이프라인 실행기")
    parser.add_argument("--target-date", required=True, type=str)
    parser.add_argument("--train-start", required=True, type=str)
    parser.add_argument("--train-end", required=True, type=str)
    parser.add_argument("--lookback-days", type=int, default=260)
    parser.add_argument("--no-persist", action="store_true")
    parser.add_argument("--eval-start", type=str, default=None)
    parser.add_argument("--eval-end", type=str, default=None)
    parser.add_argument("--horizons", type=str, default="5,20")
    parser.add_argument("--prob-threshold", type=float, default=0.5)
    parser.add_argument("--bias-threshold", type=float, default=0.02)
    parser.add_argument(
        "--output-dir",
        type=str,
        default="prediction_system/artifacts/server_pipeline",
    )
    return parser.parse_args()


def main() -> None:
    args = _parse_args()
    eval_start = dt.date.fromisoformat(args.eval_start) if args.eval_start else None
    eval_end = dt.date.fromisoformat(args.eval_end) if args.eval_end else None

    run_pipeline(
        target_date=dt.date.fromisoformat(args.target_date),
        train_start=dt.date.fromisoformat(args.train_start),
        train_end=dt.date.fromisoformat(args.train_end),
        lookback_days=args.lookback_days,
        persist_predictions=not args.no_persist,
        eval_start=eval_start,
        eval_end=eval_end,
        horizons=[int(h.strip()) for h in args.horizons.split(",") if h.strip()],
        probability_threshold=args.prob_threshold,
        bias_threshold=args.bias_threshold,
        output_dir=Path(args.output_dir),
    )


if __name__ == "__main__":
    main()
