"""모델 학습 파이프라인 스텁."""

from __future__ import annotations

import datetime as dt
import os

import numpy as np
import pandas as pd

from pipelines.watchlists import METRIC_STOCKS

from .stock_price_dao import fetch_prices
from .feature_store_builder import build_feature_store
from .dataset_builder import build_datasets
from .feature_selector import FeatureSelectionResult, select_feature_columns
from .trainer import train_models
from .logger import get_logger
from .hyperparameter_tuner import tune_hyperparameters

logger = get_logger(__name__)

MIN_REQUIRED_LOOKBACK = 260
TUNING_TRIALS = int(os.getenv("PRED_TUNING_TRIALS", "25"))
ENABLE_TUNING = os.getenv("PRED_ENABLE_TUNING", "true").lower() not in {"0", "false", "no"}
CALIBRATION_RATIO = float(os.getenv("PRED_CALIBRATION_RATIO", "0.2"))
WALK_FORWARD_ENABLED = os.getenv("PRED_WALK_ENABLED", "true").lower() not in {"0", "false", "no"}
WALK_FORWARD_SPLITS = int(os.getenv("PRED_WALK_SPLITS", "3"))
WALK_FORWARD_VAL_RATIO = float(os.getenv("PRED_WALK_VALID_RATIO", "0.1"))
WALK_FORWARD_MIN_TRAIN = int(os.getenv("PRED_WALK_MIN_TRAIN", "1800"))
WALK_FORWARD_MIN_VALID = int(os.getenv("PRED_WALK_MIN_VALID", "360"))

BARRIER_CONFIG: dict[int, dict[str, float]] = {
    5: {
        "upper": float(os.getenv("PRED_BARRIER_UPPER_5D", "0.006")),
        "lower": float(os.getenv("PRED_BARRIER_LOWER_5D", "0.006")),
        "premium_upper": float(os.getenv("PRED_BARRIER_PREMIUM_5D", "0.01")),
        "mode": os.getenv("PRED_BARRIER_MODE_5D", os.getenv("PRED_BARRIER_MODE", "atr")).lower(),
        "atr_window": int(os.getenv("PRED_BARRIER_ATR_WINDOW_5D", os.getenv("PRED_BARRIER_ATR_WINDOW", "14"))),
        "atr_multiplier_upper": float(os.getenv("PRED_BARRIER_ATR_MULT_UP_5D", os.getenv("PRED_BARRIER_ATR_MULT_UP", "1.4"))),
        "atr_multiplier_lower": float(os.getenv("PRED_BARRIER_ATR_MULT_DOWN_5D", os.getenv("PRED_BARRIER_ATR_MULT_DOWN", "1.0"))),
        "upper_floor": float(os.getenv("PRED_BARRIER_UPPER_FLOOR_5D", "0.004")),
        "lower_floor": float(os.getenv("PRED_BARRIER_LOWER_FLOOR_5D", "0.004")),
        "premium_multiplier": float(os.getenv("PRED_BARRIER_PREMIUM_MULT_5D", os.getenv("PRED_BARRIER_PREMIUM_MULT", "1.5"))),
        "vol_window": int(os.getenv("PRED_BARRIER_VOL_WINDOW_5D", os.getenv("PRED_BARRIER_VOL_WINDOW", "20"))),
        "vol_multiplier_upper": float(os.getenv("PRED_BARRIER_VOL_MULT_UP_5D", os.getenv("PRED_BARRIER_VOL_MULT_UP", "2.0"))),
        "vol_multiplier_lower": float(os.getenv("PRED_BARRIER_VOL_MULT_DOWN_5D", os.getenv("PRED_BARRIER_VOL_MULT_DOWN", "1.5"))),
    },
    20: {
        "upper": float(os.getenv("PRED_BARRIER_UPPER_20D", "0.01")),
        "lower": float(os.getenv("PRED_BARRIER_LOWER_20D", "0.01")),
        "premium_upper": float(os.getenv("PRED_BARRIER_PREMIUM_20D", "0.015")),
        "mode": os.getenv("PRED_BARRIER_MODE_20D", os.getenv("PRED_BARRIER_MODE", "atr")).lower(),
        "atr_window": int(os.getenv("PRED_BARRIER_ATR_WINDOW_20D", os.getenv("PRED_BARRIER_ATR_WINDOW", "21"))),
        "atr_multiplier_upper": float(os.getenv("PRED_BARRIER_ATR_MULT_UP_20D", os.getenv("PRED_BARRIER_ATR_MULT_UP", "1.2"))),
        "atr_multiplier_lower": float(os.getenv("PRED_BARRIER_ATR_MULT_DOWN_20D", os.getenv("PRED_BARRIER_ATR_MULT_DOWN", "0.9"))),
        "upper_floor": float(os.getenv("PRED_BARRIER_UPPER_FLOOR_20D", "0.006")),
        "lower_floor": float(os.getenv("PRED_BARRIER_LOWER_FLOOR_20D", "0.006")),
        "premium_multiplier": float(os.getenv("PRED_BARRIER_PREMIUM_MULT_20D", os.getenv("PRED_BARRIER_PREMIUM_MULT", "1.4"))),
        "vol_window": int(os.getenv("PRED_BARRIER_VOL_WINDOW_20D", os.getenv("PRED_BARRIER_VOL_WINDOW", "40"))),
        "vol_multiplier_upper": float(os.getenv("PRED_BARRIER_VOL_MULT_UP_20D", os.getenv("PRED_BARRIER_VOL_MULT_UP", "1.8"))),
        "vol_multiplier_lower": float(os.getenv("PRED_BARRIER_VOL_MULT_DOWN_20D", os.getenv("PRED_BARRIER_VOL_MULT_DOWN", "1.2"))),
    },
}

