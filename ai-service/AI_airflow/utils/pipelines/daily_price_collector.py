"""Daily price collection helpers (stocks, ETFs, indices).

KIS Open API를 호출해 일별 시세를 조회하고
`stock_price_daily`, `etf_price_daily`, `index_price_daily` 테이블에 업서트한다.
원래 `stock_data_collection` 패키지에 있던 구현을 이 프로젝트 내부로 옮겨온 것이다.
"""

from __future__ import annotations

import datetime as dt
from typing import Iterable, List, Tuple

from psycopg2.extras import execute_batch

from pipelines.db import get_connection
from pipelines.kis_client import KISClient, KISClientError, default_client


def _format_date(value: dt.date | dt.datetime) -> str:
    return value.strftime("%Y%m%d")


def _fetch_daily_itemchart(
    client: KISClient,
    *,
    ticker: str,
    start_date: dt.date,
    end_date: dt.date,
    market_div_code: str,
) -> List[dict]:
    """공통 itemchartprice 호출."""

    if start_date > end_date:
        start_date, end_date = end_date, start_date

    request_start = start_date
    if (end_date - start_date).days < 3:
        request_start = start_date - dt.timedelta(days=5)

    params = {
        "FID_COND_MRKT_DIV_CODE": market_div_code,
        "FID_INPUT_ISCD": ticker,
        "FID_INPUT_DATE_1": _format_date(request_start),
        "FID_INPUT_DATE_2": _format_date(end_date),
        "FID_PERIOD_DIV_CODE": "D",
        "FID_ORG_ADJ_PRC": "1",
    }
    data = client.request(
        "GET",
        "/uapi/domestic-stock/v1/quotations/inquire-daily-itemchartprice",
        tr_id="FHKST03010100",
        params=params,
    )
    output = data.get("output2") or data.get("output") or data.get("output1")
    if isinstance(output, dict):
        output = []
    if not isinstance(output, list):
        raise KISClientError(f"Unexpected response payload: {data}")
    filtered = []
    for row in output:
        bsop_date = dt.datetime.strptime(row["stck_bsop_date"], "%Y%m%d").date()
        if start_date <= bsop_date <= end_date:
            filtered.append(row)
    return filtered


def _fetch_daily_indexchart(
    client: KISClient,
    *,
    ticker: str,
    start_date: dt.date,
    end_date: dt.date,
) -> List[dict]:
    params = {
        "FID_COND_MRKT_DIV_CODE": "U",
        "FID_INPUT_ISCD": ticker,
        "FID_INPUT_DATE_1": _format_date(start_date),
        "FID_INPUT_DATE_2": _format_date(end_date),
        "FID_PERIOD_DIV_CODE": "D",
        "FID_ORG_ADJ_PRC": "1",
    }
    data = client.request(
        "GET",
        "/uapi/domestic-stock/v1/quotations/inquire-daily-indexchartprice",
        tr_id="FHPUP02100000",
        params=params,
    )
    output = data.get("output2") or data.get("output") or data.get("output1")
    if isinstance(output, dict):
        return []
    if not isinstance(output, list):
        raise KISClientError(f"Unexpected response payload: {data}")
    return output


def _map_price_record(ticker: str, row: dict) -> Tuple:
    price_date = dt.datetime.strptime(row["stck_bsop_date"], "%Y%m%d").date()
    return (
        ticker,
        price_date,
        float(row.get("stck_oprc", 0) or 0),
        float(row.get("stck_hgpr", 0) or 0),
        float(row.get("stck_lwpr", 0) or 0),
        float(row.get("stck_clpr", 0) or 0),
        int(row.get("acml_vol", 0) or 0),
        float(row.get("stck_clpr", 0) or 0),
    )


def _insert_price_records(table: str, rows: Iterable[Tuple]) -> int:
    rows = list(rows)
    if not rows:
        return 0
    sql = f"""
        INSERT INTO {table} (
            ticker, price_date, open, high, low, close, volume, adj_close
        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (ticker, price_date) DO UPDATE SET
            open = EXCLUDED.open,
            high = EXCLUDED.high,
            low = EXCLUDED.low,
            close = EXCLUDED.close,
            volume = EXCLUDED.volume,
            adj_close = EXCLUDED.adj_close
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
    all_rows: List[Tuple] = []
    for ticker in tickers:
        data = _fetch_daily_itemchart(
            client,
            ticker=ticker,
            start_date=start_date,
            end_date=end_date,
            market_div_code="J",
        )
        rows = [_map_price_record(ticker, row) for row in data]
        all_rows.extend(rows)
    if not save_to_db:
        return all_rows
    return _insert_price_records("stock_price_daily", all_rows)


def collect_etf_daily_prices(
    tickers: Iterable[str],
    *,
    start_date: dt.date,
    end_date: dt.date,
    client: KISClient | None = None,
    save_to_db: bool = True,
):
    client = client or default_client()
    all_rows: List[Tuple] = []
    for ticker in tickers:
        data = _fetch_daily_itemchart(
            client,
            ticker=ticker,
            start_date=start_date,
            end_date=end_date,
            market_div_code="J",
        )
        rows = [_map_price_record(ticker, row) for row in data]
        all_rows.extend(rows)
    if not save_to_db:
        return all_rows
    return _insert_price_records("etf_price_daily", all_rows)


def collect_index_daily_prices(
    tickers: Iterable[str],
    *,
    start_date: dt.date,
    end_date: dt.date,
    client: KISClient | None = None,
    save_to_db: bool = True,
):
    client = client or default_client()
    all_rows: List[Tuple] = []
    for ticker in tickers:
        data = _fetch_daily_indexchart(
            client,
            ticker=ticker,
            start_date=start_date,
            end_date=end_date,
        )
        rows = [_map_price_record(ticker, row) for row in data]
        all_rows.extend(rows)
    if not save_to_db:
        return all_rows
    return _insert_price_records("index_price_daily", all_rows)


__all__ = [
    "collect_stock_daily_prices",
    "collect_etf_daily_prices",
    "collect_index_daily_prices",
]


