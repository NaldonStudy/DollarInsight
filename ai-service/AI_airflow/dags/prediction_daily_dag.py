"""
Prediction Daily Pipeline Airflow DAG

일별 예측 파이프라인을 실행하는 DAG
매일 한국시간 기준 아침 7시에 실행
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
# from prediction_system.pipelines.prediction_pipeline import (
#     run_pipeline as run_prediction_pipeline,
# )


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
# 매일 한국시간 기준 아침 7시 실행 (UTC 기준: 매일 22:00 전날)
dag = DAG(
    "prediction_daily",
    default_args=default_args,
    description="Daily prediction pipeline: Feature update → Daily predictions",
    schedule="0 22 * * *",  # 매일 UTC 22:00 (한국시간 다음날 07:00)
    catchup=False,
    max_active_runs=1,
    tags=["prediction", "daily", "forecast", "ml"],
)


def run_prediction(**context):
    """일별 예측 파이프라인 실행"""
    # Lazy import: 무거운 라이브러리는 함수 내부에서 import하여 DAG 파싱 시 CPU/메모리 사용량 감소
    from prediction_system.pipelines.prediction_pipeline import (
        run_pipeline as run_prediction_pipeline,
    )
    from datetime import datetime

    execution_date = context.get("execution_date") or context.get("data_interval_start")

    # execution_date를 date 객체로 변환
    # 예측은 전날 데이터를 기준으로 실행되므로 execution_date의 전날 사용
    if isinstance(execution_date, datetime):
        target_date = execution_date.date() - dt.timedelta(days=1)
    elif isinstance(execution_date, str):
        target_date = dt.date.fromisoformat(execution_date) - dt.timedelta(days=1)
    else:
        target_date = dt.date.today() - dt.timedelta(days=1)

    print(
        f"🔄 Prediction daily pipeline 시작: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
    )
    print(f"📅 Execution date: {execution_date}")
    print(f"🎯 Target date: {target_date}")

    try:
        # 예측 파이프라인 실행
        predictions = run_prediction_pipeline(
            target_date=target_date.isoformat(),
            lookback_days=260,
            persist_predictions=True,
            build_features=True,
            evaluate=False,  # 일일 실행 시 평가는 제외 (성능 고려)
        )

        if predictions:
            print(f"✅ Prediction daily pipeline 완료")
            print(f"📊 Generated predictions: {len(predictions)} records")

            # 티커별 통계 출력
            tickers = set(p.get("ticker") for p in predictions if p.get("ticker"))
            print(f"📈 Tickers predicted: {len(tickers)}")
        else:
            print("⚠️ Prediction pipeline completed but no predictions were generated")

        return {
            "status": "success",
            "execution_date": str(execution_date),
            "target_date": target_date.isoformat(),
            "prediction_count": len(predictions) if predictions else 0,
        }

    except Exception as e:
        print(f"❌ Prediction daily pipeline 실행 중 오류 발생: {str(e)}")
        import traceback

        traceback.print_exc()
        raise


# 작업 정의
prediction_task = PythonOperator(
    task_id="run_daily_prediction",
    python_callable=run_prediction,
    dag=dag,
)