_TASK_DEFINITIONS = {
    "regression_5d": {"type": "regression", "horizon": 5, "quantile": 0.9},
    "classification_5d": {"type": "classification", "horizon": 5},
    "regression_20d": {"type": "regression", "horizon": 20, "quantile": 0.9},
    "classification_20d": {"type": "classification", "horizon": 20},
}


def _calculate_atr(high: pd.Series, low: pd.Series, close: pd.Series, window: int) -> pd.Series:
    high_low = (high - low).abs()
    high_prev_close = (high - close.shift(1)).abs()
    low_prev_close = (low - close.shift(1)).abs()
    true_range = pd.concat([high_low, high_prev_close, low_prev_close], axis=1).max(axis=1)
    atr = true_range.rolling(window=window, min_periods=1).mean()
    return atr


def _calculate_volatility(close: pd.Series, window: int) -> pd.Series:
    returns = close.pct_change()
    return returns.rolling(window=window, min_periods=1).std()


def _resolve_threshold_value(series_or_value, idx: int, fallback: float) -> float:
    if isinstance(series_or_value, (pd.Series,)):
        val = series_or_value.iloc[idx]
    elif isinstance(series_or_value, (np.ndarray, list, tuple)):
        val = series_or_value[idx]
    else:
        val = series_or_value
    if val is None:
        return fallback
    try:
        if not np.isfinite(val):
            return fallback
    except TypeError:
        return fallback
    return float(val)


def _triple_barrier_labels(
    close: pd.Series,
    high: pd.Series,
    low: pd.Series,
    horizon: int,
    upper,
    lower,
    premium_upper = None,
) -> tuple[pd.Series, pd.Series | None]:
    direction = pd.Series(np.nan, index=close.index, dtype=float)
    premium = None
    if premium_upper is not None:
        premium = pd.Series(0.0, index=close.index, dtype=float)

    closes = close.to_numpy(dtype=float)
    highs = high.to_numpy(dtype=float)
    lows = low.to_numpy(dtype=float)

    n = len(close)
    for idx in range(n):
        start_price = closes[idx]
        if not np.isfinite(start_price):
            continue

        horizon_end = min(n, idx + horizon + 1)
        upper_ratio = _resolve_threshold_value(upper, idx, 0.0)
        lower_ratio = _resolve_threshold_value(lower, idx, 0.0)
        premium_ratio = _resolve_threshold_value(premium_upper, idx, upper_ratio) if premium is not None else None

        upper_ratio = max(upper_ratio, 0.0)
        lower_ratio = max(lower_ratio, 0.0)
        premium_ratio = max(premium_ratio, upper_ratio) if premium_ratio is not None else None

        upper_price = start_price * (1.0 + upper_ratio)
        lower_price = start_price * (1.0 - lower_ratio)
        premium_price = start_price * (1.0 + premium_ratio) if premium_ratio is not None else None

        upper_hit = None
        lower_hit = None
        premium_hit = False

        for step in range(idx + 1, horizon_end):
            if upper_hit is None and highs[step] >= upper_price:
                upper_hit = step
            if lower_hit is None and lows[step] <= lower_price:
                lower_hit = step
            if (
                premium is not None
                and premium_price is not None
                and not premium_hit
                and highs[step] >= premium_price
            ):
                premium_hit = True

            if upper_hit is not None and lower_hit is not None and (premium is None or premium_hit):
                # no need to continue scanning once both (and premium) resolved
                break

        label = np.nan
        if upper_hit is None and lower_hit is None:
            label = np.nan
        elif upper_hit is not None and (lower_hit is None or upper_hit < lower_hit):
            label = 1.0
        elif lower_hit is not None and (upper_hit is None or lower_hit < upper_hit):
            label = 0.0
        elif upper_hit == lower_hit:
            # 동일한 일자에 상/하단 모두 충족 → 당일 종가 방향으로 결정
            label = float(closes[upper_hit] >= start_price)
        direction.iloc[idx] = label

        if premium is not None:
            premium.iloc[idx] = 1.0 if premium_hit else 0.0

    return direction, premium


