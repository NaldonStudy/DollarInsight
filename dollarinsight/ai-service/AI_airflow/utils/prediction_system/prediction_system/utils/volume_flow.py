"""Volume & 수급 feature 스텁."""

from __future__ import annotations

import pandas as pd


def compute_volume_flow_features(df: pd.DataFrame) -> pd.DataFrame:
    """
    거래량 기반 지표(MFI, OBV 등)를 계산한다.
    """
    raise NotImplementedError("Volume/Flow feature 계산을 구현하세요.")


