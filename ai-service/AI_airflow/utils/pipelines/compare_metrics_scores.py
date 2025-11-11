"""주요 지표/점수 계산 검증 스크립트.

`stock_metrics_daily`, `stock_scores_daily` 계산 로직을 현재 DB 데이터에
재적용하여 결과를 비교한다. 날짜는 기본적으로 2025-11-04(테스트용)이며
CLI 옵션으로 조정 가능하다.
"""

from __future__ import annotations

import argparse
from collections import defaultdict
from dataclasses import dataclass
from datetime import date, timedelta
from math import isfinite
from typing import Dict, Iterable, Optional, Tuple

import numpy as np
import pandas as pd

from .env_loader import load_env
from .db import get_connection
from .watchlists import US_STOCKS


METRIC_FIELDS = [
    "mom_1m",
    "mom_3m",
    "mom_6m",
    "volatility_20",
    "beta_60",
    "pos_52w",
    "turnover",
    "rsi_14",
    "ma20",
    "ma60",
    "price_to_ma20",
]

SCORE_FIELDS = [
    "score_momentum",
    "score_valuation",
    "score_growth",
    "score_flow",
    "score_risk",
    "total_score",
]


def _round(value: Optional[float], digits: int) -> Optional[float]:
    if value is None or not isfinite(value):
        return None
    return round(float(value), digits)


def calculate_rsi(prices: pd.Series, period: int = 14) -> pd.Series:
    if len(prices) < period + 1:
        return pd.Series([None] * len(prices), index=prices.index)
    delta = prices.diff()
    gain = delta.where(delta > 0, 0).rolling(window=period).mean()
    loss = (-delta.where(delta < 0, 0)).rolling(window=period).mean()
    rs = gain / loss
    rsi = 100 - (100 / (1 + rs))
    return rsi


@dataclass
class MasterInfo:
    shares_outstanding: Optional[float]
    high_52w: Optional[float]
    low_52w: Optional[float]
    current_price: Optional[float]
    per: Optional[float]
    pbr: Optional[float]
    eps: Optional[float]
    bps: Optional[float]


def fetch_master_info() -> Dict[str, MasterInfo]:
    query = """
        SELECT ticker, shares_outstanding, high_52w, low_52w,
               current_price, per, pbr, eps, bps
        FROM stocks_master
        WHERE ticker = ANY(%s);
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(query, (US_STOCKS,))
            rows = cur.fetchall()
    info: Dict[str, MasterInfo] = {}
    for row in rows:
        (ticker, shares_outstanding, high_52w, low_52w,
         current_price, per, pbr, eps, bps) = row
        info[ticker] = MasterInfo(
            shares_outstanding=float(shares_outstanding) if shares_outstanding is not None else None,
            high_52w=float(high_52w) if high_52w is not None else None,
            low_52w=float(low_52w) if low_52w is not None else None,
            current_price=float(current_price) if current_price is not None else None,
            per=float(per) if per is not None else None,
            pbr=float(pbr) if pbr is not None else None,
            eps=float(eps) if eps is not None else None,
            bps=float(bps) if bps is not None else None,
        )
    return info


def fetch_price_history(
    ticker: str,
    start: date,
    end: date,
) -> pd.DataFrame:
    query = """
        SELECT price_date, close, adj_close, volume
        FROM stock_price_daily
        WHERE ticker = %s AND price_date BETWEEN %s AND %s
        ORDER BY price_date ASC;
    """
    with get_connection() as conn:
        df = pd.read_sql_query(query, conn, params=(ticker, start, end))
    if df.empty:
        return df
    df["price_date"] = pd.to_datetime(df["price_date"])
    df["close"] = pd.to_numeric(df["close"], errors="coerce")
    df["adj_close"] = pd.to_numeric(df["adj_close"], errors="coerce")
    df["volume"] = pd.to_numeric(df["volume"], errors="coerce")
    return df


def fetch_financial_growth(tickers: Iterable[str]) -> Dict[str, Optional[float]]:
    query = """
        SELECT DISTINCT ON (ticker)
               ticker, net_income_growth_yoy
        FROM stocks_financial_statements
        WHERE period_type = 'annual' AND ticker = ANY(%s)
        ORDER BY ticker, period DESC;
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(query, (list(tickers),))
            rows = cur.fetchall()
    return {ticker: (float(growth) if growth is not None else None) for ticker, growth in rows}