def _compute_targets(price_df: pd.DataFrame, horizons: list[int]) -> pd.DataFrame:
    price_df = price_df.copy()
    price_df["price_date"] = pd.to_datetime(price_df["price_date"])
    price_df.sort_values(["ticker", "price_date"], inplace=True)

    frames = []
    for ticker, group in price_df.groupby("ticker", sort=False):
        g = group.set_index("price_date").sort_index()
        base = pd.DataFrame(index=g.index)
        base["ticker"] = ticker
        close = g["close"].astype(float)
        high = g["high"].astype(float)
        low = g["low"].astype(float)
        for horizon in horizons:
            future_close = close.shift(-horizon)
            return_col = (future_close - close) / close
            base[f"target_return_{horizon}d"] = return_col
            barrier_cfg = BARRIER_CONFIG.get(horizon)
            if barrier_cfg:
                mode = barrier_cfg.get("mode", "fixed")
                upper_series = pd.Series(barrier_cfg.get("upper", 0.0), index=g.index, dtype=float)
                lower_series = pd.Series(barrier_cfg.get("lower", 0.0), index=g.index, dtype=float)
                premium_series = None

                if mode == "atr":
                    atr_window = int(barrier_cfg.get("atr_window", 14))
                    atr_series = _calculate_atr(high, low, close, atr_window)
                    atr_ratio = (atr_series / close.replace(0, np.nan)).replace([np.inf, -np.inf], np.nan)
                    atr_ratio = atr_ratio.fillna(barrier_cfg.get("upper", 0.0))
                    upper_series = atr_ratio * float(barrier_cfg.get("atr_multiplier_upper", 1.2))
                    lower_series = atr_ratio * float(barrier_cfg.get("atr_multiplier_lower", 1.0))
                elif mode == "vol":
                    vol_window = int(barrier_cfg.get("vol_window", 20))
                    vol_series = _calculate_volatility(close, vol_window).fillna(method="bfill").fillna(method="ffill")
                    upper_series = vol_series * float(barrier_cfg.get("vol_multiplier_upper", 2.0))
                    lower_series = vol_series * float(barrier_cfg.get("vol_multiplier_lower", 1.5))

                upper_floor = barrier_cfg.get("upper_floor")
                lower_floor = barrier_cfg.get("lower_floor")
                if upper_floor is not None:
                    upper_series = upper_series.clip(lower=float(upper_floor))
                if lower_floor is not None:
                    lower_series = lower_series.clip(lower=float(lower_floor))

                premium_base = barrier_cfg.get("premium_upper")
                if premium_base is not None:
                    premium_series = upper_series * float(barrier_cfg.get("premium_multiplier", 1.5))
                    premium_series = premium_series.clip(lower=float(premium_base))

                direction, premium = _triple_barrier_labels(
                    close,
                    high,
                    low,
                    horizon=horizon,
                    upper=upper_series.to_numpy(),
                    lower=lower_series.to_numpy(),
                    premium_upper=premium_series.to_numpy() if premium_series is not None else None,
                )
                base[f"target_direction_{horizon}d"] = direction
                if premium is not None:
                    base[f"target_premium_{horizon}d"] = premium
            else:
                threshold = float(os.getenv(f"PRED_CLASS_THRESH_{horizon}D", "0.0"))
                series = (return_col > threshold).astype(float)
                series[~np.isfinite(return_col)] = np.nan
                base[f"target_direction_{horizon}d"] = series
        frames.append(base.reset_index())
    target_df = pd.concat(frames, ignore_index=True)
    target_df.set_index(["ticker", "price_date"], inplace=True)
    return target_df


