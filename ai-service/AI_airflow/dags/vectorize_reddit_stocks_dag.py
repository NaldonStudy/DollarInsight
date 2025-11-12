"""
Reddit Stocks 데이터 벡터화 Airflow DAG
reddit_stocks.json 데이터를 벡터화하여 ChromaDB에 저장
크롤링 후 실행 (매일 오전 3시 30분)
"""

from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta
import sys
import os

# Airflow utils 경로를 Python 경로에 추가
airflow_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
utils_dir = os.path.join(airflow_dir, "utils")
if utils_dir not in sys.path:
    sys.path.insert(0, utils_dir)

# 프로젝트 루트 경로
project_root = airflow_dir  # /opt/airflow

# 모듈 레벨 import 제거 (파싱 시 CPU 과부하 방지)
# 무거운 라이브러리(FlagEmbedding, kss, chromadb) 로딩을 방지하기 위해
# 함수 내부에서 import하도록 변경
# from vectorize_reddit_stocks import vectorize_reddit_stocks

# 기본 인자 설정
default_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=10),
    "start_date": datetime(2024, 1, 1),
}

# DAG 정의
dag = DAG(
    "vectorize_reddit_stocks",
    default_args=default_args,
    description="Reddit Stocks 데이터 벡터화 - reddit_stocks.json을 ChromaDB에 저장",
    schedule="30 3 * * *",  # 매일 오전 3시 30분 실행 (뉴스 벡터화와 동시)
    catchup=False,
    max_active_runs=1,
    max_active_tasks=1,
    tags=["reddit", "vectorization", "chromadb"],
)


def vectorize_reddit_task(**context):
    """Reddit Stocks 데이터 벡터화 실행"""
    import os
    from datetime import datetime

    # 무거운 라이브러리 import를 함수 내부로 이동 (파싱 시 CPU 과부하 방지)
    from vectorize_reddit_stocks import vectorize_reddit_stocks

    # 데이터 파일 경로 설정
    data_dir = os.path.join(project_root, "data")
    json_file = os.path.join(data_dir, "reddit_stocks.json")

    print(
        f"🔄 Reddit Stocks 벡터화 시작: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
    )
    print(f"📁 데이터 파일: {json_file}")

    try:
        # 벡터화 실행
        stats = vectorize_reddit_stocks(json_file=json_file)

        # Airflow XCom에 결과 저장
        context["ti"].xcom_push(key="saved_chunks", value=stats.get("saved_chunks", 0))
        context["ti"].xcom_push(key="skipped", value=stats.get("skipped", 0))
        context["ti"].xcom_push(key="status", value=stats.get("status", "unknown"))

        return {
            "status": stats.get("status", "unknown"),
            "saved_chunks": stats.get("saved_chunks", 0),
            "skipped": stats.get("skipped", 0),
        }

    except Exception as e:
        print(f"❌ Reddit Stocks 벡터화 중 오류 발생: {str(e)}")
        import traceback

        traceback.print_exc()
        raise


# 벡터화 작업 정의
vectorize_task = PythonOperator(
    task_id="vectorize_reddit_stocks",
    python_callable=vectorize_reddit_task,
    dag=dag,
)

# 작업 실행
vectorize_task