def fetch_metric_table_stats() -> Dict[str, Tuple[Optional[float], Optional[float]]]:
    def to_float_tuple(values: Tuple) -> Tuple:
        return tuple(float(v) if v is not None else None for v in values)

    stats = {}
    queries = {
        "per_pbr": """
            SELECT MIN(sp.close / NULLIF(sm.eps, 0)) as min_per,
                   MAX(sp.close / NULLIF(sm.eps, 0)) as max_per,
                   MIN(sp.close / NULLIF(sm.bps, 0)) as min_pbr,
                   MAX(sp.close / NULLIF(sm.bps, 0)) as max_pbr
            FROM stocks_master sm
            INNER JOIN stock_price_daily sp ON sm.ticker = sp.ticker
            WHERE sm.eps IS NOT NULL AND sm.bps IS NOT NULL
              AND sm.eps > 0 AND sm.bps > 0
              AND sp.close IS NOT NULL
              AND sp.price_date >= '2022-01-31'
              AND sp.price_date <= '2025-11-04'
              AND sp.ticker != 'SPY';
        """,
        "momentum": """
            SELECT MIN(mom_3m), MAX(mom_3m), MIN(mom_1m), MAX(mom_1m),
                   MIN(price_to_ma20), MAX(price_to_ma20)
            FROM stock_metrics_daily
            WHERE mom_3m IS NOT NULL AND mom_1m IS NOT NULL AND price_to_ma20 IS NOT NULL;
        """,
        "risk": """
            SELECT MIN(volatility_20), MAX(volatility_20), MIN(beta_60), MAX(beta_60)
            FROM stock_metrics_daily
            WHERE volatility_20 IS NOT NULL AND beta_60 IS NOT NULL;
        """,
        "turnover": """
            SELECT MIN(turnover), MAX(turnover)
            FROM stock_metrics_daily
            WHERE turnover IS NOT NULL;
        """,
    }
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(queries["per_pbr"])
            first = cur.fetchone()
            stats["per_pbr"] = to_float_tuple(first or ()) if first and first[0] is not None else None
            cur.execute(queries["momentum"])
            stats["momentum"] = to_float_tuple(cur.fetchone() or ())
            cur.execute(queries["risk"])
            stats["risk"] = to_float_tuple(cur.fetchone() or ())
            cur.execute(queries["turnover"])
            stats["turnover"] = to_float_tuple(cur.fetchone() or ())
    return stats


def normalize(value: float, min_val: float, max_val: float) -> float:
    value = float(value)
    min_val = float(min_val)
    max_val = float(max_val)
    if min_val == max_val:
        return 0.5
    return (value - min_val) / (max_val - min_val)


