from __future__ import annotations

import datetime as dt
from typing import Iterable, Mapping

import pandas as pd
from psycopg2.extras import execute_batch

from .db import fetch_dataframe, get_connection


def upsert_predictions(records: Iterable[Mapping[str, object]]) -> int:
    """`stock_predictions_daily` 테이블에 예측 결과를 업서트한다."""

    payload = list(records)
    if not payload:
        return 0

    sql = """
        INSERT INTO stock_predictions_daily (
            prediction_date,
            ticker,
            horizon_days,
            point_estimate,
            lower_bound,
            upper_bound,
            prob_up,
            model_version,
            residual_quantile,
            feature_window_id
        ) VALUES (
            %(prediction_date)s,
            %(ticker)s,
            %(horizon_days)s,
            %(point_estimate)s,
            %(lower_bound)s,
            %(upper_bound)s,
            %(prob_up)s,
            %(model_version)s,
            %(residual_quantile)s,
            %(feature_window_id)s
        )
        ON CONFLICT (prediction_date, ticker, horizon_days) DO UPDATE SET
            point_estimate = EXCLUDED.point_estimate,
            lower_bound = EXCLUDED.lower_bound,
            upper_bound = EXCLUDED.upper_bound,
            prob_up = EXCLUDED.prob_up,
            model_version = EXCLUDED.model_version,
            residual_quantile = EXCLUDED.residual_quantile,
            feature_window_id = EXCLUDED.feature_window_id
    """

    with get_connection() as conn:
        with conn.cursor() as cur:
            execute_batch(cur, sql, payload, page_size=200)
        conn.commit()
    return len(payload)


def fetch_predictions(
    *,
    prediction_date: dt.date | None = None,
    ticker: str | None = None,
    horizon_days: int | None = None,
) -> pd.DataFrame:
    """예측 결과를 DataFrame으로 조회한다."""

    conditions: list[str] = []
    params: list[object] = []

    if prediction_date is not None:
        conditions.append("prediction_date = %s")
        params.append(prediction_date)
    if ticker is not None:
        conditions.append("ticker = %s")
        params.append(ticker)
    if horizon_days is not None:
        conditions.append("horizon_days = %s")
        params.append(horizon_days)

    where_clause = ""
    if conditions:
        where_clause = "WHERE " + " AND ".join(conditions)

    query = f"""
        SELECT
            prediction_date,
            ticker,
            horizon_days,
            point_estimate,
            lower_bound,
            upper_bound,
            prob_up,
            model_version,
            residual_quantile,
            feature_window_id,
            created_at
        FROM stock_predictions_daily
        {where_clause}
        ORDER BY prediction_date DESC, ticker, horizon_days
    """
    return fetch_dataframe(query, tuple(params) if params else None)
