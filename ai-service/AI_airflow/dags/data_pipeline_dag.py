"""
Data pipeline Airflow DAG

Raw data 수집 → Metrics & Scores 계산 순서로 실행
매일 장 마감 후 실행하여 전날 데이터를 수집하고 메트릭을 계산
"""

from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta
import sys
import os
import pytz

# Airflow utils 경로를 Python 경로에 추가
airflow_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
utils_dir = os.path.join(airflow_dir, "utils")
if utils_dir not in sys.path:
    sys.path.insert(0, utils_dir)

from raw_data_pipeline import run_pipeline as run_raw_data_pipeline
from metrics_scores_pipeline import run_pipeline as run_metrics_scores_pipeline


# 기본 인자 설정
# 한국 시간(KST, UTC+9) 기준으로 설정
kst = pytz.timezone("Asia/Seoul")
default_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=30),
    "start_date": datetime(2024, 1, 1, tzinfo=kst),  # 한국 시간대 적용
}

# DAG 정의
# schedule에 cron 표현식 사용 (UTC 기준으로 실행)
dag = DAG(
    "data_pipeline",
    default_args=default_args,
    description="Data pipeline: Raw data collection → Metrics & Scores calculation",
    schedule="10 21 * * *",  # 매일 UTC 기준 21시 10분 실행
    catchup=False,
    max_active_runs=1,
    max_active_tasks=2,  # 두 작업이 순차적으로 실행되므로 2로 설정
    tags=["data", "collection", "metrics", "scores", "stocks"],
)


def run_raw_data(**context):
    """Raw data pipeline 실행"""
    from datetime import datetime

    execution_date = context.get("execution_date") or context.get("data_interval_start")

    print(f"🔄 Raw data pipeline 시작: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"📅 Execution date: {execution_date}")

    try:
        # 파이프라인 실행 (execution_date 전달)
        run_raw_data_pipeline(execution_date=execution_date)

        print("✅ Raw data pipeline 완료")

        return {
            "status": "success",
            "execution_date": str(execution_date),
        }

    except Exception as e:
        print(f"❌ Raw data pipeline 실행 중 오류 발생: {str(e)}")
        import traceback

        traceback.print_exc()
        raise


def run_metrics_scores(**context):
    """Metrics & scores pipeline 실행"""
    from datetime import datetime

    execution_date = context.get("execution_date") or context.get("data_interval_start")

    print(
        f"🔄 Metrics & scores pipeline 시작: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
    )
    print(f"📅 Execution date: {execution_date}")

    try:
        # 파이프라인 실행 (execution_date 전달)
        run_metrics_scores_pipeline(execution_date=execution_date)

        print("✅ Metrics & scores pipeline 완료")

        return {
            "status": "success",
            "execution_date": str(execution_date),
        }

    except Exception as e:
        print(f"❌ Metrics & scores pipeline 실행 중 오류 발생: {str(e)}")
        import traceback

        traceback.print_exc()
        raise


# 작업 정의
raw_data_task = PythonOperator(
    task_id="run_raw_data_pipeline",
    python_callable=run_raw_data,
    dag=dag,
)

metrics_scores_task = PythonOperator(
    task_id="run_metrics_scores_pipeline",
    python_callable=run_metrics_scores,
    dag=dag,
)

# 작업 순서 설정: raw_data_task 완료 후 metrics_scores_task 실행
raw_data_task >> metrics_scores_task
