"""간단한 .env 로더.

`python-dotenv` 없이도 사용할 수 있도록 `KEY=VALUE` 형식의 텍스트 파일을
읽어 `os.environ`에 주입한다. 기본 경로는 프로젝트 루트의 `config/.env`.
"""

from __future__ import annotations

import os
from pathlib import Path
from typing import Iterable


BASE_CONFIG_DIR = Path(__file__).resolve().parents[1] / "config"
DEFAULT_ENV_PATH = BASE_CONFIG_DIR / ".env"
FALLBACK_ENV_PATH = BASE_CONFIG_DIR / "env.template"


def load_env(path: Path | str | None = None, *, override: bool = False) -> None:
    """`.env` 파일을 읽어 환경 변수로 주입한다.

    Parameters
    ----------
    path: 선택적으로 특정 경로를 지정.
    override: True면 이미 존재하는 환경 변수도 덮어쓴다.
    """

    if path:
        env_path = Path(path)
        if not env_path.exists():
            return
    else:
        env_path = DEFAULT_ENV_PATH if DEFAULT_ENV_PATH.exists() else FALLBACK_ENV_PATH
        if not env_path.exists():
            return

    for line in env_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip()
        if not override and key in os.environ:
            continue
        os.environ[key] = value


def load_env_if_needed(paths: Iterable[Path | str]) -> None:
    """주어진 경로 목록 중 존재하는 파일을 순서대로 로드한다."""

    for path in paths:
        load_env(path, override=False)


__all__ = [
    "load_env",
    "load_env_if_needed",
    "DEFAULT_ENV_PATH",
    "FALLBACK_ENV_PATH",
]


