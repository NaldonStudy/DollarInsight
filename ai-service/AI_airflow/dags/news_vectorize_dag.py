"""
뉴스 벡터화 DAG
MongoDB의 뉴스 데이터를 KSS와 BGE-M3를 사용하여 벡터화하여 ChromaDB에 저장
뉴스 처리 후 실행 (매일 오전 3시 30분)
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

from vectorize_news import vectorize_news

# 기본 인자 설정
# 한국 시간(KST, UTC+9) 기준으로 설정
kst = pytz.timezone("Asia/Seoul")
default_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=10),
    "start_date": datetime(2024, 1, 1, tzinfo=kst),  # 한국 시간대 적용
}

# DAG 정의
dag = DAG(
    "news_vectorize",
    default_args=default_args,
    description="뉴스 벡터화 - MongoDB 뉴스를 ChromaDB에 벡터화하여 저장",
    schedule="30 3 * * *",  # 매일 오전 3시 30분 실행 (뉴스 처리 후, 한국 시간 기준)
    catchup=False,
    max_active_runs=1,
    max_active_tasks=1,
    tags=["news", "vectorize", "chromadb"],
)


def vectorize_news_task(**context):
    """뉴스 벡터화 실행"""
    from datetime import datetime
    
    print(f"🔄 뉴스 벡터화 시작: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    try:
        # MongoDB의 모든 뉴스를 벡터화하여 ChromaDB에 저장
        # limit=None: 모든 기사 처리
        # skip=0: 처음부터 처리
        stats = vectorize_news(
            limit=None,  # 모든 기사 처리
            skip=0,  # 처음부터
            collection_name=None  # 환경 변수에서 가져옴
        )
        
        # Airflow XCom에 결과 저장
        context["ti"].xcom_push(key="total_articles", value=stats.get("total_articles", 0))
        context["ti"].xcom_push(key="total_chunks", value=stats.get("total_chunks", 0))
        context["ti"].xcom_push(key="saved_chunks", value=stats.get("saved_chunks", 0))
        context["ti"].xcom_push(key="errors", value=stats.get("errors", 0))
        
        return {
            "status": "success",
            "total_articles": stats.get("total_articles", 0),
            "total_chunks": stats.get("total_chunks", 0),
            "saved_chunks": stats.get("saved_chunks", 0),
            "errors": stats.get("errors", 0),
        }
        
    except Exception as e:
        print(f"❌ 뉴스 벡터화 중 오류 발생: {str(e)}")
        import traceback
        traceback.print_exc()
        raise


# 뉴스 벡터화 작업 정의
vectorize_task = PythonOperator(
    task_id="vectorize_news",
    python_callable=vectorize_news_task,
    dag=dag,
)

# 작업 실행
vectorize_task

