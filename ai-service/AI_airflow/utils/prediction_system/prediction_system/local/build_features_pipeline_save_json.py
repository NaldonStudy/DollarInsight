from __future__ import annotations

import argparse
import datetime as dt
from pathlib import Path

from pipelines.watchlists import METRIC_STOCKS

from prediction_system.utils.feature_store_builder import build_feature_store
from prediction_system.utils.json_io import write_json
from prediction_system.utils.logger import get_logger

logger = get_logger(__name__)


def run(
    *,
    target_date: dt.date | None = None,
    lookback_days: int = 260,
    output_dir: Path = Path("prediction_system/output_sample/features"),
) -> Path | None:
    resolved = target_date or dt.date.today()
    start = resolved - dt.timedelta(days=lookback_days)
    logger.info(
        "(TEST) Feature build JSON export: target=%s, window=%s~%s",
        resolved,
        start,
        resolved,
    )
    feature_df = build_feature_store((start, resolved), METRIC_STOCKS)
    if feature_df.empty:
        logger.warning("Feature DataFrame is empty. JSON export skipped.")
        return None

    records = feature_df.reset_index().to_dict(orient="records")
    output_dir.mkdir(parents=True, exist_ok=True)
    target_path = output_dir / f"features_{resolved:%Y%m%d}.json"
    write_json(records, target_path)
    logger.info("Feature JSON 저장 완료: %s (rows=%d)", target_path, len(records))
    return target_path


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Feature build JSON exporter")
    parser.add_argument("--target-date", type=str, help="YYYY-MM-DD", default=None)
    parser.add_argument("--lookback-days", type=int, default=260)
    parser.add_argument(
        "--output-dir",
        type=str,
        default="prediction_system/output_sample/features",
        help="JSON을 저장할 디렉터리",
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
