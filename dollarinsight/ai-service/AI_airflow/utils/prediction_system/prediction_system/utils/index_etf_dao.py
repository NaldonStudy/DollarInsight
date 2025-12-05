"""ETF 및 지수 DAO 스텁."""

from __future__ import annotations

import datetime as dt
from typing import Iterable

import pandas as pd

from .db import fetch_dataframe


def fetch_etf_prices(
    tickers: Iterable[str],
    start: dt.date,
    end: dt.date,
) -> pd.DataFrame:
    """ETF 가격 데이터를 반환한다."""

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
            volume,
            created_at
        FROM etf_price_daily
        WHERE ticker = ANY(%s)
          AND price_date BETWEEN %s AND %s
        ORDER BY price_date, ticker
    """
    return fetch_dataframe(query, (tickers_list, start, end))


def fetch_index_prices(
    tickers: Iterable[str],
    start: dt.date,
    end: dt.date,
) -> pd.DataFrame:
    """지수 가격 데이터를 반환한다."""

    tickers_list = list(tickers)
    if not tickers_list:
        return pd.DataFrame()

    query = """
        SELECT
            price_date,
            ticker,
            close,
            change_pct,
            created_at
        FROM index_price_daily
        WHERE ticker = ANY(%s)
          AND price_date BETWEEN %s AND %s
        ORDER BY price_date, ticker
    """
    return fetch_dataframe(query, (tickers_list, start, end))


