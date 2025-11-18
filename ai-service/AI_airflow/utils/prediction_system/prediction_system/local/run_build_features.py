from __future__ import annotations

import argparse
import datetime as dt
from pathlib import Path

from .build_features_pipeline_save_json import run


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="로컬용 Feature build JSON 실행기")
    parser.add_argument("--target-date", type=str, default=None, help="YYYY-MM-DD 포맷")
    parser.add_argument("--lookback-days", type=int, default=260)
    parser.add_argument(
        "--output-dir",
        type=str,
        default="prediction_system/output_sample/features",
        help="JSON 저장 경로",
    )
    return parser.parse_args()


def main() -> None:
    args = _parse_args()
    target_date = dt.date.fromisoformat(args.target_date) if args.target_date else None
    run(
        target_date=target_date,
        lookback_days=args.lookback_days,
        output_dir=Path(args.output_dir),
    )


if __name__ == "__main__":
    main()
