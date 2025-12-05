"""설정 로더 스텁."""

from __future__ import annotations

import functools
from pathlib import Path
from typing import Any

import yaml


@functools.lru_cache(maxsize=32)
def load_config(path: str | Path) -> dict[str, Any]:
    """YAML 설정 파일을 로드해 dict로 반환한다."""

    target = Path(path)
    if not target.exists():
        raise FileNotFoundError(f"Config file not found: {target}")
    with target.open("r", encoding="utf-8") as fp:
        data = yaml.safe_load(fp) or {}
    if not isinstance(data, dict):
        raise ValueError(f"YAML root must be a mapping, got {type(data)!r}")
    return data


