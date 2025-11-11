"""Utilities to update master tables with derived metrics."""

from __future__ import annotations

import datetime as dt
import logging
from decimal import Decimal, InvalidOperation
from typing import Iterable, Sequence

import yfinance as yf
from psycopg2.extras import RealDictCursor

from pipelines.env_loader import load_env
from pipelines.db import get_connection
from pipelines.watchlists import US_ETFS

logger = logging.getLogger(__name__)


def update_stock_master_metrics(
    tickers: Sequence[str] | None = None,
    *,
    dividend_lookback_days: int = 365,
    as_of_date: dt.date | None = None,
) -> None:
    """
    Update `stocks_master` derived columns (dividend yield, ROE, PSR).

    Parameters
    ----------
    tickers:
        Optional iterable of tickers to update. If None, update all stocks.
    dividend_lookback_days:
        Window (in days) to aggregate dividends for annualized yield.
    """

    load_env()

    with get_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            if tickers is None:
                cur.execute("SELECT ticker, market_cap FROM stocks_master")
                rows = cur.fetchall()
            else:
                cur.execute(
                    "SELECT ticker, market_cap FROM stocks_master WHERE ticker = ANY(%s)",
                    (list(tickers),),
                )
                rows = cur.fetchall()

            for row in rows:
                ticker = row["ticker"]
                market_cap = row["market_cap"]

                # 최신 종가
                if as_of_date:
                    cur.execute(
                        """
                        SELECT price_date, close
                        FROM stock_price_daily
                        WHERE ticker = %s
                          AND price_date <= %s
                        ORDER BY price_date DESC
                        LIMIT 1
                        """,
                        (ticker, as_of_date),
                    )
                else:
                    cur.execute(
                        """
                        SELECT price_date, close
                        FROM stock_price_daily
                        WHERE ticker = %s
                        ORDER BY price_date DESC
                        LIMIT 1
                        """,
                        (ticker,),
                    )
                price_row = cur.fetchone()
                if not price_row:
                    continue

                close_price = price_row["close"]
                reference_date = price_row["price_date"]
                lookback_start = reference_date - dt.timedelta(days=dividend_lookback_days)

                dividend_yield = None
                if close_price and close_price != 0:
                    cur.execute(
                        """
                        SELECT COALESCE(SUM(dividend_per_share), 0) AS total_dividends
                        FROM stocks_dividends
                        WHERE ticker = %s
                          AND basis_date >= %s
                          AND basis_date <= %s
                        """,
                        (ticker, lookback_start, reference_date),
                    )
                    div_row = cur.fetchone()
                    total_dividends = div_row["total_dividends"] if div_row else None
                    if total_dividends is not None:
                        try:
                            dividend_yield = Decimal(total_dividends) / Decimal(close_price)
                        except (InvalidOperation, ZeroDivisionError):
                            dividend_yield = None

                # 최신 재무제표
                cur.execute(
                    """
                    SELECT revenue, net_income, total_equity
                    FROM stocks_financial_statements
                    WHERE ticker = %s
                    ORDER BY period DESC
                    LIMIT 1
                    """,
                    (ticker,),
                )
                fin_row = cur.fetchone()
                revenue = fin_row["revenue"] if fin_row else None
                net_income = fin_row["net_income"] if fin_row else None
                total_equity = fin_row["total_equity"] if fin_row else None

                roe = None
                if net_income is not None and total_equity not in (None, 0):
                    try:
                        roe = Decimal(net_income) / Decimal(total_equity)
                    except (InvalidOperation, ZeroDivisionError):
                        roe = None

                psr = None
                if market_cap not in (None, 0) and revenue not in (None, 0):
                    try:
                        psr = Decimal(market_cap) / Decimal(revenue)
                    except (InvalidOperation, ZeroDivisionError):
                        psr = None

                cur.execute(
                    """
                    UPDATE stocks_master
                    SET dividend_yield_annualized = %s,
                        roe = %s,
                        psr = %s
                    WHERE ticker = %s
                    """,
                    (
                        float(dividend_yield) if dividend_yield is not None else None,
                        float(roe) if roe is not None else None,
                        float(psr) if psr is not None else None,
                        ticker,
                    ),
                )

        conn.commit()
    logger.info("Updated stock master metrics for %s tickers.", len(rows))


