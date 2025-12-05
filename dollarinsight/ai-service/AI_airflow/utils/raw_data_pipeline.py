"""Raw market data collection pipeline functions.

이 모듈은 주식/ETF/지수/거시지표 데이터를 하루치 수집하고
DB에 업서트하는 순서를 한 파일에 정리한 것이다.
Airflow DAG이나 기타 스케줄러에서 직접 호출할 수 있다.
"""

from __future__ import annotations

import datetime as dt
import logging
from typing import Iterable

try:
    import pandas_market_calendars as mcal  # type: ignore
except ImportError:  # pragma: no cover
    mcal = None

from pipelines.env_loader import load_env
from pipelines.db import get_connection
from pipelines.kis_client import default_client
from pipelines.watchlists import US_ETFS, US_INDICES, US_STOCKS

from pipelines.daily_json_export import collect_fred_daily

from pipelines.daily_price_collector import (
    collect_stock_daily_prices,
    collect_etf_daily_prices,
    collect_index_daily_prices,
)
from pipelines.master_metrics import update_etf_master_and_metrics


logger = logging.getLogger(__name__)
_HOLIDAY_FALLBACK_WARNED = False


def _resolve_target_date(
    execution_date: dt.datetime | None = None,
    target_date: str | None = None,
) -> dt.date:
    if target_date:
        return dt.date.fromisoformat(target_date)
    if execution_date:
        return execution_date.date()
    return (dt.datetime.utcnow() - dt.timedelta(days=1)).date()


def _is_us_trading_day(date: dt.date) -> bool:
    """미국(뉴욕) 시장 거래일 여부를 판단한다."""

    if date.weekday() >= 5:  # 토/일
        return False

    if mcal is None:
        global _HOLIDAY_FALLBACK_WARNED
        if not _HOLIDAY_FALLBACK_WARNED:
            logger.warning(
                "pandas_market_calendars 패키지가 없어 주말 외 휴장일 체크를 건너뜁니다. "
                "해당 패키지를 설치하면 정확한 휴장일 검사가 가능합니다."
            )
            _HOLIDAY_FALLBACK_WARNED = True
        return True

    nyse = mcal.get_calendar("XNYS")
    schedule = nyse.schedule(start_date=date, end_date=date)
    return not schedule.empty


def collect_stock_prices(
    *,
    target_date: str | None = None,
    execution_date: dt.datetime | None = None,
) -> None:
    load_env()
    date = _resolve_target_date(execution_date, target_date)
    client = default_client()
    collect_stock_daily_prices(
        US_STOCKS,
        start_date=date,
        end_date=date,
        client=client,
        save_to_db=True,
    )


def collect_etf_prices(
    *,
    target_date: str | None = None,
    execution_date: dt.datetime | None = None,
) -> None:
    load_env()
    date = _resolve_target_date(execution_date, target_date)
    client = default_client()
    collect_etf_daily_prices(
        US_ETFS,
        start_date=date,
        end_date=date,
        client=client,
        save_to_db=True,
    )
    update_etf_master_and_metrics(target_date=date, tickers=US_ETFS)


def collect_index_prices(
    *,
    target_date: str | None = None,
    execution_date: dt.datetime | None = None,
) -> None:
    load_env()
    date = _resolve_target_date(execution_date, target_date)
    client = default_client()
    collect_index_daily_prices(
        US_INDICES.keys(),
        start_date=date,
        end_date=date,
        client=client,
        save_to_db=True,
    )


def collect_macro_indicators(
    *,
    target_date: str | None = None,
    execution_date: dt.datetime | None = None,
) -> None:
    load_env()
    end_date = _resolve_target_date(execution_date, target_date)
    lookback_days = 5
    records: list[dict] = []
    for offset in range(lookback_days + 1):
        day = end_date - dt.timedelta(days=offset)
        records.extend(collect_fred_daily(date=day))
    if not records:
        return
    sql = """
        INSERT INTO macro_economic_indicators (
            indicator_code, date, value, unit, seasonal_adjustment,
            change_mom, change_yoy, source, source_vendor
        ) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
        ON CONFLICT (indicator_code, date) DO UPDATE SET
            value = COALESCE(EXCLUDED.value, macro_economic_indicators.value),
            unit = EXCLUDED.unit,
            seasonal_adjustment = EXCLUDED.seasonal_adjustment,
            change_mom = COALESCE(EXCLUDED.change_mom, macro_economic_indicators.change_mom),
            change_yoy = COALESCE(EXCLUDED.change_yoy, macro_economic_indicators.change_yoy),
            source = EXCLUDED.source,
            source_vendor = EXCLUDED.source_vendor;
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            params = [
                (
                    row.get("indicator_code"),
                    dt.date.fromisoformat(row["date"]),
                    row.get("value"),
                    row.get("unit"),
                    row.get("seasonal_adjustment"),
                    row.get("change_mom"),
                    row.get("change_yoy"),
                    "FRED",
                    row.get("source_vendor", "FRED"),
                )
                for row in records
            ]
            cur.executemany(sql, params)


def collect_etf_metrics(
    *,
    target_date: str | None = None,
    execution_date: dt.datetime | None = None,
) -> None:
    """Fetch ETF metrics from yfinance and update master/daily tables."""

    load_env()
    date = _resolve_target_date(execution_date, target_date)
    update_etf_master_and_metrics(target_date=date, tickers=US_ETFS)


def run_pipeline(
    *,
    target_date: str | None = None,
    execution_date: dt.datetime | None = None,
) -> None:
    resolved_date = _resolve_target_date(execution_date, target_date)
    if not _is_us_trading_day(resolved_date):
        logger.info("미국 휴장일(%s)이므로 raw data pipeline 실행을 건너뜁니다.", resolved_date)
        return

    target_iso = resolved_date.isoformat()
    collect_stock_prices(target_date=target_iso)
    collect_etf_prices(target_date=target_iso)
    collect_index_prices(target_date=target_iso)
    collect_macro_indicators(target_date=target_iso)


__all__ = [
    "collect_stock_prices",
    "collect_etf_prices",
    "collect_index_prices",
    "collect_macro_indicators",
    "collect_etf_metrics",
    "run_pipeline",
]



