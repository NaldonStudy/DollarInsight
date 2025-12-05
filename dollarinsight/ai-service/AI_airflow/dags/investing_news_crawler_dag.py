"""
Investing.com 뉴스 크롤링 Airflow DAG
30분마다 실행하여 최신 뉴스를 수집하고 JSON 파일에 누적 저장
"""

from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta
import sys
import os

# Airflow utils 경로를 Python 경로에 추가
# dags와 utils가 모두 airflow/ 안에 있으므로 같은 레벨
airflow_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
utils_dir = os.path.join(airflow_dir, "utils")
if utils_dir not in sys.path:
    sys.path.insert(0, utils_dir)

# 프로젝트 루트 경로 (데이터 저장용)
# Docker 컨테이너 내부에서 /opt/airflow가 루트이므로 airflow_dir 사용
project_root = airflow_dir  # /opt/airflow

# Lazy import: 무거운 라이브러리는 함수 내부에서 import하여 DAG 파싱 시 CPU/메모리 사용량 감소
# from crawl_investing_news import InvestingNewsCrawler


# 기본 인자 설정
default_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
    "start_date": datetime(2024, 1, 1),
}

# DAG 정의
dag = DAG(
    "investing_news_crawler",
    default_args=default_args,
    description="Investing.com 뉴스 크롤링 - 30분마다 실행",
    schedule="*/30 * * * *",  # 30분마다 실행 - schedule_interval 대신 schedule 사용
    catchup=False,
    max_active_runs=1,  # 동시에 실행될 수 있는 같은 DAG 인스턴스 수 (1개만 허용)
    max_active_tasks=1,  # 동시에 실행될 수 있는 Task 수
    tags=["news", "crawling", "investing"],
)


def crawl_investing_news(**context):
    """Investing.com 뉴스 크롤링 실행"""
    # Lazy import: 무거운 라이브러리는 함수 내부에서 import하여 DAG 파싱 시 CPU/메모리 사용량 감소
    from crawl_investing_news import InvestingNewsCrawler
    import os
    from datetime import datetime

    # 데이터 저장 경로 설정
    # Docker 컨테이너: /opt/airflow/data → 호스트: AI_airflow/data
    data_dir = os.path.join(project_root, "data")
    os.makedirs(data_dir, exist_ok=True)
    json_file = os.path.join(data_dir, "investing_news.json")

    print(f"🔄 크롤링 시작: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"📁 저장 경로: {json_file} (호스트: AI_airflow/data/investing_news.json)")

    try:
        # 크롤러 생성 및 실행
        crawler = InvestingNewsCrawler()
        results = crawler.crawl(max_articles=10)

        if results:
            # 기존 JSON 파일에 누적 저장
            new_count = crawler.append_to_json(results, filename=json_file)
            print(
                f"✅ 크롤링 완료: {new_count}개 새 기사 추가, 총 {len(results)}개 처리"
            )

            # Airflow XCom에 결과 저장
            context["ti"].xcom_push(key="new_articles", value=new_count)
            context["ti"].xcom_push(key="total_processed", value=len(results))

            return {
                "status": "success",
                "new_articles": new_count,
                "total_processed": len(results),
            }
        else:
            print("⚠️ 크롤링된 기사가 없습니다.")
            return {
                "status": "no_articles",
                "new_articles": 0,
                "total_processed": 0,
            }

    except Exception as e:
        print(f"❌ 크롤링 중 오류 발생: {str(e)}")
        import traceback

        traceback.print_exc()
        raise


# 크롤링 작업 정의
crawl_task = PythonOperator(
    task_id="crawl_investing_news",
    python_callable=crawl_investing_news,
    dag=dag,
)

# 작업 실행 순서 설정 (현재는 단일 작업이지만 향후 확장 가능)
crawl_task
