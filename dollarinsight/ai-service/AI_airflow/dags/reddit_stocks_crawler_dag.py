"""
Reddit 주식 게시글 크롤링 Airflow DAG
2시간마다 실행하여 인기 게시글을 수집하고 JSON 파일에 누적 저장
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

# Lazy import: 무거운 라이브러리는 함수 내부에서 import하여 DAG 파싱 시 CPU/메모리 사용량 감소
# from crawl_reddit_stocks import RedditPostsCrawler


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
    "reddit_stocks_crawler",
    default_args=default_args,
    description="Reddit 주식 게시글 크롤링 - 2시간마다 실행",
    schedule="0 */2 * * *",  # 2시간마다 실행 (매 짝수 시 0분) - schedule_interval 대신 schedule 사용
    catchup=False,
    max_active_runs=1,  # 동시에 실행될 수 있는 같은 DAG 인스턴스 수 (1개만 허용)
    max_active_tasks=1,  # 동시에 실행될 수 있는 Task 수
    tags=["reddit", "stocks", "crawling", "social"],
)


def crawl_reddit_stocks(**context):
    """Reddit 주식 게시글 크롤링 실행"""
    # Lazy import: 무거운 라이브러리는 함수 내부에서 import하여 DAG 파싱 시 CPU/메모리 사용량 감소
    from crawl_reddit_stocks import RedditPostsCrawler
    import os
    from datetime import datetime

    # 데이터 저장 경로 설정
    data_dir = os.path.join(project_root, "data")
    os.makedirs(data_dir, exist_ok=True)
    json_file = os.path.join(data_dir, "reddit_stocks.json")

    print(f"🔄 크롤링 시작: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"📁 저장 경로: {json_file}")

    try:
        # 크롤러 생성 (최소 score 100점 이상 필터링)
        # Reddit 공개 API 사용 (인증 불필요)
        crawler = RedditPostsCrawler(min_score=100)

        # 크롤링 실행 (각 서브레딧당 25개 게시글)
        results = crawler.crawl(limit_per_subreddit=25)

        if results and results.get("posts"):
            # 기존 JSON 파일에 누적 저장 (permalink 기준 중복 제거)
            new_count = crawler.append_to_json(results, filename=json_file)

            print(f"✅ 크롤링 완료:")
            print(f"   - 수집된 게시글: {len(results['posts'])}개")
            print(f"   - 신규 추가: {new_count}개")
            print(f"   - 최소 score: {results.get('min_score', 5)}점 이상")

            # Airflow XCom에 결과 저장
            context["ti"].xcom_push(key="total_posts", value=len(results["posts"]))
            context["ti"].xcom_push(key="new_posts", value=new_count)

            return {
                "status": "success",
                "total_posts": len(results["posts"]),
                "new_posts": new_count,
            }
        else:
            print("⚠️ 크롤링된 게시글이 없습니다.")
            return {
                "status": "no_posts",
                "total_posts": 0,
                "new_posts": 0,
            }

    except Exception as e:
        print(f"❌ 크롤링 중 오류 발생: {str(e)}")
        import traceback

        traceback.print_exc()
        raise


# 크롤링 작업 정의
crawl_task = PythonOperator(
    task_id="crawl_reddit_stocks",
    python_callable=crawl_reddit_stocks,
    dag=dag,
)

# 작업 실행
crawl_task
