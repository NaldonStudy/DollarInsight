"""일일 데이터 수집 후 JSON으로 저장하는 파이프라인."""

from __future__ import annotations

import datetime as dt
import json
import math
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Optional

import os
import pandas as pd
import yfinance as yf
from fredapi import Fred

from .env_loader import load_env
from .kis_client import KISClient, KISClientError, default_client
from .watchlists import FRED_DAILY_SERIES, US_ETFS, US_INDICES, US_STOCKS, YF_MACRO_SERIES


ROOT_DIR = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT_DIR / "pipelines" / "output"
ICON_CODES_PATH = ROOT_DIR / "pipelines" / "resources" / "icon_stock_codes.json"


def _safe_float(value: Optional[str | float | int]) -> Optional[float]:
    if value in (None, "", " "):
        return None
    try:
        number = float(value)
    except (TypeError, ValueError):
        return None
    if math.isnan(number) or math.isinf(number):
        return None
    return number


def _safe_int(value: Optional[str | float | int]) -> Optional[int]:
    if value in (None, "", " "):
        return None
    try:
        if isinstance(value, (float, int)):
            return int(value)
        return int(float(value.replace(",", ""))) if isinstance(value, str) else int(value)
    except (TypeError, ValueError, AttributeError):
        return None


def _sign_symbol(code: Optional[str]) -> Optional[str]:
    mapping = {
        "1": "+",
        "2": "+",
        "3": "0",
        "4": "-",
        "5": "-",
        "+": "+",
        "-": "-",
        "0": "0",
    }
    if code is None:
        return None
    return mapping.get(str(code).strip(), None)


def _load_icon_codes() -> dict[str, dict[str, str]]:
    cache_path = ICON_CODES_PATH
    if not cache_path.exists():
        return {}
    return json.loads(cache_path.read_text(encoding="utf-8"))


ICON_CODES = _load_icon_codes()


def _ticker_exchange(ticker: str) -> Optional[str]:
    info = ICON_CODES.get(ticker.upper())
    return info.get("exchange") if info else None


def _remove_none(data: dict) -> dict:
    return {key: value for key, value in data.items() if value is not None}


def _build_stock_record(ticker: str, row: dict, created_at: str) -> dict:
    return _remove_none(
        {
        "price_date": row["date"],
        "ticker": ticker,
        "open": row["open"],
        "high": row["high"],
        "low": row["low"],
        "close": row["close"],
        "adj_close": row["adj_close"],
        "volume": row["volume"],
        "amount": row["amount"],
        "change": row["change"],
        "change_pct": row["change_pct"],
        "change_sign": row["change_sign"],
        "bid": row["bid"],
        "ask": row["ask"],
        "bid_size": row["bid_size"],
        "ask_size": row["ask_size"],
        "source_vendor": row.get("source_vendor", "KIS"),
        "created_at": created_at,
        }
    )


def _query_kis_dailyprice(
    client: KISClient,
    *,
    ticker: str,
    exchange: str,
    date: dt.date,
) -> Optional[dict]:
    params = {
        "AUTH": "",
        "EXCD": exchange,
        "SYMB": ticker,
        "GUBN": "0",
        "BYMD": date.strftime("%Y%m%d"),
        "MODP": "1",
    }
    data = client.request(
        "GET",
        "/uapi/overseas-price/v1/quotations/dailyprice",
        tr_id="HHDFS76240000",
        params=params,
    )
    rows = data.get("output2") or []
    if isinstance(rows, dict):
        rows = [rows]
    target_row = None
    for row in rows:
        if row.get("xymd") == date.strftime("%Y%m%d"):
            target_row = row
            break
    if not target_row:
        return None
    prev_row = None
    for row in rows:
        if row.get("xymd") == (date - dt.timedelta(days=1)).strftime("%Y%m%d"):
            prev_row = row
            break

    close = _safe_float(target_row.get("clos"))
    prev_close = _safe_float(target_row.get("prpr")) or (
        _safe_float(prev_row.get("clos")) if prev_row else None
    )
    change = _safe_float(target_row.get("diff"))
    if change is None and close is not None and prev_close is not None:
        change = close - prev_close
    change_pct = _safe_float(target_row.get("rate"))
    if change_pct is None and change is not None and prev_close not in (None, 0):
        change_pct = (change / prev_close) * 100

    volume = _safe_int(target_row.get("tvol"))
    amount = _safe_float(target_row.get("tamt"))
    if amount is None and close is not None and volume is not None:
        amount = round(close * volume, 2)

    record = {
        "date": date.isoformat(),
        "open": _safe_float(target_row.get("open")),
        "high": _safe_float(target_row.get("high")),
        "low": _safe_float(target_row.get("low")),
        "close": close,
        "adj_close": close,
        "volume": volume,
        "amount": amount,
        "change": change,
        "change_pct": change_pct,
        "change_sign": _sign_symbol(target_row.get("sign")),
        "bid": _safe_float(target_row.get("pbid")),
        "ask": _safe_float(target_row.get("pask")),
        "bid_size": _safe_int(target_row.get("vbid")),
        "ask_size": _safe_int(target_row.get("vask")),
        "source_vendor": "KIS",
    }
    return record


