"""Compare macro_economic_indicators JSON with DB records."""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from datetime import date
from pathlib import Path
from typing import Dict, List, Optional, Tuple

from pipelines.env_loader import load_env
from pipelines.db import get_connection


@dataclass
class MacroRecord:
    indicator_code: str
    date: date
    value: float
    unit: Optional[str]
    seasonal_adjustment: Optional[str]
    change_mom: Optional[float]
    change_pct: Optional[float]


NUM_FIELDS = ["value", "change_mom", "change_yoy"]


def round_num(value: Optional[float], digits: int = 6) -> Optional[float]:
    if value is None:
        return None
    return round(float(value), digits)


def load_json_records(path: Path) -> Dict[Tuple[str, date], Dict]:
    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)
    records = {}
    for row in data:
        key = (row["indicator_code"], date.fromisoformat(row["date"]))
        # normalize numeric fields
        for field in NUM_FIELDS:
            if field in row and row[field] is not None:
                row[field] = float(row[field])
        records[key] = row
    return records


def fetch_db_records(target: date) -> Dict[Tuple[str, date], Dict]:
    query = """
        SELECT indicator_code, date, value, unit, seasonal_adjustment,
               change_mom, change_yoy
        FROM macro_economic_indicators
        WHERE date = %s;
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(query, (target,))
            rows = cur.fetchall()
    result = {}
    for row in rows:
        indicator_code, record_date, value, unit, seasonal_adjustment, change_mom, change_yoy = row
        result[(indicator_code, record_date)] = {
            "indicator_code": indicator_code,
            "date": record_date,
            "value": float(value) if value is not None else None,
            "unit": unit,
            "seasonal_adjustment": seasonal_adjustment,
            "change_mom": float(change_mom) if change_mom is not None else None,
            "change_yoy": float(change_yoy) if change_yoy is not None else None,
        }
    return result


def diff_records(json_records: Dict, db_records: Dict, tolerance: float = 1e-6) -> Dict:
    diffs = {}
    for key, json_row in json_records.items():
        db_row = db_records.get(key)
        if db_row is None:
            diffs[key] = {"status": "missing_in_db", "json": json_row}
            continue
        field_diff = {}
        for field in ["unit", "seasonal_adjustment"]:
            if json_row.get(field) != db_row.get(field):
                field_diff[field] = (json_row.get(field), db_row.get(field))
        for field in NUM_FIELDS:
            json_val = json_row.get(field)
            db_val = db_row.get(field)
            if json_val is None and db_val is None:
                continue
            if json_val is None or db_val is None:
                field_diff[field] = (json_val, db_val)
            else:
                if abs(json_val - db_val) > tolerance:
                    field_diff[field] = (json_val, db_val)
        if field_diff:
            diffs[key] = field_diff
    for key in set(db_records) - set(json_records):
        diffs[key] = {"status": "extra_in_db", "db": db_records[key]}
    return diffs


def summarize(diffs: Dict) -> None:
    if not diffs:
        print("✅ macro_economic_indicators: JSON과 DB 차이 없음")
        return
    missing = [k for k, v in diffs.items() if v.get("status") == "missing_in_db"]
    extra = [k for k, v in diffs.items() if v.get("status") == "extra_in_db"]
    detailed = {k: v for k, v in diffs.items() if v.get("status") not in ("missing_in_db", "extra_in_db")}

    if missing:
        print(f"❌ DB에 없는 레코드: {len(missing)}" )
        print("  예시:", missing[:5])
    if extra:
        print(f"❌ JSON에 없는 레코드: {len(extra)}")
        print("  예시:", extra[:5])
    if detailed:
        print(f"❌ 필드 차이가 있는 레코드: {len(detailed)}")
        sample = list(detailed.items())[:5]
        for key, diff in sample:
            print(f"  {key}: {diff}")


def main(target: date, output_dir: Path) -> None:
    load_env()
    json_path = output_dir / "macro_economic_indicators.json"
    if not json_path.exists():
        raise FileNotFoundError(f"JSON not found: {json_path}")

    json_records = load_json_records(json_path)
    db_records = fetch_db_records(target)
    diffs = diff_records(json_records, db_records)
    summarize(diffs)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Compare macro_economic_indicators JSON with DB")
    parser.add_argument("--date", default="2025-11-04", help="비교 날짜")
    parser.add_argument("--output", default="pipelines/output/20251104", help="JSON이 있는 디렉터리")
    args = parser.parse_args()
    target_date = date.fromisoformat(args.date)
    main(target_date, Path(args.output))
