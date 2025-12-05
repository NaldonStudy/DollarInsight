"""시간/거래일 유틸리티 스텁."""

from __future__ import annotations

import datetime as dt


def to_kst(value: dt.datetime) -> dt.datetime:
    """UTC datetime을 KST로 변환."""
    raise NotImplementedError("시간 변환 로직을 구현하세요.")


def previous_trading_day(value: dt.date) -> dt.date:
    """이전 거래일을 반환."""
    raise NotImplementedError("거래일 계산 로직을 구현하세요.")