def _query_yf_dailyprice(ticker: str, date: dt.date) -> Optional[dict]:
    yf_ticker = yf.Ticker(ticker)
    history = yf_ticker.history(
        start=date - dt.timedelta(days=10),
        end=date + dt.timedelta(days=2),
        auto_adjust=False,
    )
    if history.empty:
        return None
    row = history.loc[history.index.date == date]
    if row.empty:
        return None
    row = row.iloc[0]
    prev_close = None
    if len(history) > 1:
        # pick previous trading day
        prev_idx = history.index[history.index.date < date]
        if len(prev_idx) > 0:
            prev_close = float(history.loc[prev_idx[-1], "Close"])
    close = float(row["Close"])
    change = close - prev_close if prev_close is not None else None
    change_pct = (change / prev_close * 100) if change is not None and prev_close else None
    amount = close * float(row["Volume"])
    return {
        "date": date.isoformat(),
        "open": float(row["Open"]),
        "high": float(row["High"]),
        "low": float(row["Low"]),
        "close": close,
        "adj_close": float(row.get("Adj Close", close)),
        "volume": int(row["Volume"]),
        "amount": round(amount, 2),
        "change": change,
        "change_pct": change_pct,
        "change_sign": _sign_symbol("+" if change and change > 0 else "-" if change and change < 0 else "0"),
        "bid": None,
        "ask": None,
        "bid_size": None,
        "ask_size": None,
        "source_vendor": "yfinance",
    }


def collect_stock_prices(
    *,
    date: dt.date,
    tickers: Iterable[str] = US_STOCKS,
    client: Optional[KISClient] = None,
) -> list[dict]:
    created_at = dt.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"
    records: list[dict] = []
    client = client or default_client()
    for ticker in sorted(set(tickers)):
        exchange = _ticker_exchange(ticker)
        record = None
        if exchange:
            try:
                record = _query_kis_dailyprice(client, ticker=ticker, exchange=exchange, date=date)
            except KISClientError:
                record = None
        if record is None:
            record = _query_yf_dailyprice(ticker, date)
        if record is None:
            continue
        records.append(_build_stock_record(ticker, record, created_at))
    return records


def collect_etf_prices(
    *,
    date: dt.date,
    tickers: Iterable[str] = US_ETFS,
    client: Optional[KISClient] = None,
) -> list[dict]:
    created_at = dt.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"
    records: list[dict] = []
    client = client or default_client()
    for ticker in sorted(set(tickers)):
        exchange = _ticker_exchange(ticker)
        record = None
        if exchange:
            try:
                record = _query_kis_dailyprice(client, ticker=ticker, exchange=exchange, date=date)
            except KISClientError:
                record = None
        if record is None:
            record = _query_yf_dailyprice(ticker, date)
        if record is None:
            continue
        payload = _remove_none(
            {
            "price_date": record["date"],
            "ticker": ticker,
            "open": record["open"],
            "high": record["high"],
            "low": record["low"],
            "close": record["close"],
            "adj_close": record["adj_close"],
            "volume": record["volume"],
            "amount": record["amount"],
            "change": record["change"],
            "change_pct": record["change_pct"],
            "change_sign": record["change_sign"],
            "source_vendor": record.get("source_vendor", "KIS"),
            "created_at": created_at,
        }
        )
        records.append(payload)
    return records


def _query_kis_index(
    client: KISClient,
    *,
    ticker: str,
    date: dt.date,
    market_code: str = "U",
) -> Optional[dict]:
    tried: list[str] = []
    for code in [market_code, "U", "N"]:
        if code in tried:
            continue
        tried.append(code)
        params = {
            "FID_COND_MRKT_DIV_CODE": code,
            "FID_INPUT_ISCD": ticker,
            "FID_INPUT_DATE_1": (date - dt.timedelta(days=30)).strftime("%Y%m%d"),
            "FID_INPUT_DATE_2": date.strftime("%Y%m%d"),
            "FID_PERIOD_DIV_CODE": "D",
        }
        try:
            data = client.request(
                "GET",
                "/uapi/overseas-price/v1/quotations/inquire-daily-chartprice",
                tr_id="FHKST03030100",
                params=params,
            )
        except KISClientError:
            continue

        rows = data.get("output2") or data.get("output1") or []
        if isinstance(rows, dict):
            rows = [rows]
        if not rows:
            continue

        target_idx = None
        for idx, row in enumerate(rows):
            if row.get("stck_bsop_date") == date.strftime("%Y%m%d"):
                target_idx = idx
                break
        if target_idx is None:
            continue

        row = rows[target_idx]
        prev_row = rows[target_idx + 1] if target_idx + 1 < len(rows) else None
        close = _safe_float(row.get("ovrs_nmix_prpr"))
        prev_close = _safe_float(row.get("prdy_prpr")) or (
            _safe_float(prev_row.get("ovrs_nmix_prpr")) if prev_row else None
        )
        change = close - prev_close if close is not None and prev_close is not None else None
        change_pct = (change / prev_close * 100) if change not in (None, 0) and prev_close else None
        return _remove_none(
            {
                "price_date": date.isoformat(),
                "ticker": ticker,
                "close": close,
                "change_pct": change_pct,
                "change": change,
                "source_vendor": "KIS",
            }
        )
    return None


