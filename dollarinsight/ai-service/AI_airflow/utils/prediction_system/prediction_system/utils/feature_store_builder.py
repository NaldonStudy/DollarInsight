"""Feature store 통합 빌더."""

from __future__ import annotations

import datetime as dt
import os
from pathlib import Path
from typing import Iterable

import numpy as np
import pandas as pd

from .financial_dao import fetch_financials
from .index_etf_dao import fetch_index_prices
from .macro_dao import fetch_macro_series
from .stock_price_dao import fetch_prices
from .feature_store_cache import load_feature_store, save_feature_store

_MIN_HISTORY_DAYS = 260  # 1년 이상 데이터가 필요한 피처 대응
_BENCHMARK_INDEX = ".SPX"  # index_price_daily 기준 S&P 500 심볼
_BENCHMARK_ETF = "SPY"

_DEFAULT_FEATURE_DIR = Path(
    os.getenv(
        "FEATURE_STORE_DIR",
        Path(__file__).resolve().parents[1] / "artifacts" / "feature_store",
    )
)

_MACRO_SERIES = {
    "CPIAUCSL": "macro_cpi",
    "UNRATE": "macro_unemployment",
    "DGS10": "macro_treasury10y",
    "DGS2": "macro_treasury2y",
    "FEDFUNDS": "macro_fedfunds",
    "DEXCHUS": "macro_dxy",
    "DEXUSEU": "macro_eurusd",
    "DCOILWTICO": "macro_wti",
    "VIXCLS": "macro_vix",
    "GDP": "macro_gdp",
}


def _ema(series: pd.Series, span: int) -> pd.Series:
    return series.ewm(span=span, adjust=False, min_periods=span).mean()


def _rsi(series: pd.Series, period: int = 14) -> pd.Series:
    delta = series.diff()
    up = delta.clip(lower=0)
    down = -delta.clip(upper=0)
    roll_up = up.ewm(alpha=1 / period, adjust=False, min_periods=period).mean()
    roll_down = down.ewm(alpha=1 / period, adjust=False, min_periods=period).mean()
    rs = roll_up / roll_down
    return 100 - (100 / (1 + rs))


def _stochastic(high: pd.Series, low: pd.Series, close: pd.Series, period: int = 14) -> tuple[pd.Series, pd.Series]:
    lowest_low = low.rolling(window=period, min_periods=period).min()
    highest_high = high.rolling(window=period, min_periods=period).max()
    k = 100 * (close - lowest_low) / (highest_high - lowest_low)
    d = k.rolling(window=3, min_periods=3).mean()
    return k, d


def _true_range(high: pd.Series, low: pd.Series, close: pd.Series) -> pd.Series:
    prev_close = close.shift(1)
    tr_components = pd.concat(
        [
            high - low,
            (high - prev_close).abs(),
            (low - prev_close).abs(),
        ],
        axis=1,
    )
    return tr_components.max(axis=1)


def _atr(high: pd.Series, low: pd.Series, close: pd.Series, period: int = 14) -> pd.Series:
    tr = _true_range(high, low, close)
    return tr.ewm(alpha=1 / period, adjust=False, min_periods=period).mean()


def _adx(high: pd.Series, low: pd.Series, close: pd.Series, period: int = 14) -> pd.Series:
    plus_dm = (high.diff()).where((high.diff() > low.diff()) & (high.diff() > 0), 0.0)
    minus_dm = (-low.diff()).where((low.diff() < high.diff()) & (low.diff() > 0), 0.0)
    atr = _atr(high, low, close, period)

    plus_di = 100 * (plus_dm.ewm(alpha=1 / period, adjust=False, min_periods=period).mean() / atr)
    minus_di = 100 * (minus_dm.ewm(alpha=1 / period, adjust=False, min_periods=period).mean() / atr)
    dx = (plus_di - minus_di).abs() / (plus_di + minus_di)
    adx = (100 * dx).ewm(alpha=1 / period, adjust=False, min_periods=period).mean()
    return adx


def _obv(close: pd.Series, volume: pd.Series) -> pd.Series:
    direction = np.sign(close.diff()).fillna(0)
    return (volume * direction).fillna(0).cumsum()


