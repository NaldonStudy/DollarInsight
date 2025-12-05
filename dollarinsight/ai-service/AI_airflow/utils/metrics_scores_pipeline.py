"""Stock metrics & scores calculation pipeline."""

from __future__ import annotations

import datetime as dt
import logging
from typing import Dict, Iterable, List

try:
    import pandas_market_calendars as mcal  # type: ignore
except ImportError:  # pragma: no cover
    mcal = None

from pipelines.env_loader import load_env
from pipelines.db import get_connection
from pipelines.watchlists import METRIC_STOCKS

from pipelines.compare_metrics_scores import (
    compute_metrics_for_ticker,
    compute_scores_for_ticker,
    fetch_master_info,
    fetch_metric_table_stats,
    fetch_price_history,
    fetch_financial_growth,
)


def _resolve_target_date(
    execution_date: dt.datetime | None = None,
    target_date: str | None = None,
) -> dt.date:
    if target_date:
        return dt.date.fromisoformat(target_date)
    if execution_date:
        return execution_date.date()
    return (dt.datetime.utcnow() - dt.timedelta(days=1)).date()


logger = logging.getLogger(__name__)
_HOLIDAY_FALLBACK_WARNED = False


def _is_us_trading_day(date: dt.date) -> bool:
    if date.weekday() >= 5:
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


def _upsert_metrics(records: Iterable[dict]) -> None:
    if not records:
        return
    sql = """
        INSERT INTO stock_metrics_daily (
            metric_date, ticker,
            mom_1m, mom_3m, mom_6m,
            volatility_20, beta_60, pos_52w, turnover,
            rsi_14, ma20, ma60, price_to_ma20
        ) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
        ON CONFLICT (metric_date, ticker) DO UPDATE SET
            mom_1m = EXCLUDED.mom_1m,
            mom_3m = EXCLUDED.mom_3m,
            mom_6m = EXCLUDED.mom_6m,
            volatility_20 = EXCLUDED.volatility_20,
            beta_60 = EXCLUDED.beta_60,
            pos_52w = EXCLUDED.pos_52w,
            turnover = EXCLUDED.turnover,
            rsi_14 = EXCLUDED.rsi_14,
            ma20 = EXCLUDED.ma20,
            ma60 = EXCLUDED.ma60,
            price_to_ma20 = EXCLUDED.price_to_ma20;
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            params = [
                (
                    rec["metric_date"],
                    rec["ticker"],
                    rec.get("mom_1m"),
                    rec.get("mom_3m"),
                    rec.get("mom_6m"),
                    rec.get("volatility_20"),
                    rec.get("beta_60"),
                    rec.get("pos_52w"),
                    rec.get("turnover"),
                    rec.get("rsi_14"),
                    rec.get("ma20"),
                    rec.get("ma60"),
                    rec.get("price_to_ma20"),
                )
                for rec in records
            ]
            cur.executemany(sql, params)


def _upsert_scores(records: Iterable[dict]) -> None:
    if not records:
        return
    sql = """
        INSERT INTO stock_scores_daily (
            score_date, ticker,
            score_momentum, score_valuation, score_growth,
            score_flow, score_risk, total_score
        ) VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
        ON CONFLICT (score_date, ticker) DO UPDATE SET
            score_momentum = EXCLUDED.score_momentum,
            score_valuation = EXCLUDED.score_valuation,
            score_growth = EXCLUDED.score_growth,
            score_flow = EXCLUDED.score_flow,
            score_risk = EXCLUDED.score_risk,
            total_score = EXCLUDED.total_score;
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            params = [
                (
                    rec["score_date"],
                    rec["ticker"],
                    rec.get("score_momentum"),
                    rec.get("score_valuation"),
                    rec.get("score_growth"),
                    rec.get("score_flow"),
                    rec.get("score_risk"),
                    rec.get("total_score"),
                )
                for rec in records
            ]
            cur.executemany(sql, params)


def calculate_stock_metrics(
    *,
    target_date: str | None = None,
    execution_date: dt.datetime | None = None,
) -> List[dict]:
    load_env()
    target = _resolve_target_date(execution_date, target_date)
    master_infos = fetch_master_info()
    spy_history = fetch_price_history("SPY", target - dt.timedelta(days=200), target)
    spy_prices = spy_history["adj_close"].fillna(spy_history["close"])
    spy_prices.index = spy_history["price_date"]
    metrics: List[dict] = []
    for ticker in METRIC_STOCKS:
        info = master_infos.get(ticker)
        if info is None:
            continue
        metric = compute_metrics_for_ticker(ticker, target, spy_prices, info)
        if metric:
            metrics.append(metric)
    _upsert_metrics(metrics)
    return metrics


def calculate_stock_scores(
    *,
    target_date: str | None = None,
    execution_date: dt.datetime | None = None,
    metrics_cache: Dict[str, dict] | None = None,
) -> None:
    load_env()
    target = _resolve_target_date(execution_date, target_date)
    master_infos = fetch_master_info()
    spy_history = fetch_price_history("SPY", target - dt.timedelta(days=200), target)
    spy_prices = spy_history["adj_close"].fillna(spy_history["close"])
    spy_prices.index = spy_history["price_date"]

    metrics_map: Dict[str, dict] = {}
    if metrics_cache:
        metrics_map = metrics_cache
    else:
        for ticker in METRIC_STOCKS:
            info = master_infos.get(ticker)
            if info is None:
                continue
            metric = compute_metrics_for_ticker(ticker, target, spy_prices, info)
            if metric:
                metrics_map[ticker] = metric

    stats = fetch_metric_table_stats()
    growth_map = fetch_financial_growth(metrics_map.keys())

    scores: List[dict] = []
    for ticker, metric in metrics_map.items():
        info = master_infos.get(ticker)
        if info is None:
            continue
        score = compute_scores_for_ticker(
            ticker,
            metric,
            info,
            growth_map.get(ticker),
            stats,
        )
        scores.append(score)

    _upsert_scores(scores)


def run_pipeline(
    *,
    target_date: str | None = None,
    execution_date: dt.datetime | None = None,
) -> None:
    resolved_date = _resolve_target_date(execution_date, target_date)
    if not _is_us_trading_day(resolved_date):
        logger.info("미국 휴장일(%s)이므로 metrics/scores pipeline을 건너뜁니다.", resolved_date)
        return

    target_iso = resolved_date.isoformat()
    metrics = calculate_stock_metrics(target_date=target_iso)
    metric_map = {rec["ticker"]: rec for rec in metrics}
    calculate_stock_scores(
        target_date=target_iso,
        metrics_cache=metric_map,
    )


__all__ = [
    "calculate_stock_metrics",
    "calculate_stock_scores",
    "run_pipeline",
]