def _query_yf_index(
    *,
    ticker: str,
    yf_symbol: str,
    date: dt.date,
) -> Optional[dict]:
    record = _query_yf_dailyprice(yf_symbol, date)
    if record is None:
        return None
    return _remove_none(
        {
            "price_date": record["date"],
            "ticker": ticker,
            "close": record.get("close"),
            "change": record.get("change"),
            "change_pct": record.get("change_pct"),
            "source_vendor": record.get("source_vendor", "yfinance"),
        }
    )


def collect_index_prices(
    *,
    date: dt.date,
    indices: dict[str, dict[str, str]] = US_INDICES,
    client: Optional[KISClient] = None,
) -> list[dict]:
    created_at = dt.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"
    records: list[dict] = []
    client = client or default_client()
    for ticker, meta in sorted(indices.items()):
        try:
            record = _query_kis_index(
                client,
                ticker=ticker,
                date=date,
                market_code=meta.get("market", "U"),
            )
        except KISClientError:
            record = None
        if record is None:
            yf_symbol = meta.get("yf_symbol")
            if yf_symbol:
                record = _query_yf_index(ticker=ticker, yf_symbol=yf_symbol, date=date)
        if record is None:
            continue
        record["created_at"] = created_at
        records.append(record)
    return records


def collect_fred_daily(*, date: dt.date) -> list[dict]:
    load_env()
    api_key = os.getenv("FRED_API_KEY")
    fred = Fred(api_key=api_key)
    start = date - dt.timedelta(days=400)
    records: list[dict] = []
    for series_id, meta in FRED_DAILY_SERIES.items():
        series = fred.get_series(
            series_id,
            observation_start=start,
            observation_end=date + dt.timedelta(days=1),
        )
        if series is None or series.empty:
            continue
        cleaned = {
            idx.date(): float(val)
            for idx, val in series.dropna().items()
            if not (isinstance(val, float) and math.isnan(val))
        }
        value = cleaned.get(date)
        if value is None:
            continue
        previous_dates = [d for d in cleaned.keys() if d < date]
        prev_value = cleaned[max(previous_dates)] if previous_dates else None
        change_abs = value - prev_value if prev_value is not None else None
        change_mom = ((value - prev_value) / prev_value * 100) if prev_value not in (None, 0) else None
        change_yoy = None
        year_ago = date - dt.timedelta(days=365)
        for offset in range(0, 7):
            candidate = year_ago - dt.timedelta(days=offset)
            year_value = cleaned.get(candidate)
            if year_value not in (None, 0):
                change_yoy = ((value - year_value) / year_value) * 100
                break
        if change_abs is not None:
            change_abs = round(change_abs, 4)
        if change_mom is not None:
            change_mom = round(change_mom, 4)
        if change_yoy is not None:
            change_yoy = round(change_yoy, 4)
        records.append(
            _remove_none(
                {
                    "indicator_code": series_id,
                    "date": date.isoformat(),
                    "value": value,
                    "change": change_abs,
                    "change_mom": change_mom,
                    "change_yoy": change_yoy,
                    "unit": meta.get("unit"),
                    "seasonal_adjustment": meta.get("seasonal_adjustment"),
                    "source_vendor": "FRED",
                }
            )
        )
    return records


def _scale_value(value: float | None, meta: dict) -> float | None:
    if value is None:
        return None
    if "scale" in meta:
        return float(value) * float(meta["scale"])
    if meta.get("auto_scale_percent") and abs(value) > 20:
        return float(value) * 0.1
    return float(value)


def _extract_history_value(series: pd.Series, date: dt.date) -> tuple[float | None, float | None]:
    if series is None or series.empty:
        return None, None
    series = series[~series.index.duplicated(keep="last")]
    target_rows = series[series.index.date == date]
    if target_rows.empty:
        return None, None
    value = float(target_rows.iloc[0])
    prior_idx = series.index[series.index < target_rows.index[0]]
    prev_value = float(series.loc[prior_idx[-1]]) if len(prior_idx) else None
    return value, prev_value


