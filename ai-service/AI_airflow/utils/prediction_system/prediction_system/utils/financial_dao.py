"""재무 데이터 DAO 스텁."""

from __future__ import annotations

import datetime as dt

import pandas as pd

from .db import fetch_dataframe


def fetch_financials(ticker: str, start_period: str) -> pd.DataFrame:
    """지정한 티커의 재무제표 데이터를 반환한다."""

    query = """
        SELECT
            ticker,
            period,
            period_type,
            revenue,
            net_income,
            operating_income,
            operating_margin,
            gross_margin,
            ebitda,
            operating_cashflow,
            total_assets,
            total_liabilities,
            total_equity,
            shares_outstanding,
            eps,
            bps,
            dps,
            created_at
        FROM stocks_financial_statements
        WHERE ticker = %s
          AND period >= %s
        ORDER BY period DESC
    """
    return fetch_dataframe(query, (ticker, start_period))


def fetch_dividends(ticker: str, start: dt.date, end: dt.date) -> pd.DataFrame:
    """배당 데이터를 반환한다."""

    query = """
        SELECT
            ticker,
            code,
            basis_date,
            dividend_per_share,
            currency_code,
            is_confirmed,
            basis_date_local,
            subscription_start,
            subscription_end,
            cash_allocation_rate,
            stock_allocation_rate,
            source_vendor,
            created_at
        FROM stocks_dividends
        WHERE ticker = %s
          AND basis_date BETWEEN %s AND %s
        ORDER BY basis_date
    """
    return fetch_dataframe(query, (ticker, start, end))


