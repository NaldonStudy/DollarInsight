from __future__ import annotations

import argparse
import datetime as dt
import json
from pathlib import Path
from typing import Any, Dict, List

from prediction_system.utils.daily_predict_pipeline import run as daily_predict_run


def run_predictions(
    *,
    target_date: dt.date,
    lookback_days: int,
    persist: bool,
    output_path: Path | None = None,
) -> List[Dict[str, Any]] | None:
    predictions = daily_predict_run(
        target_date=target_date,
        lookback_days=lookback_days,
        persist=persist,
    )
    if output_path:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        with output_path.open("w", encoding="utf-8") as fp:
            json.dump(predictions or [], fp, indent=2, ensure_ascii=False, default=str)
    return predictions


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="일별 예측 전용 실행기")
    parser.add_argument("--predict-date", required=True, type=str, help="예측 기준일 (YYYY-MM-DD)")
    parser.add_argument(
        "--lookback-days",
        type=int,
        default=260,
        help="예측 시 사용할 최소 과거 일수",
    )
    persist_group = parser.add_mutually_exclusive_group()
    persist_group.add_argument(
        "--persist",
        dest="persist",
        action="store_true",
        help="예측 결과를 DB에 저장 (기본값)",
    )
    persist_group.add_argument(
        "--no-persist",
        dest="persist",
        action="store_false",
        help="DB 저장 없이 결과만 반환",
    )
    parser.set_defaults(persist=True)
    parser.add_argument(
        "--output-path",
        type=str,
        help="예측 결과를 저장할 JSON 경로 (생략 시 저장하지 않음)",
    )
    return parser.parse_args()


def main() -> None:
    args = _parse_args()
    predict_date = dt.date.fromisoformat(args.predict_date)
    output_path = Path(args.output_path) if args.output_path else None

    run_predictions(
        target_date=predict_date,
        lookback_days=args.lookback_days,
        persist=args.persist,
        output_path=output_path,
    )


if __name__ == "__main__":
    main()


