from __future__ import annotations

import argparse
import datetime as dt
from pathlib import Path

from prediction_system.utils.train_models_pipeline import run as train_run
from prediction_system.utils.json_io import write_json
from prediction_system.utils.logger import get_logger

logger = get_logger(__name__)


def run(
    *,
    train_start: dt.date,
    train_end: dt.date,
    lookback_days: int = 260,
    output_dir: Path = Path("prediction_system/output_sample/train"),
) -> Path | None:
    logger.info(
        "(TEST) 모델 학습 JSON export: %s~%s (lookback=%d)",
        train_start,
        train_end,
        lookback_days,
    )
    results = train_run(train_start=train_start, train_end=train_end, lookback_days=lookback_days)
    if not results:
        logger.warning("학습 결과가 없어 JSON export를 건너뜁니다.")
        return None

    serializable = {
        task: {
            "model_id": info.get("model_id"),
            "metadata": info.get("metadata"),
        }
        for task, info in results.items()
    }
    output_dir.mkdir(parents=True, exist_ok=True)
    target_path = output_dir / f"train_{train_start:%Y%m%d}_{train_end:%Y%m%d}.json"
    write_json(serializable, target_path)
    logger.info("학습 결과 JSON 저장 완료: %s", target_path)
    return target_path


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Training pipeline JSON exporter")
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
