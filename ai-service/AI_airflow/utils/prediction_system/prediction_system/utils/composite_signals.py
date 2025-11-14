"""조합형 시그널 feature 스텁."""

from __future__ import annotations

import pandas as pd


def compute_composite_signals(feature_df: pd.DataFrame) -> pd.DataFrame:
    """
    RSI+볼린저, MACD+ATR 등 조합형 시그널을 생성한다.
    """
    raise NotImplementedError("Composite signal 계산을 구현하세요.")


