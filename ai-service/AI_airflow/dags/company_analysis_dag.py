"""
기업 분석 Airflow DAG
매일 50개 기업을 분석하여 MongoDB에 저장
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

from process_company_analysis import process_companies, get_mongodb_client, get_mongodb_collection

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
    "company_analysis",
    default_args=default_args,
    description="기업 분석 - 매일 50개 기업/ETF 분석하여 MongoDB 최신화 (업데이트 또는 삽입)",
    schedule="0 2 * * *",  # 매일 오전 2시 실행 (한국 시간 기준)
    catchup=False,
    max_active_runs=1,
    max_active_tasks=1,
    tags=["company", "analysis", "persona"],
)


def analyze_companies_task(**context):
    """50개 기업 분석 실행"""
    import os
    from datetime import datetime
    
    # 분석할 기업 목록 및 업종 정보 (50개: 36개 기업 + 14개 ETF)
    company_list = [
        # 기술 기업 (12개)
        "애플", "마이크로소프트", "구글(알파벳)", "아마존", "메타",
        "엔비디아", "AMD", "인텔", "TSMC", "ASML",
        "어도비", "오라클",
        # 커머스 (2개)
        "쿠팡", "알리바바",
        # 자동차 (1개)
        "테슬라",
        # 항공 (2개)
        "보잉", "델타항공",
        # 모빌리티 (1개)
        "우버",
        # 산업/물류 (1개)
        "페덱스",
        # 리테일 (2개)
        "월마트", "코스트코",
        # 금융 (3개)
        "JP모건", "BOA", "골드만삭스",
        # 결제 (3개)
        "비자", "마스터카드", "페이팔",
        # 보험 (1개)
        "AIG",
        # 소비재 (5개)
        "코카콜라", "펩시", "맥도날드", "스타벅스", "나이키",
        # 미디어/엔터 (3개)
        "넷플릭스", "디즈니", "소니",
        # ETF (14개)
        "VOO", "SPY", "VTI", "QQQ", "QQQM",
        "TQQQ", "SCHD", "SOXX", "SMH", "ITA",
        "XLF", "XLY", "XLP", "ICLN"
    ]
    
    # 기업별 업종 정보 (분석 품질 향상을 위해 제공)
    company_info_dict = {
        # 기술 기업
        "애플": "기술 - 스마트폰, 태블릿, PC, 서비스",
        "마이크로소프트": "기술 - 소프트웨어, 클라우드, AI",
        "구글(알파벳)": "기술 - 검색, 광고, 클라우드, AI",
        "아마존": "기술 - 전자상거래, 클라우드, AI",
        "메타": "기술 - 소셜미디어, 메타버스, AI",
        "엔비디아": "기술 - GPU, AI 반도체",
        "AMD": "기술 - CPU, GPU 반도체",
        "인텔": "기술 - CPU 반도체",
        "TSMC": "기술 - 반도체 파운드리",
        "ASML": "기술 - 반도체 장비",
        "어도비": "기술 - 소프트웨어, 크리에이티브 툴",
        "오라클": "기술 - 데이터베이스, 클라우드",
        # 커머스
        "쿠팡": "커머스 - 이커머스, 물류",
        "알리바바": "커머스 - 이커머스, 클라우드",
        # 자동차
        "테슬라": "자동차 - 전기차, 자율주행",
        # 항공
        "보잉": "항공 - 항공기 제조",
        "델타항공": "항공 - 항공사",
        # 모빌리티
        "우버": "모빌리티 - 라이드셰어링, 배달",
        # 산업/물류
        "페덱스": "산업/물류 - 물류, 택배",
        # 리테일
        "월마트": "리테일 - 대형마트",
        "코스트코": "리테일 - 대형마트, 회원제",
        # 금융
        "JP모건": "금융(은행) - 투자은행",
        "BOA": "금융(은행) - 상업은행",
        "골드만삭스": "금융(IB) - 투자은행",
        # 결제
        "비자": "결제 - 신용카드 네트워크",
        "마스터카드": "결제 - 신용카드 네트워크",
        "페이팔": "온라인결제 - 전자결제",
        # 보험
        "AIG": "보험 - 보험사",
        # 소비재
        "코카콜라": "소비재 - 음료",
        "펩시": "소비재 - 음료",
        "맥도날드": "소비재 - 패스트푸드",
        "스타벅스": "소비재 - 커피 전문점",
        "나이키": "소비재 - 스포츠웨어",
        # 미디어/엔터
        "넷플릭스": "미디어 - 스트리밍",
        "디즈니": "미디어/엔터 - 엔터테인먼트",
        "소니": "게임+엔터 - 게임, 엔터테인먼트",
        # ETF
        "VOO": "ETF - S&P500",
        "SPY": "ETF - S&P500",
        "VTI": "ETF - 미국 전체",
        "QQQ": "ETF - 기술",
        "QQQM": "ETF - 기술",
        "TQQQ": "ETF - 레버리지",
        "SCHD": "ETF - 배당",
        "SOXX": "ETF - 반도체",
        "SMH": "ETF - 반도체",
        "ITA": "ETF - 산업/방산",
        "XLF": "ETF - 금융",
        "XLY": "ETF - 소비재",
        "XLP": "ETF - 필수소비재",
        "ICLN": "ETF - 친환경"
    }
    
    # 환경 변수에서 기업 목록 파일 경로 확인 (선택사항)
    company_list_file = os.getenv("COMPANY_LIST_FILE", None)
    if company_list_file and os.path.exists(company_list_file):
        print(f"📁 기업 목록 파일에서 로드: {company_list_file}")
        with open(company_list_file, "r", encoding="utf-8") as f:
            company_list = [line.strip() for line in f if line.strip()]
    
    print(f"🔄 기업 분석 시작: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"📊 분석 대상 기업: {len(company_list)}개")
    
    try:
        # MongoDB 연결
        client = get_mongodb_client()
        collection = get_mongodb_collection(client)
        
        # 기업 분석 및 저장
        stats = process_companies(
            company_names=company_list,
            company_info_dict=company_info_dict,  # 업종 정보 제공
            collection=collection
        )
        
        client.close()
        
        # Airflow XCom에 결과 저장
        context["ti"].xcom_push(key="total_companies", value=stats["total"])
        context["ti"].xcom_push(key="processed", value=stats["processed"])
        context["ti"].xcom_push(key="inserted", value=stats["inserted"])
        context["ti"].xcom_push(key="updated", value=stats["updated"])
        context["ti"].xcom_push(key="errors", value=stats["errors"])
        
        return {
            "status": "success",
            "total_companies": stats["total"],
            "processed": stats["processed"],
            "inserted": stats["inserted"],
            "updated": stats["updated"],
            "errors": stats["errors"],
        }
        
    except Exception as e:
        print(f"❌ 기업 분석 중 오류 발생: {str(e)}")
        import traceback
        traceback.print_exc()
        raise


# 기업 분석 작업 정의
analyze_task = PythonOperator(
    task_id="analyze_companies",
    python_callable=analyze_companies_task,
    dag=dag,
)

# 작업 실행
analyze_task

