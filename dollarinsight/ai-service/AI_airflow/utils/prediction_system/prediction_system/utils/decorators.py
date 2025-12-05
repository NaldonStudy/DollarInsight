"""공통 데코레이터 스텁."""

from __future__ import annotations

from functools import wraps


def log_execution(func):
    """실행 시작/종료를 로깅하는 데코레이터."""

    @wraps(func)
    def wrapper(*args, **kwargs):
        raise NotImplementedError("로깅 데코레이터 로직을 구현하세요.")

    return wrapper


def retry(times: int = 3, delay_seconds: float = 1.0):
    """재시도 데코레이터."""

    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            raise NotImplementedError("재시도 로직을 구현하세요.")

        return wrapper

    return decorator