def _chaikin_money_flow(high: pd.Series, low: pd.Series, close: pd.Series, volume: pd.Series, period: int = 20) -> pd.Series:
    denominator = (high - low).replace(0, np.nan)
    mf_multiplier = ((close - low) - (high - close)) / denominator
    mf_volume = (mf_multiplier.fillna(0)) * volume
    return mf_volume.rolling(window=period, min_periods=period).sum() / volume.rolling(window=period, min_periods=period).sum()


def _vpt(close: pd.Series, volume: pd.Series) -> pd.Series:
    return ((close.pct_change().fillna(0)) * volume).cumsum()


def _bollinger_band_width(close: pd.Series, window: int = 20, num_std: float = 2.0) -> pd.Series:
    ma = close.rolling(window, min_periods=window).mean()
    std = close.rolling(window, min_periods=window).std()
    upper = ma + num_std * std
    lower = ma - num_std * std
    width = (upper - lower) / ma.replace(0, np.nan)
    return width


def _gap_ratio(open_: pd.Series, prev_close: pd.Series) -> pd.Series:
    return (open_ - prev_close) / prev_close.replace(0, np.nan)


def _ichimoku(close: pd.Series, high: pd.Series, low: pd.Series) -> pd.DataFrame:
    conversion = (high.rolling(9).max() + low.rolling(9).min()) / 2
    base = (high.rolling(26).max() + low.rolling(26).min()) / 2
    span_a = (conversion + base) / 2
    span_b = (high.rolling(52).max() + low.rolling(52).min()) / 2
    ichimoku_df = pd.DataFrame(
        {
            "ichimoku_conversion": conversion,
            "ichimoku_base": base,
            "ichimoku_span_a": span_a.shift(26),
            "ichimoku_span_b": span_b.shift(26),
        }
    )
    return ichimoku_df


def _rolling_beta(returns: pd.Series, benchmark_returns: pd.Series, window: int = 60) -> pd.Series:
    cov = returns.rolling(window, min_periods=window).cov(benchmark_returns)
    var = benchmark_returns.rolling(window, min_periods=window).var()
    beta = cov / var.replace(0, np.nan)
    return beta


def _collect_macro_features(
    start: dt.date,
    end: dt.date,
    feature_dates: pd.DatetimeIndex,
) -> pd.DataFrame:
    try:
        macro_df = fetch_macro_series(_MACRO_SERIES.keys(), start, end)
    except Exception:  # pragma: no cover
        return pd.DataFrame(index=feature_dates)

    if macro_df.empty:
        return pd.DataFrame(index=feature_dates)

    macro_df = macro_df.copy()
    macro_df["date"] = pd.to_datetime(macro_df["date"], errors="coerce")
    macro_df.dropna(subset=["date"], inplace=True)
    macro_df.sort_values("date", inplace=True)

    pivot = macro_df.pivot(index="date", columns="indicator_code", values="value")
    full_range = pd.date_range(start, end, freq="D")
    pivot = pivot.reindex(full_range).ffill()

    features = pd.DataFrame(index=pivot.index)
    for code, prefix in _MACRO_SERIES.items():
        if code not in pivot.columns:
            continue
        series = pd.to_numeric(pivot[code], errors="coerce")
        features[f"{prefix}_value"] = series
        for period, suffix in [(21, "1m"), (63, "3m"), (252, "12m")]:
            pct = series.pct_change(periods=period)
            features[f"{prefix}_chg_{suffix}"] = pct.replace([np.inf, -np.inf], np.nan)
        rolling_mean = series.rolling(252, min_periods=63).mean()
        rolling_std = series.rolling(252, min_periods=63).std()
        zscore = (series - rolling_mean) / rolling_std.replace(0, np.nan)
        features[f"{prefix}_zscore"] = zscore

    feature_dates = pd.DatetimeIndex(sorted(set(pd.to_datetime(feature_dates))))
    features = features.reindex(feature_dates).ffill()
    features.replace([np.inf, -np.inf], np.nan, inplace=True)
    return features


