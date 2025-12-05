"""PostgreSQL에서 특정 일자의 스냅샷을 JSON으로 내보내는 도구."""

from __future__ import annotations

import datetime as dt
import json
from pathlib import Path

from psycopg2.extras import RealDictCursor

from .db import get_connection


DEFAULT_TABLES = {
    "stock_price_daily": """
        SELECT * FROM stock_price_daily
        WHERE price_date = %(target)s
        ORDER BY ticker
    """,
    "etf_price_daily": """
        SELECT * FROM etf_price_daily
        WHERE price_date = %(target)s
        ORDER BY ticker
    """,
    "index_price_daily": """
        SELECT * FROM index_price_daily
        WHERE price_date = %(target)s
        ORDER BY ticker
    """,
}


def export_snapshot(
    date: dt.date,
    *,
    output_dir: Path,
    tables: dict[str, str] | None = None,
) -> None:
    queries = tables or DEFAULT_TABLES
    output_dir.mkdir(parents=True, exist_ok=True)
    with get_connection() as conn:
        for table, query in queries.items():
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute(query, {"target": date})
                rows = cur.fetchall()
            path = output_dir / f"{table}_{date.isoformat()}.json"
            with path.open("w", encoding="utf-8") as f:
                json.dump(rows, f, ensure_ascii=False, indent=2, default=str)


if __name__ == "__main__":
    target = dt.date(2025, 11, 4)
    export_snapshot(target, output_dir=Path("pipelines/output/reference"))


