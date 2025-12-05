"""FastAPI 앱 엔트리포인트 스텁."""

from __future__ import annotations

from fastapi import FastAPI


def create_app() -> FastAPI:
    """FastAPI 애플리케이션을 생성해 반환한다."""

    app = FastAPI(title="US Stock Forecast API")
    return app


app = create_app()


