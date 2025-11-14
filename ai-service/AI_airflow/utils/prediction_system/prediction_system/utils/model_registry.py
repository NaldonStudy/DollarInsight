"""모델 레지스트리 스텁."""

from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Any

import joblib
import datetime as dt


def _sanitize_identifier(value: str) -> str:
    for ch in (":", "\\", "/", " ", "|"):
        value = value.replace(ch, "")
    return value


_REGISTRY_DIR = Path(
    os.getenv(
        "MODEL_REGISTRY_DIR",
        Path(__file__).resolve().parents[1] / "artifacts" / "models",
    )
)
_MANIFEST_PATH = _REGISTRY_DIR / "latest_models.json"


def _load_manifest() -> dict[str, Any]:
    if not _MANIFEST_PATH.exists():
        return {}
    with _MANIFEST_PATH.open("r", encoding="utf-8") as fp:
        return json.load(fp)


def _save_manifest(manifest: dict[str, Any]) -> None:
    _REGISTRY_DIR.mkdir(parents=True, exist_ok=True)
    with _MANIFEST_PATH.open("w", encoding="utf-8") as fp:
        json.dump(manifest, fp, indent=2, ensure_ascii=False)


def register_model(model, metadata: dict) -> str:
    """모델과 메타 정보를 저장하고 식별자를 반환한다."""

    _REGISTRY_DIR.mkdir(parents=True, exist_ok=True)
    task_name = metadata.get("task_name", "model")
    timestamp = metadata.get("trained_at") or dt.datetime.utcnow().strftime("%Y%m%d%H%M%S")
    timestamp = _sanitize_identifier(timestamp)
    model_id_raw = metadata.get("model_id") or f"{task_name}_{timestamp}"
    model_id = _sanitize_identifier(model_id_raw)

    model_path = _REGISTRY_DIR / f"{model_id}.joblib"
    meta_path = _REGISTRY_DIR / f"{model_id}.meta.json"

    joblib.dump(model, model_path)
    with meta_path.open("w", encoding="utf-8") as fp:
        json.dump({**metadata, "model_id": model_id}, fp, indent=2, ensure_ascii=False)

    manifest = _load_manifest()
    manifest[task_name] = {
        "model_id": model_id,
        "metadata_path": str(meta_path),
    }
    _save_manifest(manifest)
    return model_id


def load_metadata(*, task_name: str | None = None, model_id: str | None = None) -> dict[str, Any]:
    if model_id is None and task_name is None:
        raise ValueError("Either task_name or model_id must be provided.")

    manifest = _load_manifest()
    meta_path: Path | None = None
    resolved_model_id = model_id

    if resolved_model_id is None and task_name:
        record = manifest.get(task_name)
        if not record:
            raise KeyError(f"No model registered for task '{task_name}'.")
        meta_path = _REGISTRY_DIR / Path(record["metadata_path"]).name
        resolved_model_id = record["model_id"]
    else:
        meta_path = _REGISTRY_DIR / f"{resolved_model_id}.meta.json"
        if not meta_path.exists() and task_name:
            record = manifest.get(task_name)
            if record:
                meta_path = _REGISTRY_DIR / Path(record["metadata_path"]).name
                resolved_model_id = record.get("model_id", resolved_model_id)

    if meta_path is None or not meta_path.exists():
        raise FileNotFoundError(f"Metadata not found for model '{resolved_model_id}'.")

    with meta_path.open("r", encoding="utf-8") as fp:
        metadata = json.load(fp)
    return metadata


def update_metadata(model_id: str, updates: dict[str, Any]) -> dict[str, Any]:
    meta_path = _REGISTRY_DIR / f"{model_id}.meta.json"
    if not meta_path.exists():
        raise FileNotFoundError(f"Metadata file not found for model '{model_id}'.")
    with meta_path.open("r", encoding="utf-8") as fp:
        metadata = json.load(fp)

    metadata.update(updates)

    _REGISTRY_DIR.mkdir(parents=True, exist_ok=True)
    with meta_path.open("w", encoding="utf-8") as fp:
        json.dump(metadata, fp, indent=2, ensure_ascii=False)

    manifest = _load_manifest()
    for task_name, record in manifest.items():
        if record.get("model_id") == model_id:
            record["metadata_path"] = str(meta_path)
    _save_manifest(manifest)
    return metadata


def load_model(*, task_name: str | None = None, model_id: str | None = None):
    """지정한 모델을 로드해 반환한다."""

    if model_id is None and task_name is None:
        raise ValueError("Either task_name or model_id must be provided.")

    manifest = _load_manifest()
    metadata_path: Path | None = None

    if model_id is None:
        record = manifest.get(task_name or "")
        if record is None:
            raise KeyError(f"No model registered for task '{task_name}'.")
        model_id = record["model_id"]
        metadata_path = _REGISTRY_DIR / Path(record["metadata_path"]).name
    else:
        metadata_path = _REGISTRY_DIR / f"{model_id}.meta.json"
        if not metadata_path.exists() and task_name:
            record = manifest.get(task_name)
            if record:
                metadata_path = _REGISTRY_DIR / Path(record["metadata_path"]).name

    model_path = _REGISTRY_DIR / f"{model_id}.joblib"
    if not model_path.exists():
        raise FileNotFoundError(f"Model artifact not found: {model_path}")

    metadata: dict[str, Any] = {}
    if metadata_path and metadata_path.exists():
        with metadata_path.open("r", encoding="utf-8") as fp:
            metadata = json.load(fp)

    model = joblib.load(model_path)
    return model, metadata


