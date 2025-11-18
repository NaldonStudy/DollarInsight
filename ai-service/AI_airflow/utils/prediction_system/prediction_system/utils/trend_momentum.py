"""Trend & momentum feature 스텁."""

from __future__ import annotations

import pandas as pd


def compute_trend_momentum_features(
    stock_df: pd.DataFrame,
    market_df: pd.DataFrame | None = None,
) -> pd.DataFrame:
    """
    수익률, 이동평균, 상대 모멘텀 등을 계산한다.
    """
    raise NotImplementedError("Trend/Momentum feature 계산을 구현하세요.")


