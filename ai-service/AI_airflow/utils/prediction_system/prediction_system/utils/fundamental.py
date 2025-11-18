"""재무 지표 feature 스텁."""

from __future__ import annotations

import pandas as pd


def compute_fundamental_features(
    financial_df: pd.DataFrame,
    master_df: pd.DataFrame,
) -> pd.DataFrame:
    """
    PER, PBR, ROE, 성장률 등 재무 기반 피처를 계산한다.
    """
    raise NotImplementedError("Fundamental feature 계산을 구현하세요.")