def _collect_financial_features(ticker: str, feature_index: pd.DatetimeIndex) -> pd.DataFrame:
    try:
        fin_df = fetch_financials(ticker, "1900-01-01")
    except Exception:  # pragma: no cover - DB 예외시 피처 없음 처리
        return pd.DataFrame(index=feature_index)

    if fin_df.empty:
        return pd.DataFrame(index=feature_index)

    fin_df = fin_df.copy()
    fin_df["period"] = pd.to_datetime(fin_df["period"], errors="coerce")
    fin_df.dropna(subset=["period"], inplace=True)
    fin_df.sort_values("period", inplace=True)
    fin_df.set_index("period", inplace=True)

    numeric_cols = [
        "revenue",
        "net_income",
        "operating_income",
        "total_assets",
        "total_liabilities",
        "total_equity",
        "ebitda",
    ]
    for col in numeric_cols:
        if col in fin_df.columns:
            fin_df[col] = pd.to_numeric(fin_df[col], errors="coerce")

    features = pd.DataFrame(index=feature_index)
    if "revenue" in fin_df.columns:
        revenue = fin_df["revenue"].replace(0, np.nan)
        features["revenue_growth_yoy"] = revenue.pct_change(periods=4).reindex(feature_index, method="ffill")
    if {"net_income", "revenue"}.issubset(fin_df.columns):
        margin = (fin_df["net_income"] / fin_df["revenue"].replace(0, np.nan)).clip(-10, 10)
        features["net_income_margin"] = margin.reindex(feature_index, method="ffill")
    if {"total_liabilities", "total_equity"}.issubset(fin_df.columns):
        d_to_e = (fin_df["total_liabilities"] / fin_df["total_equity"].replace(0, np.nan)).clip(-10, 10)
        features["debt_to_equity_ratio"] = d_to_e.reindex(feature_index, method="ffill")
    if {"net_income", "total_equity"}.issubset(fin_df.columns):
        roe = (fin_df["net_income"] / fin_df["total_equity"].replace(0, np.nan)).clip(-10, 10)
        features["roe_financial"] = roe.reindex(feature_index, method="ffill")

    features.fillna(method="ffill", inplace=True)
    features.fillna(0.0, inplace=True)
    return features


def _fetch_benchmark_series(
    start: dt.date,
    end: dt.date,
) -> tuple[pd.Series, pd.Series]:
    """S&P 지수와 SPY ETF 종가 시계열을 반환한다."""

    index_df = fetch_index_prices([_BENCHMARK_INDEX], start, end)
    if index_df.empty:
        index_series = pd.Series(dtype=float)
    else:
        index_series = (
            index_df[index_df["ticker"] == _BENCHMARK_INDEX]
            .sort_values("price_date")
            .set_index("price_date")["close"]
            .astype(float)
        )

    spy_df = fetch_prices([_BENCHMARK_ETF], start, end)
    if spy_df.empty:
        spy_series = pd.Series(dtype=float)
    else:
        spy_series = (
            spy_df[spy_df["ticker"] == _BENCHMARK_ETF]
            .sort_values("price_date")
            .set_index("price_date")["close"]
            .astype(float)
        )
    return index_series, spy_series


