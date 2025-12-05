"""예측 결과 응답 스키마 스텁."""

from __future__ import annotations

import datetime as dt

from pydantic import BaseModel


class PredictionResponse(BaseModel):
    """예측 결과 API 응답 모델."""

    ticker: str
    date: dt.date
    yhat_5d: float | None = None
    lower_5d: float | None = None
    upper_5d: float | None = None
    prob_up_5d: float | None = None
    yhat_20d: float | None = None
    lower_20d: float | None = None
    upper_20d: float | None = None
    prob_up_20d: float | None = None


