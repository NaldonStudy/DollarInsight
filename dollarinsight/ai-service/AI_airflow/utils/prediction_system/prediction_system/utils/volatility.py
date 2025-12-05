"""Volatility feature 스텁."""

from __future__ import annotations

import pandas as pd


def compute_volatility_features(df: pd.DataFrame) -> pd.DataFrame:
    """
    ATR, realized volatility, Bollinger Band 등 변동성 관련 피처를 계산한다.
    """
    raise NotImplementedError("Volatility feature 계산을 구현하세요.")


