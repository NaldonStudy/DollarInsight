"""Price action feature 스텁."""

from __future__ import annotations

import pandas as pd


def compute_price_action_features(df: pd.DataFrame) -> pd.DataFrame:
    """
    캔들 모양, 갭, 바 패턴 등의 price action 피처를 계산한다.
    """
    raise NotImplementedError("Price action feature 계산을 구현하세요.")


