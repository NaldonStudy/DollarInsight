"""One-off helper to populate newly added master metrics."""

from __future__ import annotations

import argparse
import datetime as dt

from pipelines.master_metrics import (
    update_etf_master_and_metrics,
    update_stock_master_metrics,
)


def run(target_date: dt.date | None = None) -> None:
    """Populate derived metrics for stocks/ETFs."""

    target_date = target_date or (dt.date.today() - dt.timedelta(days=1))
    update_stock_master_metrics(as_of_date=target_date)
    update_etf_master_and_metrics(target_date=target_date)


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Backfill master metrics.")
    parser.add_argument(
        "--date",
        type=lambda s: dt.date.fromisoformat(s),
        help="Target date for ETF metrics (defaults to yesterday).",
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = _parse_args()
    run(target_date=args.date)