def fetch_close_price(ticker: str, target: date) -> Optional[float]:
    query = """
        SELECT close
        FROM stock_price_daily
        WHERE ticker = %s AND price_date = %s;
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(query, (ticker, target))
            row = cur.fetchone()
    if not row or row[0] is None:
        return None
    return float(row[0])


def compute_metrics_for_ticker(
    ticker: str,
    target_date: date,
    spy_prices: pd.Series,
    master_info: MasterInfo,
) -> Optional[Dict[str, Optional[float]]]:
    window_start = target_date - timedelta(days=180)
    df = fetch_price_history(ticker, window_start, target_date)
    if df.empty or len(df) < 20:
        return None

    prices = df["adj_close"].fillna(df["close"])
    volumes = df["volume"].fillna(0)
    prices.index = df["price_date"]
    volumes.index = df["price_date"]

    target_ts = pd.Timestamp(target_date)

    spy_aligned = spy_prices.loc[spy_prices.index >= prices.index.min()]
    returns = prices.pct_change()
    spy_returns = spy_aligned.pct_change()
    rsi_series = calculate_rsi(prices, period=14)
    ma20_series = prices.rolling(window=20).mean()
    ma60_series = prices.rolling(window=60).mean()
    volatility_series = returns.rolling(window=20).std() * np.sqrt(252) * 100

    beta_series = pd.Series([np.nan] * len(prices), index=prices.index)
    if not spy_returns.dropna().empty:
        for idx in range(len(prices)):
            if idx < 59:
                continue
            segment = prices.index[idx-59:idx+1]
            stock_window = returns.loc[segment].dropna()
            spy_window = spy_returns.loc[segment].dropna()
            common = stock_window.index.intersection(spy_window.index)
            if len(common) >= 30:
                stock_vals = stock_window.loc[common]
                spy_vals = spy_window.loc[common]
                if spy_vals.var() > 0:
                    beta_val = np.cov(stock_vals, spy_vals)[0, 1] / spy_vals.var()
                    beta_series.iloc[idx] = beta_val

    if target_ts not in prices.index:
        return None

    latest_price = prices.loc[target_ts]
    latest_volume = volumes.loc[target_ts]

    def pct_change(days: int) -> Optional[float]:
        if len(prices) > days and prices.iloc[-days] > 0:
            base = prices.iloc[-days]
            return (latest_price - base) / base * 100
        return None

    mom_1m = pct_change(20)
    mom_3m = pct_change(60)
    mom_6m = pct_change(120)
    volatility_20 = volatility_series.loc[target_ts] if not pd.isna(volatility_series.loc[target_ts]) else None
    beta_60 = beta_series.loc[target_ts] if not pd.isna(beta_series.loc[target_ts]) else None

    pos_52w = None
    if (
        master_info.high_52w
        and master_info.low_52w
        and master_info.current_price
        and master_info.high_52w > master_info.low_52w
    ):
        pos_52w = (
            (master_info.current_price - master_info.low_52w)
            / (master_info.high_52w - master_info.low_52w)
        ) * 100

    turnover = None
    if (
        master_info.shares_outstanding
        and master_info.shares_outstanding > 0
        and latest_volume is not None
    ):
        turnover = (latest_volume / master_info.shares_outstanding) * 100

    rsi_14 = rsi_series.loc[target_ts] if not pd.isna(rsi_series.loc[target_ts]) else None
    ma20 = ma20_series.loc[target_ts] if not pd.isna(ma20_series.loc[target_ts]) else None
    ma60 = ma60_series.loc[target_ts] if not pd.isna(ma60_series.loc[target_ts]) else None
    price_to_ma20 = None
    if ma20 and ma20 > 0:
        price_to_ma20 = ((latest_price - ma20) / ma20) * 100

    return {
        "metric_date": target_date,
        "ticker": ticker,
        "mom_1m": _round(mom_1m, 4) if mom_1m is not None else None,
        "mom_3m": _round(mom_3m, 4) if mom_3m is not None else None,
        "mom_6m": _round(mom_6m, 4) if mom_6m is not None else None,
        "volatility_20": _round(volatility_20, 4) if volatility_20 is not None else None,
        "beta_60": _round(beta_60, 4) if beta_60 is not None else None,
        "pos_52w": _round(pos_52w, 4) if pos_52w is not None else None,
        "turnover": _round(turnover, 4) if turnover is not None else None,
        "rsi_14": _round(rsi_14, 4) if rsi_14 is not None else None,
        "ma20": _round(ma20, 4) if ma20 is not None else None,
        "ma60": _round(ma60, 4) if ma60 is not None else None,
        "price_to_ma20": _round(price_to_ma20, 4) if price_to_ma20 is not None else None,
    }


def compute_scores_for_ticker(
    ticker: str,
    metric: Dict[str, Optional[float]],
    master: MasterInfo,
    growth: Optional[float],
    stats: Dict[str, Tuple[Optional[float], Optional[float]]],
) -> Dict[str, Optional[float]]:
    score_momentum = None
    mom_stats = stats.get("momentum")
    if mom_stats and metric["mom_1m"] is not None and metric["mom_3m"] is not None and metric["price_to_ma20"] is not None:
        min_mom, max_mom, min_mom1m, max_mom1m, min_ptm, max_ptm = mom_stats
        norm_mom1m = normalize(metric["mom_1m"], min_mom1m or 0, max_mom1m or 0) if min_mom1m is not None else 0.5
        norm_mom3m = normalize(metric["mom_3m"], min_mom or 0, max_mom or 0) if min_mom is not None else 0.5
        norm_ptm = normalize(metric["price_to_ma20"], min_ptm or 0, max_ptm or 0) if min_ptm is not None else 0.5
        norm_rsi = (metric["rsi_14"] / 100.0) if metric.get("rsi_14") is not None else 0.5
        score_momentum = (norm_mom1m * 0.3 + norm_mom3m * 0.3 + norm_ptm * 0.2 + norm_rsi * 0.2) * 100

    score_valuation = None
    per_stats = stats.get("per_pbr")
    if per_stats:
        price_for_day = fetch_close_price(ticker, metric["metric_date"])
        eps = master.eps
        bps = master.bps
        current_per = price_for_day / eps if price_for_day is not None and eps not in (None, 0) else None
        current_pbr = price_for_day / bps if price_for_day is not None and bps not in (None, 0) else None
        if current_per is not None and current_pbr is not None:
            min_per, max_per, min_pbr, max_pbr = per_stats
            per_score = 1 - normalize(current_per, min_per or 0, max_per or 0) if min_per is not None else 0.5
            pbr_score = 1 - normalize(current_pbr, min_pbr or 0, max_pbr or 0) if min_pbr is not None else 0.5
            score_valuation = ((per_score + pbr_score) / 2) * 100

    score_growth = None
    if growth is not None:
        norm_growth = max(0, min(1, (growth + 50) / 150.0))
        score_growth = norm_growth * 100

    score_flow = None
    turnover_stats = stats.get("turnover")
    if turnover_stats and metric.get("turnover") is not None:
        min_turn, max_turn = turnover_stats
        score_flow = normalize(metric["turnover"], min_turn or 0, max_turn or 0) * 100 if min_turn is not None else 50

    score_risk = None
    risk_stats = stats.get("risk")
    if risk_stats and metric.get("volatility_20") is not None and metric.get("beta_60") is not None:
        min_vol, max_vol, min_beta, max_beta = risk_stats
        vol_score = 1 - normalize(metric["volatility_20"], min_vol or 0, max_vol or 0) if min_vol is not None else 0.5
        beta_diff = abs((metric.get("beta_60") or 1) - 1.0)
        max_beta_diff = max(abs((max_beta or 1) - 1.0), abs((min_beta or 1) - 1.0)) if max_beta is not None else 1
        beta_score = 1 - normalize(beta_diff, 0, max_beta_diff or 1)
        score_risk = ((vol_score + beta_score) / 2) * 100

    scores = []
    weights = []
    def add(score: Optional[float], weight: float):
        if score is not None:
            scores.append(score)
            weights.append(weight)

    add(score_momentum, 0.25)
    add(score_valuation, 0.25)
    add(score_growth, 0.15)
    add(score_flow, 0.15)
    add(score_risk, 0.20)

    total_score = None
    if scores:
        total_weight = sum(weights)
        norm_weights = [w / total_weight for w in weights]
        total_score = sum(s * w for s, w in zip(scores, norm_weights))

    return {
        "score_date": metric["metric_date"],
        "ticker": ticker,
        "score_momentum": _round(score_momentum, 4) if score_momentum is not None else None,
        "score_valuation": _round(score_valuation, 4) if score_valuation is not None else None,
        "score_growth": _round(score_growth, 4) if score_growth is not None else None,
        "score_flow": _round(score_flow, 4) if score_flow is not None else None,
        "score_risk": _round(score_risk, 4) if score_risk is not None else None,
        "total_score": _round(total_score, 4) if total_score is not None else None,
    }


def fetch_db_metrics(target_date: date) -> Dict[str, Dict[str, Optional[float]]]:
    query = """
        SELECT ticker, mom_1m, mom_3m, mom_6m, volatility_20,
               beta_60, pos_52w, turnover, rsi_14, ma20, ma60, price_to_ma20
        FROM stock_metrics_daily
        WHERE metric_date = %s AND ticker = ANY(%s);
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(query, (target_date, US_STOCKS))
            rows = cur.fetchall()
    result = {}
    for row in rows:
        ticker = row[0]
        result[ticker] = {field: (float(value) if value is not None else None) for field, value in zip(METRIC_FIELDS, row[1:])}
    return result


