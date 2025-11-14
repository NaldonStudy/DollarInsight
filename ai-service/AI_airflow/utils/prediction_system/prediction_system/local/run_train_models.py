from __future__ import annotations

import argparse
import datetime as dt
from pathlib import Path

from .train_models_pipeline_save_json import run


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="로컬용 모델 학습 JSON 실행기")
    parser.add_argument("--train-start", required=True, type=str, help="YYYY-MM-DD")
    parser.add_argument("--train-end", required=True, type=str, help="YYYY-MM-DD")
    parser.add_argument("--lookback-days", type=int, default=260)
    parser.add_argument(
        "--output-dir",
        type=str,
        default="prediction_system/output_sample/train",
    )
    return parser.parse_args()


def main() -> None:
    args = _parse_args()
    train_start = dt.date.fromisoformat(args.train_start)
    train_end = dt.date.fromisoformat(args.train_end)
    run(
        train_start=train_start,
        train_end=train_end,
        lookback_days=args.lookback_days,
        output_dir=Path(args.output_dir),
    )


if __name__ == "__main__":
    main()
