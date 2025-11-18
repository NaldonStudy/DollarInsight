"""
Prediction Training Pipeline Airflow DAG

모델 학습 파이프라인을 실행하는 DAG
매주 한국시간 기준 낮 12시에 실행
"""

from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta
import sys
import os
import pytz
import datetime as dt

# Airflow utils 경로를 Python 경로에 추가
airflow_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
utils_dir = os.path.join(airflow_dir, "utils")
if utils_dir not in sys.path:
    sys.path.insert(0, utils_dir)

# prediction_system 경로 추가 (prediction_system 모듈을 import하기 위해)
prediction_system_dir = os.path.join(utils_dir, "prediction_system")
if prediction_system_dir not in sys.path:
    sys.path.insert(0, prediction_system_dir)

# pipelines 경로 추가 (watchlists 모듈용)
pipelines_dir = os.path.join(utils_dir, "pipelines")
if pipelines_dir not in sys.path:
    sys.path.insert(0, pipelines_dir)

# Lazy import: 무거운 라이브러리는 함수 내부에서 import하여 DAG 파싱 시 CPU/메모리 사용량 감소
# from prediction_system.pipelines.training_pipeline import (
#     run_pipeline as run_training_pipeline,
# )


# 기본 인자 설정
# 한국 시간(KST, UTC+9) 기준으로 설정
kst = pytz.timezone("Asia/Seoul")
default_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 1,
    "retry_delay": timedelta(hours=1),
    "start_date": datetime(2024, 1, 1, tzinfo=kst),  # 한국 시간대 적용
}

# DAG 정의
# 매주 월요일 한국시간 기준 낮 12시 실행 (UTC 기준: 매주 월요일 03:00)
dag = DAG(
    "prediction_training",
    default_args=default_args,
    description="Prediction model training pipeline: Feature build → Model training",
    schedule="0 3 * * 1",  # 매주 월요일 UTC 03:00 (한국시간 월요일 12:00)
    catchup=False,
    max_active_runs=1,
    tags=["prediction", "training", "ml", "models"],
)


def run_training(**context):
    """모델 학습 파이프라인 실행"""
    # Lazy import: 무거운 라이브러리는 함수 내부에서 import하여 DAG 파싱 시 CPU/메모리 사용량 감소
    from prediction_system.pipelines.training_pipeline import (
        run_pipeline as run_training_pipeline,
    )
    from datetime import datetime

    execution_date = context.get("execution_date") or context.get("data_interval_start")

    # execution_date를 date 객체로 변환
    if isinstance(execution_date, datetime):
        target_date = execution_date.date()
    elif isinstance(execution_date, str):
        target_date = dt.date.fromisoformat(execution_date)
    else:
        target_date = dt.date.today() - dt.timedelta(days=1)

    # 학습 기간 설정: 최근 1년 데이터 사용
    train_end = target_date
    train_start = train_end - dt.timedelta(days=365)

    print(
        f"🔄 Prediction training pipeline 시작: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
    )
    print(f"📅 Execution date: {execution_date}")
    print(f"📊 Training period: {train_start} ~ {train_end}")

    try:
        # 학습 파이프라인 실행
        train_results = run_training_pipeline(
            train_start=train_start.isoformat(),
            train_end=train_end.isoformat(),
            feature_target=train_end.isoformat(),
            lookback_days=260,
            build_features=True,
        )

        if train_results:
            print(f"✅ Prediction training pipeline 완료")
            print(f"📈 Trained models: {list(train_results.keys())}")
            for task_name, info in train_results.items():
                model_id = info.get("model_id", "N/A")
                print(f"   - {task_name}: {model_id}")
        else:
            print("⚠️ Training pipeline completed but no models were trained")

        return {
            "status": "success",
            "execution_date": str(execution_date),
            "train_start": train_start.isoformat(),
            "train_end": train_end.isoformat(),
            "trained_models": list(train_results.keys()) if train_results else [],
        }

    except Exception as e:
        print(f"❌ Prediction training pipeline 실행 중 오류 발생: {str(e)}")
        import traceback

        traceback.print_exc()
        raise


# 작업 정의
training_task = PythonOperator(
    task_id="run_training_pipeline",
    python_callable=run_training,
    dag=dag,
)
