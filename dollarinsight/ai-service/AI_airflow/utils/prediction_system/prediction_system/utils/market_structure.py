"""시장/섹터 구조 feature 스텁."""

from __future__ import annotations

import pandas as pd


def compute_market_structure_features(
    stock_df: pd.DataFrame,
    index_df: pd.DataFrame,
    etf_df: pd.DataFrame,
) -> pd.DataFrame:
    """
    베타, 상관계수, 상대모멘텀 등 시장 구조 관련 피처를 계산한다.
    """
    raise NotImplementedError("Market structure feature 계산을 구현하세요.")


