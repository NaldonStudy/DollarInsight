"""거시 지표 feature 스텁."""

from __future__ import annotations

import pandas as pd


def compute_macro_features(macro_df: pd.DataFrame) -> pd.DataFrame:
    """
    CPI, 금리 등 거시 지표를 lag/forward fill 처리하여 피처화한다.
    """
    raise NotImplementedError("Macro feature 계산을 구현하세요.")


