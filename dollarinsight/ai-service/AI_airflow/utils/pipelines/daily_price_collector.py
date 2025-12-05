"""Daily price collection helpers (stocks, ETFs, indices).

KIS Open API를 호출해 일별 시세를 조회하고
`stock_price_daily`, `etf_price_daily`, `index_price_daily` 테이블에 업서트한다.
원래 `stock_data_collection` 패키지에 있던 구현을 이 프로젝트 내부로 옮겨온 것이다.
"""

from __future__ import annotations

import datetime as dt
from typing import Dict, Iterable, List, Tuple

from psycopg2.extras import execute_batch  # type: ignore

from pipelines.db import get_connection
from pipelines.kis_client import KISClient, default_client
from pipelines.daily_json_export import (
    collect_stock_prices as export_collect_stock_prices,
    collect_etf_prices as export_collect_etf_prices,
    collect_index_prices as export_collect_index_prices,
)
from pipelines.watchlists import US_INDICES


def _to_float(value):
    if value in (None, ""):
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def _to_int(value):
    if value in (None, ""):
        return None
    try:
        return int(value)
    except (TypeError, ValueError):
        return None

def _insert_stock_price_records(rows: Iterable[Tuple]) -> int:
    rows = list(rows)
    if not rows:
        return 0
    sql = """
        INSERT INTO stock_price_daily (
            ticker, price_date, open, high, low, close, volume, adj_close,
            amount, change, change_pct, change_sign,
            bid, ask, bid_size, ask_size, source_vendor
        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (ticker, price_date) DO UPDATE SET
            open = EXCLUDED.open,
            high = EXCLUDED.high,
            low = EXCLUDED.low,
            close = EXCLUDED.close,
            volume = EXCLUDED.volume,
            adj_close = EXCLUDED.adj_close,
            amount = EXCLUDED.amount,
            change = EXCLUDED.change,
            change_pct = EXCLUDED.change_pct,
            change_sign = EXCLUDED.change_sign,
            bid = EXCLUDED.bid,
            ask = EXCLUDED.ask,
            bid_size = EXCLUDED.bid_size,
            ask_size = EXCLUDED.ask_size,
            source_vendor = EXCLUDED.source_vendor
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            execute_batch(cur, sql, rows, page_size=500)
    return len(rows)


def collect_stock_daily_prices(
    tickers: Iterable[str],
    *,
    start_date: dt.date,
    end_date: dt.date,
    client: KISClient | None = None,
    save_to_db: bool = True,
):
    client = client or default_client()
    rows_by_key: Dict[Tuple[str, dt.date], Tuple] = {}
    ticker_list = list(tickers)
    day = start_date
    while day <= end_date:
        records = export_collect_stock_prices(date=day, tickers=ticker_list, client=client)
        for record in records:
            price_date = dt.date.fromisoformat(record["price_date"])
            key = (record["ticker"], price_date)
            rows_by_key[key] = (
                record["ticker"],
                price_date,
                float(record.get("open") or 0),
                float(record.get("high") or 0),
                float(record.get("low") or 0),
                float(record.get("close") or 0),
                int(record.get("volume") or 0),
                float(record.get("adj_close") or record.get("close") or 0),
                _to_float(record.get("amount")),
                _to_float(record.get("change")),
                _to_float(record.get("change_pct")),
                record.get("change_sign"),
                _to_float(record.get("bid")),
                _to_float(record.get("ask")),
                _to_int(record.get("bid_size")),
                _to_int(record.get("ask_size")),
                record.get("source_vendor"),
            )
        day += dt.timedelta(days=1)

    rows = list(rows_by_key.values())
    if not save_to_db:
        return rows
    return _insert_stock_price_records(rows)


def collect_etf_daily_prices(
    tickers: Iterable[str],
    *,
    start_date: dt.date,
    end_date: dt.date,
    client: KISClient | None = None,
    save_to_db: bool = True,
):
    client = client or default_client()
    rows_by_key: Dict[Tuple[str, dt.date], Tuple] = {}
    ticker_list = list(tickers)
    day = start_date
    while day <= end_date:
        records = export_collect_etf_prices(date=day, tickers=ticker_list, client=client)
        for record in records:
            price_date = dt.date.fromisoformat(record["price_date"])
            key = (record["ticker"], price_date)
            rows_by_key[key] = (
                price_date,
                record["ticker"],
                float(record.get("open") or 0),
                float(record.get("high") or 0),
                float(record.get("low") or 0),
                float(record.get("close") or 0),
                int(record.get("volume") or 0),
            )
        day += dt.timedelta(days=1)

    rows = list(rows_by_key.values())
    if not save_to_db:
        return rows
    return _insert_etf_price_records(rows)


def collect_index_daily_prices(
    tickers: Iterable[str],
    *,
    start_date: dt.date,
    end_date: dt.date,
    client: KISClient | None = None,
    save_to_db: bool = True,
):
    client = client or default_client()
    rows_by_key: Dict[Tuple[str, dt.date], Tuple] = {}
    index_map = {ticker: US_INDICES[ticker] for ticker in tickers if ticker in US_INDICES}
    day = start_date
    while day <= end_date:
        records = export_collect_index_prices(date=day, indices=index_map or US_INDICES, client=client)
        for record in records:
            price_date = dt.date.fromisoformat(record["price_date"])
            key = (record["ticker"], price_date)
            rows_by_key[key] = (
                price_date,
                record["ticker"],
                float(record.get("close") or 0),
                float(record.get("change_pct") or 0),
            )
        day += dt.timedelta(days=1)

    rows = list(rows_by_key.values())
    if not save_to_db:
        return rows
    return _insert_index_price_records(rows)


def _insert_etf_price_records(rows: Iterable[Tuple]) -> int:
    rows = list(rows)
    if not rows:
        return 0
    sql = """
        INSERT INTO etf_price_daily (
            price_date, ticker, open, high, low, close, volume
        ) VALUES (%s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (price_date, ticker) DO UPDATE SET
            open = EXCLUDED.open,
            high = EXCLUDED.high,
            low = EXCLUDED.low,
            close = EXCLUDED.close,
            volume = EXCLUDED.volume
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            execute_batch(cur, sql, rows, page_size=500)
    return len(rows)


def _insert_index_price_records(rows: Iterable[Tuple]) -> int:
    rows = list(rows)
    if not rows:
        return 0
    sql = """
        INSERT INTO index_price_daily (
            price_date, ticker, close, change_pct
        ) VALUES (%s, %s, %s, %s)
        ON CONFLICT (price_date, ticker) DO UPDATE SET
            close = EXCLUDED.close,
            change_pct = EXCLUDED.change_pct
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            execute_batch(cur, sql, rows, page_size=500)
    return len(rows)


__all__ = [
    "collect_stock_daily_prices",
    "collect_etf_daily_prices",
    "collect_index_daily_prices",
]