def fetch_db_scores(target_date: date) -> Dict[str, Dict[str, Optional[float]]]:
    query = """
        SELECT ticker, score_momentum, score_valuation, score_growth,
               score_flow, score_risk, total_score
        FROM stock_scores_daily
        WHERE score_date = %s AND ticker = ANY(%s);
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(query, (target_date, US_STOCKS))
            rows = cur.fetchall()
    return {
        row[0]: {field: (float(value) if value is not None else None) for field, value in zip(SCORE_FIELDS, row[1:])}
        for row in rows
    }


def diff_records(
    expected: Dict[str, Dict[str, Optional[float]]],
    actual: Dict[str, Dict[str, Optional[float]]],
    fields: Iterable[str],
    tolerance: float = 1e-3,
) -> Dict[str, Dict[str, Tuple[Optional[float], Optional[float]]]]:
    diffs: Dict[str, Dict[str, Tuple[Optional[float], Optional[float]]]] = {}
    for ticker, exp_values in expected.items():
        act_values = actual.get(ticker)
        if not act_values:
            diffs[ticker] = {"_missing": (None, None)}
            continue
        field_diff = {}
        for field in fields:
            ev = exp_values.get(field)
            av = act_values.get(field)
            if ev is None and av is None:
                continue
            if ev is None or av is None:
                field_diff[field] = (ev, av)
            elif abs(ev - av) > tolerance:
                field_diff[field] = (ev, av)
        if field_diff:
            diffs[ticker] = field_diff
    extra = set(actual) - set(expected)
    for ticker in extra:
        diffs[ticker] = {"_extra": (None, None)}
    return diffs


def summarize_diffs(name: str, diffs: Dict[str, Dict[str, Tuple[Optional[float], Optional[float]]]]) -> None:
    print(f"\n{name} 비교 결과")
    if not diffs:
        print("  ✅ 차이 없음")
        return
    print(f"  ❌ 차이가 있는 티커: {len(diffs)}개")
    sample = list(diffs.items())[:5]
    for ticker, fields in sample:
        print(f"    - {ticker}: {fields}")


def main(target: date) -> None:
    load_env()

    master_infos = fetch_master_info()
    spy_prices_df = fetch_price_history("SPY", target - timedelta(days=180), target)
    spy_prices = spy_prices_df["adj_close"].fillna(spy_prices_df["close"])
    spy_prices.index = spy_prices_df["price_date"]

    computed_metrics: Dict[str, Dict[str, Optional[float]]] = {}
    for ticker in US_STOCKS:
        if ticker == "SPY":
            continue
        info = master_infos.get(ticker)
        if info is None:
            continue
        metric = compute_metrics_for_ticker(ticker, target, spy_prices, info)
        if metric:
            computed_metrics[ticker] = {field: metric[field] for field in METRIC_FIELDS}

    db_metrics = fetch_db_metrics(target)
    metric_diffs = diff_records(computed_metrics, db_metrics, METRIC_FIELDS, tolerance=1e-3)
    summarize_diffs("stock_metrics_daily", metric_diffs)

    growth_map = fetch_financial_growth(computed_metrics.keys())
    stats = fetch_metric_table_stats()

    computed_scores: Dict[str, Dict[str, Optional[float]]] = {}
    for ticker, metric in computed_metrics.items():
        info = master_infos.get(ticker)
        if info is None:
            continue
        score = compute_scores_for_ticker(ticker, {"metric_date": target, **metric}, info, growth_map.get(ticker), stats)
        computed_scores[ticker] = {field: score[field] for field in SCORE_FIELDS}

    db_scores = fetch_db_scores(target)
    score_diffs = diff_records(computed_scores, db_scores, SCORE_FIELDS, tolerance=1e-2)
    summarize_diffs("stock_scores_daily", score_diffs)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Recalculate metrics/scores and compare with DB")
    parser.add_argument("--date", help="대상 날짜 (YYYY-MM-DD)", default="2025-11-04")
    args = parser.parse_args()
    target_date = date.fromisoformat(args.date)
    main(target_date)


