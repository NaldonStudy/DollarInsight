"""
High-level pipelines for model training and daily prediction.

이 모듈은 Airflow 등 스케줄러에서 바로 호출하기 위한 엔트리 포인트를 제공한다.
"""

from .training_pipeline import run_pipeline as run_training_pipeline
from .prediction_pipeline import run_pipeline as run_prediction_pipeline

__all__ = ["run_training_pipeline", "run_prediction_pipeline"]


