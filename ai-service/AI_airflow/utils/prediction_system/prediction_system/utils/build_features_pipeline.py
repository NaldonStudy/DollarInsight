"""Feature build 파이프라인 스텁."""

from __future__ import annotations

import datetime as dt
from typing import Optional

from pipelines.watchlists import METRIC_STOCKS

from .stock_price_dao import fetch_latest_price_date
from .feature_store_builder import build_feature_store, persist_feature_store
from .logger import get_logger

logger = get_logger(__name__)


def run(
    date: dt.date | None = None,
    *,
    lookback_days: int = 250,
) -> dict[str, Optional[object]]:
    """Feature store 빌드 엔트리포인트."""

    target_date = date or fetch_latest_price_date()
    if target_date is None:
        logger.warning("수집된 주가 데이터가 없어 feature build를 건너뜁니다.")
        return {
            "target_date": target_date,
            "rows": 0,
            "artifact_path": None,
        }

    start_date = target_date - dt.timedelta(days=lookback_days)
    logger.info(
        "Feature build 시작: target=%s, window=%s~%s, universe=%d종",
        target_date,
        start_date,
        target_date,
        len(METRIC_STOCKS),
    )

    features = build_feature_store((start_date, target_date), METRIC_STOCKS)
    if features.empty:
        logger.warning("생성된 feature 데이터가 비어 있습니다.")
        return {
            "target_date": target_date,
            "rows": 0,
            "artifact_path": None,
        }

    artifact_path = persist_feature_store(features)
    row_count = len(features)
    logger.info(
        "Feature build 완료: rows=%d, artifact=%s",
        row_count,
        artifact_path,
    )
    return {
        "target_date": target_date,
        "rows": row_count,
        "artifact_path": artifact_path,
    }


