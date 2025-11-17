"""
Investing.com 뉴스 가공 및 MongoDB 저장 DAG
하루에 한 번 실행하여 investing_news.json을 가공하여 MongoDB에 저장
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

# Lazy import: 무거운 라이브러리는 함수 내부에서 import하여 DAG 파싱 시 CPU/메모리 사용량 감소
# from process_investing_news import (
#     process_and_save,
#     get_mongodb_client,
#     get_mongodb_news_collection,
#     get_mongodb_persona_collection,
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
    "retry_delay": timedelta(minutes=10),
    "start_date": datetime(2024, 1, 1, tzinfo=kst),  # 한국 시간대 적용
}

# DAG 정의
dag = DAG(
    "investing_news_processor",
    default_args=default_args,
    description="Investing.com 뉴스 가공 및 MongoDB 저장 - 하루에 한 번 실행",
    schedule="0 3 * * *",  # 매일 오전 3시 실행 (크롤링 후, 한국 시간 기준)
    catchup=False,
    max_active_runs=1,
    max_active_tasks=1,
    tags=["news", "processing", "mongodb"],
)


def process_investing_news_task(**context):
    """Investing.com 뉴스 가공 및 MongoDB 저장 실행"""
    # Lazy import: 무거운 라이브러리는 함수 내부에서 import하여 DAG 파싱 시 CPU/메모리 사용량 감소
    from process_investing_news import (
        process_and_save,
        get_mongodb_client,
        get_mongodb_news_collection,
        get_mongodb_persona_collection,
    )
    import os
    from datetime import datetime
    
    # JSON 파일 경로
    data_dir = os.path.join(airflow_dir, "data")
    json_path = os.path.join(data_dir, "investing_news.json")
    
    print(f"🔄 뉴스 가공 시작: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"📁 파일 경로: {json_path}")
    
    if not os.path.exists(json_path):
        print(f"❌ 파일을 찾을 수 없습니다: {json_path}")
        return {
            "status": "error",
            "message": f"파일을 찾을 수 없습니다: {json_path}",
        }
    
    try:
        # MongoDB 연결
        client = get_mongodb_client()
        news_collection = get_mongodb_news_collection(client)
        persona_collection = get_mongodb_persona_collection(client)
        
        # 뉴스 가공 및 저장
        stats = process_and_save(
            json_path=json_path,
            news_collection=news_collection,
            persona_collection=persona_collection
        )
        
        client.close()
        
        # Airflow XCom에 결과 저장
        context["ti"].xcom_push(key="total_articles", value=stats["total"])
        context["ti"].xcom_push(key="new_articles", value=stats["new"])
        context["ti"].xcom_push(key="news_inserted", value=stats["news_inserted"])
        context["ti"].xcom_push(key="persona_inserted", value=stats["persona_inserted"])
        
        return {
            "status": "success",
            "total_articles": stats["total"],
            "new_articles": stats["new"],
            "news_inserted": stats["news_inserted"],
            "persona_inserted": stats["persona_inserted"],
        }
        
    except Exception as e:
        print(f"❌ 뉴스 가공 중 오류 발생: {str(e)}")
        import traceback
        traceback.print_exc()
        raise


# 뉴스 가공 작업 정의
process_task = PythonOperator(
    task_id="process_investing_news",
    python_callable=process_investing_news_task,
    dag=dag,
)

# 작업 실행
process_task

