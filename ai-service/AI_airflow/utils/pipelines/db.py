"""PostgreSQL 연결 및 쿼리 유틸리티."""

from __future__ import annotations

import logging
import os
from contextlib import contextmanager
from dataclasses import dataclass

from psycopg2.extras import RealDictCursor
from psycopg2.pool import SimpleConnectionPool

from .env_loader import load_env


logger = logging.getLogger(__name__)


@dataclass
class DBConfig:
    host: str
    port: int
    database: str
    user: str
    password: str


def _build_config() -> DBConfig:
    load_env()
    return DBConfig(
        host=os.getenv("POSTGRESQL_URL", os.getenv("DB_HOST", "localhost")),
        port=int(os.getenv("POSTGRESQL_PORT", os.getenv("DB_PORT", "5432"))),
        database=os.getenv("POSTGRESQL_NAME", os.getenv("DB_NAME", "postgres")),
        user=os.getenv("POSTGRESQL_USER", os.getenv("DB_USER", "postgres")),
        password=os.getenv("POSTGRESQL_PASSWORD", os.getenv("DB_PASSWORD", "")),
    )


CONFIG = _build_config()
POOL: SimpleConnectionPool | None = None


def init_pool(minconn: int = 1, maxconn: int = 10) -> None:
    global POOL
    if POOL is not None:
        return
    POOL = SimpleConnectionPool(
        minconn=minconn,
        maxconn=maxconn,
        host=CONFIG.host,
        port=CONFIG.port,
        database=CONFIG.database,
        user=CONFIG.user,
        password=CONFIG.password,
    )
    logger.info("PostgreSQL connection pool initialized: %s", CONFIG.database)


@contextmanager
def get_connection():
    if POOL is None:
        init_pool()
    assert POOL is not None
    conn = POOL.getconn()
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        POOL.putconn(conn)


def fetch_all(query: str, params: tuple | list | None = None) -> list[dict]:
    with get_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(query, params)
            return cur.fetchall()


__all__ = [
    "DBConfig",
    "CONFIG",
    "init_pool",
    "get_connection",
    "fetch_all",
]


