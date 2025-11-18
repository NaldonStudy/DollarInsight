from __future__ import annotations

import datetime as dt
import os
from pathlib import Path
from typing import Iterable

import pandas as pd

DEFAULT_CACHE_DIR = Path(
    os.getenv(
        "FEATURE_STORE_DIR",
        Path(__file__).resolve().parents[1] / "artifacts" / "feature_store",
    )
)


def _parse_range_from_name(name: str) -> tuple[dt.date, dt.date] | None:
    if not name.startswith("features_") or not name.endswith(".parquet"):
        return None
    body = name[len("features_"):-len(".parquet")]
    try:
        start_str, end_str = body.split("_")
        start = dt.datetime.strptime(start_str, "%Y%m%d").date()
        end = dt.datetime.strptime(end_str, "%Y%m%d").date()
        return start, end
    except Exception:  # pragma: no cover
        return None


def _find_covering_cache(
    date_range: tuple[dt.date, dt.date],
    cache_dir: Path,
) -> Path | None:
    req_start, req_end = date_range
    candidates = []
    for file_path in cache_dir.glob("features_*.parquet"):
        parsed = _parse_range_from_name(file_path.name)
        if parsed is None:
            continue
        start, end = parsed
        if start <= req_start and end >= req_end:
            candidates.append((start, end, file_path))
    if not candidates:
        return None
    candidates.sort(key=lambda x: (x[0], x[1]))
    return candidates[0][2]


def get_cache_path(date_range: tuple[dt.date, dt.date], cache_dir: Path | None = None) -> Path:
    cache_dir = cache_dir or DEFAULT_CACHE_DIR
    start, end = date_range
    return cache_dir / f"features_{start:%Y%m%d}_{end:%Y%m%d}.parquet"


def save_feature_store(
    date_range: tuple[dt.date, dt.date],
    feature_df: pd.DataFrame,
    cache_dir: Path | None = None,
) -> Path:
    file_path = get_cache_path(date_range, cache_dir)
    file_path.parent.mkdir(parents=True, exist_ok=True)
    feature_df.to_parquet(file_path)
    return file_path


def load_feature_store(
    date_range: tuple[dt.date, dt.date],
    cache_dir: Path | None = None,
) -> pd.DataFrame | None:
    cache_dir = cache_dir or DEFAULT_CACHE_DIR
    exact_path = get_cache_path(date_range, cache_dir)
    if exact_path.exists():
        return pd.read_parquet(exact_path)

    covering = _find_covering_cache(date_range, cache_dir)
    if covering is None:
        return None
    df = pd.read_parquet(covering)
    start, end = date_range
    mask = (
        df.index.get_level_values("feature_date") >= pd.to_datetime(start)
    ) & (
        df.index.get_level_values("feature_date") <= pd.to_datetime(end)
    )
    return df[mask]
