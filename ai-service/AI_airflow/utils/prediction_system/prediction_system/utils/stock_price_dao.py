"""주식 일봉 데이터 액세스 객체 스텁."""

from __future__ import annotations

import datetime as dt
from typing import Iterable

import pandas as pd

from .db import fetch_dataframe


def fetch_prices(
    tickers: Iterable[str],
    start: dt.date,
    end: dt.date,
) -> pd.DataFrame:
    """지정한 기간의 주식 일봉 데이터를 DataFrame으로 반환한다."""

    tickers_list = list(tickers)
    if not tickers_list:
        return pd.DataFrame()

    query = """
        SELECT
            price_date,
            ticker,
            open,
            high,
            low,
            close,
            adj_close,
            volume,
            amount,
            change,
            change_pct,
            change_sign,
            bid,
            ask,
            bid_size,
            ask_size,
            source_vendor,
            created_at
        FROM stock_price_daily
        WHERE ticker = ANY(%s)
          AND price_date BETWEEN %s AND %s
        ORDER BY price_date, ticker
    """
    return fetch_dataframe(query, (tickers_list, start, end))


def fetch_latest_price_date() -> dt.date | None:
    """가장 최근에 수집된 주식 가격 일자를 반환한다."""

    query = "SELECT MAX(price_date) AS latest_date FROM stock_price_daily"
    df = fetch_dataframe(query)
    if df.empty:
        return None
    latest = df.loc[0, "latest_date"]
    if pd.isna(latest):
        return None
    return pd.to_datetime(latest).date()