def update_etf_master_and_metrics(
    target_date: dt.date,
    tickers: Iterable[str] | None = None,
    *,
    data_source: str = "yfinance",
) -> None:
    """
    Fetch ETF metrics from yfinance and update both `etf_master` and
    `etf_metrics_daily`.

    Parameters
    ----------
    target_date:
        Date of the metrics (usually the price date that has just been ingested).
    tickers:
        Optional iterable of ETF tickers. Defaults to watchlist `US_ETFS`.
    data_source:
        String stored in DB to indicate origin.
    """

    load_env()
    tickers = list(tickers or US_ETFS)

    with get_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            for ticker in tickers:
                yf_ticker = yf.Ticker(ticker)
                try:
                    info = yf_ticker.info or {}
                except Exception as exc:  # pragma: no cover
                    logger.warning("yfinance info fetch failed for %s: %s", ticker, exc)
                    info = {}

                market_cap = info.get("marketCap")
                total_assets = info.get("totalAssets")
                nav = info.get("navPrice")
                dividend_yield = info.get("yield")
                expense_ratio = info.get("annualReportExpenseRatio") or info.get(
                    "feesExpensesInvestment"
                )

                # DB에서 당일 종가 조회
                cur.execute(
                    """
                    SELECT close
                    FROM etf_price_daily
                    WHERE ticker = %s
                      AND price_date = %s
                    """,
                    (ticker, target_date),
                )
                price_row = cur.fetchone()
                close_price = price_row["close"] if price_row else info.get("regularMarketPrice")

                premium_discount = None
                if nav not in (None, 0) and close_price not in (None, 0):
                    try:
                        premium_discount = float(close_price) / float(nav) - 1.0
                    except (ValueError, ZeroDivisionError):
                        premium_discount = None

                # Carry forward previous day's values when fresh data is missing
                cur.execute(
                    """
                    SELECT market_cap, dividend_yield, total_assets, nav,
                           premium_discount, expense_ratio
                    FROM etf_metrics_daily
                    WHERE ticker = %s
                      AND as_of_date < %s
                    ORDER BY as_of_date DESC
                    LIMIT 1
                    """,
                    (ticker, target_date),
                )
                prev_row = cur.fetchone()

                def carry_forward(current: float | None, key: str) -> tuple[float | None, bool]:
                    if current is not None:
                        return current, False
                    if prev_row and prev_row.get(key) is not None:
                        return prev_row[key], True
                    return None, False

                original_source = data_source
                missing_replaced = False

                market_cap, used_prev = carry_forward(market_cap, "market_cap")
                missing_replaced = missing_replaced or used_prev

                dividend_yield, used_prev = carry_forward(dividend_yield, "dividend_yield")
                missing_replaced = missing_replaced or used_prev

                total_assets, used_prev = carry_forward(total_assets, "total_assets")
                missing_replaced = missing_replaced or used_prev

                nav, used_prev = carry_forward(nav, "nav")
                missing_replaced = missing_replaced or used_prev

                # Recompute premium discount if we now have nav/close
                if premium_discount is None and nav not in (None, 0) and close_price not in (None, 0):
                    try:
                        premium_discount = float(close_price) / float(nav) - 1.0
                    except (ValueError, ZeroDivisionError):
                        premium_discount = None

                premium_discount, used_prev = carry_forward(premium_discount, "premium_discount")
                missing_replaced = missing_replaced or used_prev

                expense_ratio, used_prev = carry_forward(expense_ratio, "expense_ratio")
                missing_replaced = missing_replaced or used_prev

                data_source = "carry_forward" if missing_replaced else original_source

                cur.execute(
                    """
                    INSERT INTO etf_metrics_daily (
                        as_of_date,
                        ticker,
                        market_cap,
                        dividend_yield,
                        total_assets,
                        nav,
                        premium_discount,
                        expense_ratio,
                        data_source
                    ) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
                    ON CONFLICT (as_of_date, ticker) DO UPDATE SET
                        market_cap = EXCLUDED.market_cap,
                        dividend_yield = EXCLUDED.dividend_yield,
                        total_assets = EXCLUDED.total_assets,
                        nav = EXCLUDED.nav,
                        premium_discount = EXCLUDED.premium_discount,
                        expense_ratio = EXCLUDED.expense_ratio,
                        data_source = EXCLUDED.data_source
                    """,
                    (
                        target_date,
                        ticker,
                        market_cap,
                        dividend_yield,
                        total_assets,
                        nav,
                        premium_discount,
                        expense_ratio,
                        data_source,
                    ),
                )

                cur.execute(
                    """
                    UPDATE etf_master
                    SET market_cap_latest = %s,
                        total_assets_latest = %s,
                        nav_latest = %s,
                        premium_discount_latest = %s,
                        dividend_yield_latest = %s,
                        metrics_updated_at = now()
                    WHERE ticker = %s
                    """,
                    (
                        market_cap,
                        total_assets,
                        nav,
                        premium_discount,
                        dividend_yield,
                        ticker,
                    ),
                )

        conn.commit()
    logger.info("Updated ETF metrics for %s tickers (date=%s).", len(tickers), target_date)


