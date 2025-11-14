"""PostgreSQL 연결 및 DataFrame 조회 유틸리티."""

from __future__ import annotations

import contextlib
import os
from dataclasses import dataclass
from typing import Any, Iterator

import pandas as pd
import psycopg2
from psycopg2.extras import RealDictCursor
from psycopg2.pool import SimpleConnectionPool

try:
    from pipelines.env_loader import load_env  # type: ignore
except ImportError:  # pragma: no cover
    load_env = None  # type: ignore


@dataclass(slots=True)
class _DBConfig:
    host: str
    port: int
    dbname: str
    user: str
    password: str


_CONFIG: _DBConfig | None = None
_POOL: SimpleConnectionPool | None = None


def _build_config() -> _DBConfig:
    if load_env is not None:
        load_env()
    return _DBConfig(
        host=os.getenv("POSTGRESQL_URL", os.getenv("DB_HOST", "localhost")),
        port=int(os.getenv("POSTGRESQL_PORT", os.getenv("DB_PORT", "5432"))),
        dbname=os.getenv("POSTGRESQL_NAME", os.getenv("DB_NAME", "postgres")),
        user=os.getenv("POSTGRESQL_USER", os.getenv("DB_USER", "postgres")),
        password=os.getenv("POSTGRESQL_PASSWORD", os.getenv("DB_PASSWORD", "")),
    )


def _ensure_pool() -> SimpleConnectionPool:
    global _CONFIG, _POOL
    if _POOL is not None:
        return _POOL
    if _CONFIG is None:
        _CONFIG = _build_config()
    _POOL = SimpleConnectionPool(
        minconn=1,
        maxconn=int(os.getenv("PREDICTION_DB_POOL_MAX", "5")),
        host=_CONFIG.host,
        port=_CONFIG.port,
        database=_CONFIG.dbname,
        user=_CONFIG.user,
        password=_CONFIG.password,
    )
    return _POOL


@contextlib.contextmanager
def get_connection() -> Iterator[psycopg2.extensions.connection]:
    """SimpleConnectionPool 기반 PostgreSQL 커넥션 컨텍스트 매니저."""

    pool = _ensure_pool()
    conn = pool.getconn()
    try:
        yield conn
    finally:
        pool.putconn(conn)


def fetch_dataframe(
    query: str,
    params: tuple | dict | None = None,
    *,
    index_col: str | None = None,
) -> pd.DataFrame:
    """
    지정한 SQL을 실행해 pandas DataFrame을 반환한다.

    Parameters
    ----------
    query: str
        실행할 SQL.
    params: tuple | dict | None
        쿼리 파라미터.
    index_col: str | None
        DataFrame 인덱스로 사용할 열 이름.
    """

    with get_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(query, params)
            rows: list[dict[str, Any]] = cur.fetchall()
    df = pd.DataFrame(rows)
    if index_col and index_col in df.columns:
        df.set_index(index_col, inplace=True)
    return df


