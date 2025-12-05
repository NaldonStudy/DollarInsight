from __future__ import annotations

import argparse
import datetime as dt
import json
from pathlib import Path
from typing import Any, Dict

from prediction_system.utils.train_models_pipeline import run as train_models_run


def run_training(
    *,
    train_start: dt.date,
    train_end: dt.date,
    lookback_days: int,
    output_path: Path | None = None,
) -> Dict[str, Dict[str, Any]] | None:
    results = train_models_run(
        train_start=train_start,
        train_end=train_end,
        lookback_days=lookback_days,
    )
    if output_path:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        with output_path.open("w", encoding="utf-8") as fp:
            json.dump(results or {}, fp, indent=2, ensure_ascii=False, default=str)
    return results


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="모델 학습 전용 실행기")
    parser.add_argument("--train-start", required=True, type=str, help="학습 시작일 (YYYY-MM-DD)")
    parser.add_argument("--train-end", required=True, type=str, help="학습 종료일 (YYYY-MM-DD)")
    parser.add_argument(
        "--lookback-days",
        type=int,
        default=260,
        help="피처 구축 시 사용할 최소 과거 일수",
    )
    parser.add_argument(
        "--output-path",
        type=str,
        help="학습 결과를 저장할 JSON 경로 (생략 시 저장하지 않음)",
    )
    return parser.parse_args()


def main() -> None:
    args = _parse_args()
    train_start = dt.date.fromisoformat(args.train_start)
    train_end = dt.date.fromisoformat(args.train_end)
    output_path = Path(args.output_path) if args.output_path else None

    run_training(
        train_start=train_start,
        train_end=train_end,
        lookback_days=args.lookback_days,
        output_path=output_path,
    )


if __name__ == "__main__":
    main()


