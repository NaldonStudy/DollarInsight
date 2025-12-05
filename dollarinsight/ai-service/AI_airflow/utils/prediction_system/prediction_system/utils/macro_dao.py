"""거시 지표 DAO 스텁."""

from __future__ import annotations

import datetime as dt
from typing import Iterable

import pandas as pd

from .db import fetch_dataframe


def fetch_macro_series(
    series_ids: Iterable[str],
    start: dt.date,
    end: dt.date,
) -> pd.DataFrame:
    """FRED 거시 지표 데이터를 반환한다."""

    codes = list(series_ids)
    if not codes:
        return pd.DataFrame()

    query = """
        SELECT
            indicator_code,
            date,
            value,
            unit,
            seasonal_adjustment,
            change,
            change_mom,
            change_yoy,
            source,
            source_vendor,
            created_at
        FROM macro_economic_indicators
        WHERE indicator_code = ANY(%s)
          AND date BETWEEN %s AND %s
        ORDER BY date, indicator_code
    """
    return fetch_dataframe(query, (codes, start, end))


def fetch_latest_macro_release(series_id: str) -> dt.date | None:
    """해당 시리즈의 최근 발표일을 반환한다."""

    query = """
        SELECT MAX(date) AS latest_date
        FROM macro_economic_indicators
        WHERE indicator_code = %s
    """
    df = fetch_dataframe(query, (series_id,))
    if df.empty:
        return None
    latest = df.loc[0, "latest_date"]
    if pd.isna(latest):
        return None
    return pd.to_datetime(latest).date()


