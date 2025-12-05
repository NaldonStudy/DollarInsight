from __future__ import annotations

import argparse
import datetime as dt
from pathlib import Path

from prediction_system.utils.daily_predict_pipeline import run as predict_run
from prediction_system.utils.json_io import write_json
from prediction_system.utils.logger import get_logger

logger = get_logger(__name__)


def run(
    *,
    target_date: dt.date | None = None,
    lookback_days: int = 260,
    output_dir: Path = Path("prediction_system/output_sample/predict"),
) -> Path | None:
    logger.info(
        "(TEST) 일일 예측 JSON export: target=%s, lookback=%d",
        target_date,
        lookback_days,
    )
    predictions = predict_run(target_date=target_date, lookback_days=lookback_days, persist=False)
    if not predictions:
        logger.warning("예측 결과가 없어 JSON export를 건너뜁니다.")
        return None

    resolved_date = predictions[0]["prediction_date"]
    output_dir.mkdir(parents=True, exist_ok=True)
    target_path = output_dir / f"predictions_{resolved_date}.json"
    write_json(predictions, target_path)
    logger.info("예측 JSON 저장 완료: %s (records=%d)", target_path, len(predictions))
    return target_path


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Daily prediction JSON exporter")
    parser.add_argument("--target-date", type=str, help="YYYY-MM-DD", default=None)
    parser.add_argument("--lookback-days", type=int, default=260)
    parser.add_argument(
        "--output-dir",
        type=str,
        default="prediction_system/output_sample/predict",
    )
    return parser.parse_args()


def main() -> None:
    args = _parse_args()
    target_date = (
        dt.date.fromisoformat(args.target_date)
        if args.target_date
        else None
    )
    run(
        target_date=target_date,
        lookback_days=args.lookback_days,
        output_dir=Path(args.output_dir),
    )


if __name__ == "__main__":
    main()