def _build_walk_forward_folds(
    sample_count: int,
    *,
    n_splits: int,
    valid_ratio: float,
    min_train: int,
    min_valid: int,
) -> list[tuple[np.ndarray, np.ndarray]]:
    if sample_count < (min_train + min_valid):
        return []
    valid_size = max(int(sample_count * valid_ratio), min_valid)
    if valid_size <= 0:
        return []

    folds: list[tuple[np.ndarray, np.ndarray]] = []
    for split_idx in range(n_splits):
        val_end = sample_count - (n_splits - split_idx - 1) * valid_size
        val_start = val_end - valid_size
        if val_start <= 0 or val_end > sample_count:
            continue
        train_end = val_start
        if train_end < min_train:
            continue
        train_idx = np.arange(train_end, dtype=int)
        valid_idx = np.arange(val_start, min(val_end, sample_count), dtype=int)
        if valid_idx.size == 0:
            continue
        folds.append((train_idx, valid_idx))
    return folds


def run(
    train_start: dt.date,
    train_end: dt.date,
    *,
    lookback_days: int = 260,
) -> dict[str, dict] | None:
    """모델 학습 엔트리포인트."""

    if train_start > train_end:
        raise ValueError("train_start must be earlier than train_end")

    horizons = [cfg["horizon"] for cfg in _TASK_DEFINITIONS.values() if "horizon" in cfg]
    max_horizon = max(horizons)

    effective_lookback = max(lookback_days, MIN_REQUIRED_LOOKBACK)
    feature_start = train_start - dt.timedelta(days=effective_lookback)
    feature_end = train_end

    logger.info(
        "모델 학습 시작: 기간=%s~%s, lookback=%d, universe=%d종",
        train_start,
        train_end,
        lookback_days,
        len(METRIC_STOCKS),
    )

    features = build_feature_store((feature_start, feature_end), METRIC_STOCKS)
    if features.empty:
        logger.warning("Feature DataFrame이 비어 있어 학습을 중단합니다.")
        return None

    price_history = fetch_prices(
        METRIC_STOCKS,
        train_start - dt.timedelta(days=max(5, MIN_REQUIRED_LOOKBACK)),
        train_end + dt.timedelta(days=max_horizon + 5),
    )
    if price_history.empty:
        logger.warning("가격 데이터가 부족해 학습을 중단합니다.")
        return None

    targets = _compute_targets(price_history, horizons)
    feature_subset = features.loc[(slice(None), slice(train_start, train_end)), :].copy()
    feature_subset = feature_subset.join(targets, how="left")

    feature_family_columns = [col for col in feature_subset.columns if str(col).startswith("target_")]
    feature_exclude = set(feature_family_columns)
    feature_exclude.update({"price_date"})

    base_feature_columns = [
        col
        for col in feature_subset.columns
        if col not in feature_exclude
    ]

    target_map = {
        "regression_5d": "target_return_5d",
        "classification_5d": "target_direction_5d",
        "regression_20d": "target_return_20d",
        "classification_20d": "target_direction_20d",
    }

    selection_result: FeatureSelectionResult | None = None
    primary_target = "classification_5d"
    primary_target_col = target_map.get(primary_target)

    if primary_target_col:
        try:
            selection_result = select_feature_columns(
                feature_subset,
                target_column=primary_target_col,
                base_feature_columns=base_feature_columns,
                task_type="classification",
            )
            selected_columns = selection_result.selected or base_feature_columns
        except Exception as exc:  # pragma: no cover - defensive
            logger.warning("Feature selection 실패로 기본 피처 사용 (error=%s)", exc)
            selected_columns = base_feature_columns
            selection_result = None
    else:
        selected_columns = base_feature_columns

    if not selected_columns:
        selected_columns = base_feature_columns

    logger.info(
        "Feature selection 결과: total=%d, selected=%d, removed_var=%d, removed_corr=%d, removed_shap=%d",
        len(base_feature_columns),
        len(selected_columns),
        len(selection_result.removed_by_variance) if selection_result else 0,
        len(selection_result.removed_by_correlation) if selection_result else 0,
        len(selection_result.removed_by_shap) if selection_result else 0,
    )

    datasets = build_datasets(
        feature_subset,
        targets=target_map,
        config={"feature_columns": selected_columns},
    )
    if not datasets:
        logger.warning("구성된 학습 데이터셋이 없어 학습을 중단합니다.")
        return None

    # Apply temporal split for calibration (hold-out 최근 20%)
    task_configs = {name: dict(cfg) for name, cfg in _TASK_DEFINITIONS.items()}
    if selection_result:
        selection_meta = {
            "selected_features": selected_columns,
            "removed_by_variance": selection_result.removed_by_variance,
            "removed_by_correlation": selection_result.removed_by_correlation,
            "removed_by_shap": selection_result.removed_by_shap,
        }
        if selection_result.shap_importance:
            selection_meta["shap_importance"] = selection_result.shap_importance
        for cfg in task_configs.values():
            cfg["feature_selection"] = selection_meta
    for task_name, payload in list(datasets.items()):
        payload = dict(payload)
        X = payload["X"]
        y = payload["y"]
        if WALK_FORWARD_ENABLED:
            folds = _build_walk_forward_folds(
                len(y),
                n_splits=WALK_FORWARD_SPLITS,
                valid_ratio=WALK_FORWARD_VAL_RATIO,
                min_train=WALK_FORWARD_MIN_TRAIN,
                min_valid=WALK_FORWARD_MIN_VALID,
            )
            if folds:
                payload["walk_folds"] = folds
        if CALIBRATION_RATIO > 0 and len(X) > 1000:
            split_idx = int(len(X) * (1 - CALIBRATION_RATIO))
            split_idx = max(1, min(len(X) - 1, split_idx))
            payload["X_train"] = X[:split_idx]
            payload["y_train"] = y[:split_idx]
            payload["X_cal"] = X[split_idx:]
            payload["y_cal"] = y[split_idx:]
            if "index" in payload:
                payload["index_train"] = payload["index"][:split_idx]
                payload["index_cal"] = payload["index"][split_idx:]
            datasets[task_name] = payload
        else:
            payload = dict(payload)
            payload["X_train"] = X
            payload["y_train"] = y
            payload["X_cal"] = None
            payload["y_cal"] = None
            payload["index_train"] = payload.get("index")
            payload["index_cal"] = None
        datasets[task_name] = payload

    tuning_summaries: dict[str, dict] = {}

    if ENABLE_TUNING:
        logger.info("Optuna 기반 하이퍼파라미터 탐색 시작 (trials=%d)", TUNING_TRIALS)
        for task_name, payload in datasets.items():
            task_cfg = task_configs.get(task_name, {})
            task_type = task_cfg.get("type")
            if task_type is None:
                continue
            X = payload["X"]
            y = payload["y"]
            if X.size == 0 or y.size == 0:
                continue
            try:
                tuning_result = tune_hyperparameters(
                    task_name=task_name,
                    task_type=task_type,
                    X=X,
                    y=y,
                    n_trials=TUNING_TRIALS,
                    folds=payload.get("walk_folds"),
                )
            except Exception as exc:  # pragma: no cover - tuning fallback
                logger.warning(
                    "튜닝 실패로 기본 하이퍼파라미터를 사용합니다. task=%s, error=%s",
                    task_name,
                    exc,
                )
                continue
            task_configs[task_name]["params"] = tuning_result.params
            tuning_summaries[task_name] = {
                "best_score": tuning_result.best_score,
                "direction": tuning_result.direction,
                "trials": tuning_result.trials,
            }
            task_configs[task_name]["tuning_summary"] = tuning_summaries[task_name]
            logger.info(
                "튜닝 완료: task=%s, best_score=%.6f, trials=%d",
                task_name,
                tuning_result.best_score,
                tuning_result.trials,
            )
    else:
        logger.info("환경변수로 인해 하이퍼파라미터 튜닝을 건너뜁니다.")

    results = train_models(datasets, config={"tasks": task_configs})
    if not results:
        logger.warning("학습된 모델이 없습니다.")
        return None

    for task_name, info in results.items():
        meta = info.get("metadata", {})
        log_msg = (
            "모델 학습 완료: task=%s, model_id=%s, train_size=%s, tuning_score=%s"
        )
        logger.info(
            log_msg,
            task_name,
            info["model_id"],
            meta.get("train_size"),
            meta.get("tuning", {}).get("best_score"),
        )
    return results