def collect_yfinance_macro(*, date: dt.date) -> list[dict]:
    if not YF_MACRO_SERIES:
        return []
    history_cache: dict[str, pd.Series] = {}

    def fetch_series(symbol: str) -> pd.Series:
        if symbol in history_cache:
            return history_cache[symbol]
        ticker = yf.Ticker(symbol)
        history = ticker.history(
            start=date - dt.timedelta(days=30),
            end=date + dt.timedelta(days=2),
            auto_adjust=False,
        )
        if history.empty:
            series = pd.Series(dtype=float)
        else:
            series = history["Close"]
        history_cache[symbol] = series
        return series

    records: list[dict] = []
    for indicator_code, meta in YF_MACRO_SERIES.items():
        value = None
        prev_value = None

        if "symbol" in meta:
            series = fetch_series(meta["symbol"])
            value_raw, prev_raw = _extract_history_value(series, date)
            value = _scale_value(value_raw, meta)
            prev_value = _scale_value(prev_raw, meta)
        elif "components" in meta:
            component_values: list[float | None] = []
            component_prev: list[float | None] = []
            for component in meta.get("components", []):
                series = fetch_series(component["symbol"])
                value_raw, prev_raw = _extract_history_value(series, date)
                component_values.append(_scale_value(value_raw, component))
                component_prev.append(_scale_value(prev_raw, component))
            if all(val is not None for val in component_values):
                operation = meta.get("operation", "diff")
                if operation == "ratio":
                    value = (
                        component_values[0] / component_values[1]
                        if component_values[1] not in (None, 0)
                        else None
                    )
                    prev_value = (
                        component_prev[0] / component_prev[1]
                        if component_prev[1] not in (None, 0)
                        else None
                    )
                else:
                    value = component_values[0] - component_values[1]
                    if all(prev is not None for prev in component_prev):
                        prev_value = component_prev[0] - component_prev[1]
        if value is None:
            continue
        change_abs = value - prev_value if prev_value is not None else None
        change_pct = (
            (change_abs / prev_value) * 100
            if change_abs is not None and prev_value not in (None, 0)
            else None
        )
        record = {
            "indicator_code": indicator_code,
            "date": date.isoformat(),
            "value": round(float(value), 6),
            "unit": meta.get("unit"),
            "change": round(float(change_abs), 6) if change_abs is not None else None,
            "change_mom": round(float(change_pct), 6) if change_pct is not None else None,
            "source": meta.get("source", "YFINANCE"),
            "source_vendor": meta.get("source_vendor", "YFINANCE"),
        }
        records.append(_remove_none(record))
    return records


@dataclass
class DailyJsonResult:
    stock_price_daily: list[dict]
    etf_price_daily: list[dict]
    index_price_daily: list[dict]
    macro_economic_indicators: list[dict]


def collect_all(date: dt.date) -> DailyJsonResult:
    load_env()
    client = default_client()
    macro_records = collect_fred_daily(date=date)
    yf_macro = collect_yfinance_macro(date=date)
    fred_codes = {record["indicator_code"] for record in macro_records if "indicator_code" in record}
    macro_records.extend(record for record in yf_macro if record.get("indicator_code") not in fred_codes)

    return DailyJsonResult(
        stock_price_daily=collect_stock_prices(date=date, client=client),
        etf_price_daily=collect_etf_prices(date=date, client=client),
        index_price_daily=collect_index_prices(date=date, client=client),
        macro_economic_indicators=macro_records,
    )


def write_json(data: list[dict], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2, default=str)


def export_daily_json(date: dt.date, *, output_dir: Path | None = None) -> DailyJsonResult:
    result = collect_all(date)
    target_dir = output_dir or (DATA_DIR / date.strftime("%Y%m%d"))
    write_json(result.stock_price_daily, target_dir / "stock_price_daily.json")
    write_json(result.etf_price_daily, target_dir / "etf_price_daily.json")
    write_json(result.index_price_daily, target_dir / "index_price_daily.json")
    write_json(result.macro_economic_indicators, target_dir / "macro_economic_indicators.json")
    return result


def _parse_args():
    import argparse

    parser = argparse.ArgumentParser(description="Collect daily market data and export as JSON.")
    parser.add_argument("--date", help="수집 기준일 (YYYY-MM-DD). 미지정 시 전일.")
    parser.add_argument(
        "--output",
        help="출력 디렉터리. 기본값은 pipelines/output/<date>.",
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = _parse_args()
    target_date = (
        dt.datetime.strptime(args.date, "%Y-%m-%d").date()
        if args.date
        else dt.date.today() - dt.timedelta(days=1)
    )
    output_dir = Path(args.output).resolve() if args.output else None
    export_daily_json(target_date, output_dir=output_dir)