def build_feature_store(
    date_range: tuple[dt.date, dt.date],
    universe: Iterable[str],
) -> pd.DataFrame:
    """지정한 범위의 종목들에 대한 통합 feature DataFrame을 생성한다."""

    start, end = date_range
    padded_start = start - dt.timedelta(days=_MIN_HISTORY_DAYS)

    cached = load_feature_store((padded_start, end))
    if cached is not None:
        cached = cached[(cached.index.get_level_values("feature_date") >= pd.to_datetime(start))]
        return cached

    price_df = fetch_prices(universe, padded_start, end)
    if price_df.empty:
        return pd.DataFrame()

    price_df["price_date"] = pd.to_datetime(price_df["price_date"])
    price_df.sort_values(["ticker", "price_date"], inplace=True)

    index_series, spy_series = _fetch_benchmark_series(padded_start, end)

    feature_frames: list[pd.DataFrame] = []
    for ticker, group in price_df.groupby("ticker", sort=False):
        g = group.set_index("price_date").sort_index()
        close = g["close"].astype(float)
        volume = g["volume"].astype(float)
        high = g.get("high", close).astype(float)
        low = g.get("low", close).astype(float)
        open_ = g.get("open", close).astype(float)

        features = pd.DataFrame(index=g.index)
        features["close"] = close
        features["return_1d"] = close.pct_change()
        features["return_2d"] = close.pct_change(2)
        features["return_3d"] = close.pct_change(3)
        features["return_5d"] = close.pct_change(5)
        features["return_20d"] = close.pct_change(20)
        features["return_60d"] = close.pct_change(60)
        features["return_120d"] = close.pct_change(120)
        features["return_252d"] = close.pct_change(252)

        features["ma_5"] = close.rolling(5, min_periods=1).mean()
        features["ma_20"] = close.rolling(20, min_periods=1).mean()
        features["ma_50"] = close.rolling(50, min_periods=1).mean()
        features["ma_60"] = close.rolling(60, min_periods=1).mean()
        features["ma_100"] = close.rolling(100, min_periods=20).mean()
        features["ma_200"] = close.rolling(200, min_periods=40).mean()
        features["ema_12"] = _ema(close, 12)
        features["ema_26"] = _ema(close, 26)
        features["ma_ratio_5_20"] = features["ma_5"] / features["ma_20"].replace(0, np.nan)
        features["ma_ratio_20_60"] = features["ma_20"] / features["ma_60"].replace(0, np.nan)
        features["price_to_ma50"] = close / features["ma_50"].replace(0, np.nan) - 1
        features["price_to_ma200"] = close / features["ma_200"].replace(0, np.nan) - 1
        features["ma50_slope_5d"] = features["ma_50"] - features["ma_50"].shift(5)
        features["ma200_slope_5d"] = features["ma_200"] - features["ma_200"].shift(5)

        features["rsi_14"] = _rsi(close)
        stoch_k, stoch_d = _stochastic(high, low, close)
        features["stoch_k_14"] = stoch_k
        features["stoch_d_3"] = stoch_d

        macd = features["ema_12"] - features["ema_26"]
        macd_signal = _ema(macd, 9)
        features["macd"] = macd
        features["macd_signal"] = macd_signal
        features["macd_hist"] = macd - macd_signal

        features["intraday_range"] = (high - low) / close.replace(0, np.nan)
        features["close_vs_high"] = (close - high) / high.replace(0, np.nan)
        features["close_vs_low"] = (close - low) / low.replace(0, np.nan)
        features["open_to_close_return"] = (close - open_) / open_.replace(0, np.nan)
        features["open_gap_ratio"] = _gap_ratio(open_, close.shift(1))
        features["gap_ratio"] = features["open_gap_ratio"]  # alias for backward compatibility

        features["true_range"] = _true_range(high, low, close)
        features["atr_14"] = _atr(high, low, close)
        features["adx_14"] = _adx(high, low, close)

        features["bollinger_width_20"] = _bollinger_band_width(close)

        returns = features["return_1d"].fillna(0.0)
        features["volatility_20"] = returns.rolling(20, min_periods=5).std()
        features["volatility_60"] = returns.rolling(60, min_periods=20).std()

        vol_mean_5 = volume.rolling(5, min_periods=2).mean()
        vol_mean_10 = volume.rolling(10, min_periods=3).mean()
        vol_mean_20 = volume.rolling(20, min_periods=5).mean()
        vol_std_20 = volume.rolling(20, min_periods=5).std()
        features["volume_ratio_5"] = volume / vol_mean_5.replace(0, np.nan)
        features["volume_ratio_10"] = volume / vol_mean_10.replace(0, np.nan)
        features["volume_zscore_20"] = (
            (volume - vol_mean_20)
            / vol_std_20.replace(0, np.nan)
        )
        features["volume_zscore_20"].replace([np.inf, -np.inf], np.nan, inplace=True)
        features["volume_zscore_20"].fillna(0.0, inplace=True)
        features["volume_ratio_20"] = volume / vol_mean_20.replace(0, np.nan)
        features["volume_ratio_50"] = volume / volume.rolling(50, min_periods=10).mean().replace(0, np.nan)
        features["volume_momentum_3d"] = volume.pct_change(3)
        features["volume_momentum_5d"] = volume.pct_change(5)

        features["obv"] = _obv(close, volume)
        features["obv_ma_10"] = features["obv"].rolling(10, min_periods=3).mean()
        features["cmf_20"] = _chaikin_money_flow(high, low, close, volume)
        features["vpt"] = _vpt(close, volume)

        rolling_high_252 = close.rolling(252, min_periods=60).max()
        rolling_low_252 = close.rolling(252, min_periods=60).min()
        features["close_to_52w_high"] = close / rolling_high_252.replace(0, np.nan)
        features["close_to_52w_low"] = close / rolling_low_252.replace(0, np.nan)
        features["position_52w"] = (close - rolling_low_252) / (rolling_high_252 - rolling_low_252).replace(0, np.nan)
        features["bandwidth_52w"] = (rolling_high_252 - rolling_low_252) / rolling_low_252.replace(0, np.nan)
        features["breakout_52w"] = (close >= rolling_high_252).astype(float)

        ichimoku_df = _ichimoku(close, high, low)
        features = features.join(ichimoku_df, how="left")

        if not spy_series.empty:
            spy_aligned = spy_series.reindex(features.index).astype(float)
            bench_returns = spy_aligned.pct_change()
            features["relative_return_spy_20"] = features["return_20d"] - spy_aligned.pct_change(20)
            features["beta_spy_60"] = _rolling_beta(features["return_1d"], bench_returns, 60)
        else:
            features["relative_return_spy_20"] = np.nan
            features["beta_spy_60"] = np.nan

        if not index_series.empty:
            index_aligned = index_series.reindex(features.index).astype(float)
            features["relative_strength_spx"] = close / index_aligned.replace(0, np.nan)
        else:
            features["relative_strength_spx"] = np.nan

        financial_features = _collect_financial_features(ticker, features.index)
        if not financial_features.empty:
            features = features.join(financial_features, how="left")

        features["ticker"] = ticker
        features.reset_index(inplace=True)
        features.rename(columns={"price_date": "feature_date"}, inplace=True)
        feature_frames.append(features)

    feature_df = pd.concat(feature_frames, ignore_index=True)
    feature_df["feature_date"] = pd.to_datetime(feature_df["feature_date"])
    feature_df = feature_df[feature_df["feature_date"] >= pd.to_datetime(start)]
    feature_df.set_index(["ticker", "feature_date"], inplace=True)
    feature_df.sort_index(inplace=True)
    feature_df.replace([np.inf, -np.inf], np.nan, inplace=True)

    if not feature_df.empty:
        with np.errstate(invalid="ignore"):
            feature_df["rs_rank_252"] = feature_df.groupby("feature_date")[
                "return_252d"
            ].rank(pct=True)

    macro_features = _collect_macro_features(
        padded_start,
        end,
        feature_df.index.get_level_values("feature_date"),
    )
    if not macro_features.empty:
        date_index = feature_df.index.get_level_values("feature_date")
        aligned = macro_features.reindex(date_index, method="ffill")
        for col in aligned.columns:
            feature_df[col] = aligned[col].values

    save_feature_store((padded_start, end), feature_df)
    return feature_df


def persist_feature_store(feature_df: pd.DataFrame) -> Path | None:
    """생성된 feature DataFrame을 Parquet 파일로 저장한다."""

    if feature_df.empty:
        return None

    _DEFAULT_FEATURE_DIR.mkdir(parents=True, exist_ok=True)
    feature_dates = feature_df.index.get_level_values("feature_date")
    start_date = feature_dates.min().strftime("%Y%m%d")
    end_date = feature_dates.max().strftime("%Y%m%d")
    target_path = _DEFAULT_FEATURE_DIR / f"features_{start_date}_{end_date}.parquet"
    feature_df.to_parquet(target_path)
    return target_path


