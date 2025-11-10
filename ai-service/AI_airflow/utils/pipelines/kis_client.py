"""KIS Open API 클라이언트 래퍼.

토큰 발급과 요청 로직을 단순화한 버전으로, Airflow나 스크립트에서
재사용하기 쉽게 구성했다.
"""

from __future__ import annotations

import json
import os
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Optional

import requests


DEFAULT_BASE_URL = "https://openapi.koreainvestment.com:9443"
TOKEN_ENDPOINT = "/oauth2/tokenP"
TOKEN_CACHE_PATH = Path(__file__).resolve().with_name(".kis_token.json")


class KISClientError(RuntimeError):
    """KIS API 에러를 표현하는 예외."""


@dataclass
class KISToken:
    token: str
    expires_at: float

    @property
    def is_expired(self) -> bool:
        return time.time() >= self.expires_at - 5

    def as_dict(self) -> Dict[str, Any]:
        return {"token": self.token, "expires_at": self.expires_at}


class KISClient:
    """접근 토큰 발급과 API 호출을 담당하는 간단한 헬퍼 클래스."""

    def __init__(self, app_key: str, app_secret: str, base_url: str | None = None) -> None:
        self.app_key = app_key
        self.app_secret = app_secret
        self.base_url = base_url or DEFAULT_BASE_URL
        self._token: Optional[KISToken] = None
        self._load_cached_token()

    # ------------------------------------------------------------------
    # Token helpers
    # ------------------------------------------------------------------
    def _load_cached_token(self) -> None:
        if not TOKEN_CACHE_PATH.exists():
            return
        try:
            cache = json.loads(TOKEN_CACHE_PATH.read_text(encoding="utf-8"))
        except Exception:
            return
        cached = cache.get(self.app_key)
        if not cached:
            return
        token = cached.get("token")
        expires_at = cached.get("expires_at")
        if not token or expires_at is None:
            return
        try:
            expires_at = float(expires_at)
        except (TypeError, ValueError):
            return
        if time.time() >= expires_at - 5:
            return
        self._token = KISToken(token=token, expires_at=expires_at)

    def _cache_token(self) -> None:
        if self._token is None:
            return
        cache: Dict[str, Any] = {}
        if TOKEN_CACHE_PATH.exists():
            try:
                cache = json.loads(TOKEN_CACHE_PATH.read_text(encoding="utf-8"))
            except Exception:
                cache = {}
        cache[self.app_key] = self._token.as_dict()
        try:
            TOKEN_CACHE_PATH.write_text(json.dumps(cache), encoding="utf-8")
        except Exception:
            pass

    def _refresh_token(self) -> None:
        url = f"{self.base_url}{TOKEN_ENDPOINT}"
        payload = {
            "grant_type": "client_credentials",
            "appkey": self.app_key,
            "appsecret": self.app_secret,
        }
        response = requests.post(url, json=payload, timeout=10)
        if response.status_code != 200:
            if response.status_code == 403 and "1분당 1회" in response.text:
                time.sleep(65)
                response = requests.post(url, json=payload, timeout=10)
                if response.status_code != 200:
                    raise KISClientError(
                        f"Token request failed: {response.status_code} {response.text}"
                    )
            else:
                raise KISClientError(
                    f"Token request failed: {response.status_code} {response.text}"
                )

        data = response.json()
        access_token = data.get("access_token")
        expires_raw = (
            data.get("access_token_token_expired")
            or data.get("access_token_token_expire")
            or data.get("access_token_expired")
            or data.get("access_token_expire")
            or data.get("expires_in")
        )
        if isinstance(expires_raw, str):
            try:
                expires_at = time.mktime(time.strptime(expires_raw, "%Y-%m-%d %H:%M:%S"))
            except ValueError:
                expires_at = time.time() + 60 * 60
        else:
            try:
                expires_in = int(expires_raw)
            except (TypeError, ValueError):
                expires_in = 60 * 60
            expires_at = time.time() + max(expires_in, 1)
        if not access_token:
            raise KISClientError(f"Malformed token response: {data}")
        self._token = KISToken(token=access_token, expires_at=expires_at)
        self._cache_token()

    def get_access_token(self) -> str:
        if self._token is None or self._token.is_expired:
            self._refresh_token()
        assert self._token is not None
        return self._token.token

    # ------------------------------------------------------------------
    # Request helper
    # ------------------------------------------------------------------
    def request(
        self,
        method: str,
        endpoint: str,
        *,
        tr_id: str,
        params: Optional[Dict[str, Any]] = None,
        headers: Optional[Dict[str, str]] = None,
    ) -> Dict[str, Any]:
        """Call KIS API endpoint.

        Parameters
        ----------
        method:
            HTTP method (``"GET"`` or ``"POST"`` 등).
        endpoint:
            Base URL을 제외한 경로.
        tr_id:
            KIS가 요구하는 ``tr_id`` 값.
        params:
            쿼리 파라미터.
        headers:
            추가 헤더.
        """

        token = self.get_access_token()
        base_headers = {
            "Authorization": f"Bearer {token}",
            "appkey": self.app_key,
            "appsecret": self.app_secret,
            "tr_id": tr_id,
            "custtype": "P",
            "Content-Type": "application/json; charset=UTF-8",
        }
        if headers:
            base_headers.update(headers)

        url = f"{self.base_url}{endpoint}"
        response = requests.request(method, url, params=params, headers=base_headers, timeout=10)
        if response.status_code != 200:
            raise KISClientError(
                f"KIS API error {response.status_code}: {response.text} (endpoint={endpoint})"
            )

        data = response.json()
        if data.get("rt_cd") not in ("0", "", None):
            raise KISClientError(f"KIS returned error: {data}")
        return data


def default_client() -> KISClient:
    app_key = os.getenv("KIS_APP_KEY")
    app_secret = os.getenv("KIS_APP_SECRET")
    if not app_key or not app_secret:
        raise RuntimeError("KIS_APP_KEY/KIS_APP_SECRET 환경변수가 필요합니다.")
    base_url = os.getenv("KIS_BASE_URL", DEFAULT_BASE_URL)
    return KISClient(app_key=app_key, app_secret=app_secret, base_url=base_url)


__all__ = [
    "KISClient",
    "KISClientError",
    "default_client",
]


