# -*- coding: utf-8 -*-

"""
기업 분석 데이터를 MongoDB에 저장하는 유틸리티
- FastAPI 서버를 통해 기업 분석 요청
- MongoDB에 저장 (중복 제거)
"""

import os
import sys
import json
from datetime import datetime
from typing import List, Dict, Optional
from pathlib import Path

# FastAPI 서버는 HTTP로 호출 (독립적 운영)
import pymongo
from pymongo import MongoClient
from pymongo.errors import DuplicateKeyError
from dotenv import load_dotenv
import requests

# .env 파일 경로 명시적으로 지정 (Airflow 컨테이너 내부 경로 사용)
# docker-compose에서 /opt/airflow/.env로 마운트됨
# override=True: 기존 환경 변수를 .env 파일의 값으로 덮어씀
env_path = Path("/opt/airflow/.env")
if env_path.exists():
    load_dotenv(dotenv_path=env_path, override=True)
else:
    # 절대 경로에서도 시도
    env_path_abs = Path("/opt/S13P31B205/ai-service/.env")
    if env_path_abs.exists():
        load_dotenv(dotenv_path=env_path_abs, override=True)
    else:
        # 기본 경로에서도 시도
        load_dotenv(override=True)

# ============================================================================
# 환경 변수
# ============================================================================

# MONGODB_HOST는 docker-compose에서 설정되지만, 기본값이 mongodb일 수 있음
# 실제 컨테이너 이름은 dollar-insight-mongodb이므로 .env 파일에서 읽도록 함
MONGODB_HOST = os.getenv("MONGODB_HOST", "dollar-insight-mongodb")
MONGODB_PORT = int(os.getenv("MONGODB_PORT", "27017"))
MONGODB_DB = os.getenv("MONGODB_DB", "dollar_insight")
MONGODB_COLLECTION = os.getenv("MONGODB_COMPANY_COLLECTION", "company_analysis")
# MongoDB 인증 정보 (선택사항)
# .env 파일의 MONGODB_USER, MONGODB_PASSWORD 또는 MONGO_USER, MONGO_PASSWORD 사용
# docker-compose-airflow.yml에서 MONGO_USER, MONGO_PASSWORD로 설정되므로 둘 다 확인
# strip()으로 개행 문자 제거
_mongodb_user = (
    os.getenv("MONGODB_USER")
    or os.getenv("MONGODB_USERNAME")
    or os.getenv("MONGO_USER")
)
_mongodb_pass = os.getenv("MONGODB_PASSWORD") or os.getenv("MONGO_PASSWORD")
MONGODB_USERNAME = _mongodb_user.strip() if _mongodb_user else None
MONGODB_PASSWORD = _mongodb_pass.strip() if _mongodb_pass else None
MONGODB_AUTH_SOURCE = os.getenv("MONGODB_AUTH_SOURCE", "admin").strip()

# FastAPI 서버 설정
FASTAPI_URL = os.getenv("FASTAPI_URL", "http://localhost:8000")

# 페르소나 목록
PERSONAS = ["희열", "덕수", "지율", "테오", "민지"]

# 페르소나 이름을 영문 필드명으로 매핑 (뉴스 분석과 동일한 형식)
PERSONA_FIELD_MAP = {
    "희열": "heuyeol",
    "덕수": "deoksu",
    "지율": "jiyul",
    "테오": "teo",
    "민지": "minji",
}

# 기업명 -> 티커 매핑
COMPANY_TICKER_MAPPING = {
    # 기술 기업
    "애플": "AAPL",
    "마이크로소프트": "MSFT",
    "구글(알파벳)": "GOOGL",
    "아마존": "AMZN",
    "메타": "META",
    "엔비디아": "NVDA",
    "AMD": "AMD",
    "인텔": "INTC",
    "TSMC": "TSM",
    "ASML": "ASML",
    "어도비": "ADBE",
    "오라클": "ORCL",
    # 커머스
    "쿠팡": "CPNG",
    "알리바바": "BABA",
    # 자동차
    "테슬라": "TSLA",
    # 항공
    "보잉": "BA",
    "델타항공": "DAL",
    # 모빌리티
    "우버": "UBER",
    # 산업/물류
    "페덱스": "FDX",
    # 리테일
    "월마트": "WMT",
    "코스트코": "COST",
    # 금융
    "JP모건": "JPM",
    "BOA": "BAC",
    "골드만삭스": "GS",
    # 결제
    "비자": "V",
    "마스터카드": "MA",
    "페이팔": "PYPL",
    # 보험
    "AIG": "AIG",
    # 소비재
    "코카콜라": "KO",
    "펩시": "PEP",
    "맥도날드": "MCD",
    "스타벅스": "SBUX",
    "나이키": "NKE",
    # 미디어/엔터
    "넷플릭스": "NFLX",
    "디즈니": "DIS",
    "소니": "SONY",
    # ETF (이미 티커가 이름)
    "VOO": "VOO",
    "SPY": "SPY",
    "VTI": "VTI",
    "QQQ": "QQQ",
    "QQQM": "QQQM",
    "TQQQ": "TQQQ",
    "SCHD": "SCHD",
    "SOXX": "SOXX",
    "SMH": "SMH",
    "ITA": "ITA",
    "XLF": "XLF",
    "XLY": "XLY",
    "XLP": "XLP",
    "ICLN": "ICLN",
}


# ============================================================================
# MongoDB 연결
# ============================================================================


def get_mongodb_client() -> MongoClient:
    """MongoDB 클라이언트 생성 (인증 지원)"""
    if MONGODB_USERNAME and MONGODB_PASSWORD:
        # 인증 정보가 있으면 인증 포함 (URL 인코딩 적용)
        from urllib.parse import quote_plus

        username = quote_plus(str(MONGODB_USERNAME))
        password = quote_plus(str(MONGODB_PASSWORD))
        connection_string = f"mongodb://{username}:{password}@{MONGODB_HOST}:{MONGODB_PORT}/{MONGODB_DB}?authSource={MONGODB_AUTH_SOURCE}"
        return MongoClient(connection_string)
    else:
        # 인증 정보가 없으면 기본 연결
        return MongoClient(MONGODB_HOST, MONGODB_PORT)


def get_mongodb_collection(client: MongoClient = None):
    """MongoDB 컬렉션 가져오기"""
    if client is None:
        client = get_mongodb_client()
    db = client[MONGODB_DB]
    collection = db[MONGODB_COLLECTION]

    # company_name + analyzed_date를 기준으로 unique 인덱스 생성 (업데이트 시 기준으로 사용)
    # 인증 오류가 발생해도 컬렉션은 반환하도록 try-except 처리
    try:
        collection.create_index(
            [("company_name", 1), ("analyzed_date", 1)], unique=True
        )
    except Exception as e:
        # 인증 오류나 권한 오류가 발생해도 컬렉션은 반환 (인덱스는 나중에 수동으로 생성 가능)
        error_msg = str(e).lower()
        if (
            "authentication" in error_msg
            or "unauthorized" in error_msg
            or "requires authentication" in error_msg
        ):
            print(f"⚠️  인덱스 생성 중 인증 오류 발생 (무시하고 진행): {e}")
        else:
            print(f"⚠️  인덱스 생성 중 오류 발생 (무시하고 진행): {e}")

    return collection


# ============================================================================
# FastAPI 서버를 통한 기업 분석
# ============================================================================


def analyze_company_via_api(company_name: str, company_info: str = "") -> Dict:
    """
    FastAPI 서버를 통해 기업 분석
    재시도 로직 포함 (최대 3회, 타임아웃 180초)

    Returns:
        {
            "company_name": str,
            "heuyeol": str,  # FastAPI 응답 형식 (process_company에서 persona_heuyeol로 변환됨)
            "deoksu": str,   # FastAPI 응답 형식 (process_company에서 persona_deoksu로 변환됨)
            "jiyul": str,   # FastAPI 응답 형식 (process_company에서 persona_jiyul로 변환됨)
            "teo": str,     # FastAPI 응답 형식 (process_company에서 persona_teo로 변환됨)
            "minji": str,    # FastAPI 응답 형식 (process_company에서 persona_minji로 변환됨)
            "analyzed_at": str
        }
    """
    import time

    max_retries = 3
    timeout_seconds = 180  # 180초 타임아웃 (LLM 분석 시간 고려)
    retry_delay = 5  # 재시도 전 대기 시간 (초)

    fastapi_field_mapping = {
        "heuyeol": "희열",
        "deoksu": "덕수",
        "jiyul": "지율",
        "teo": "테오",
        "minji": "민지",
    }
    persona_english_mapping = {
        "희열": "heuyeol",
        "덕수": "deoksu",
        "지율": "jiyul",
        "테오": "teo",
        "민지": "minji",
    }

    for attempt in range(max_retries):
        try:
            response = requests.post(
                f"{FASTAPI_URL}/analyze-company",
                json={"company_name": company_name, "company_info": company_info},
                timeout=timeout_seconds,
            )

            if response.status_code == 200:
                return response.json()
            else:
                print(f"⚠️ FastAPI 오류 (HTTP {response.status_code}): {response.text}")
                if attempt < max_retries - 1:
                    print(f"   재시도 중... ({attempt + 1}/{max_retries})")
                    time.sleep(retry_delay)
                    continue
                result = {
                    "company_name": company_name,
                    "analyzed_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                }
                for eng_name, kor_name in fastapi_field_mapping.items():
                    result[eng_name] = f"{kor_name} 분석 실패"
                return result
        except requests.exceptions.Timeout:
            print(f"⚠️ FastAPI 타임아웃 (읽기 타임아웃: {timeout_seconds}초)")
            if attempt < max_retries - 1:
                print(f"   재시도 중... ({attempt + 1}/{max_retries})")
                time.sleep(retry_delay)
                continue
            else:
                print("   최대 재시도 횟수 초과")
                result = {
                    "company_name": company_name,
                    "analyzed_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                }
                for korean_name, english_name in persona_english_mapping.items():
                    result[english_name] = f"{korean_name} 분석 실패 (타임아웃)"
                return result
        except requests.exceptions.ConnectionError:
            print(f"⚠️ FastAPI 서버에 연결할 수 없습니다: {FASTAPI_URL}")
            if attempt < max_retries - 1:
                print(f"   재시도 중... ({attempt + 1}/{max_retries})")
                time.sleep(retry_delay)
                continue
            else:
                print("   FastAPI 서버가 실행 중인지 확인하세요.")
                result = {
                    "company_name": company_name,
                    "analyzed_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                }
                for korean_name, english_name in persona_english_mapping.items():
                    result[english_name] = f"{korean_name} 분석 실패 (서버 연결 실패)"
                return result
        except Exception as e:
            print(f"⚠️ FastAPI 호출 오류: {str(e)}")
            if attempt < max_retries - 1:
                print(f"   재시도 중... ({attempt + 1}/{max_retries})")
                time.sleep(retry_delay)
                continue
            else:
                result = {
                    "company_name": company_name,
                    "analyzed_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                }
                for korean_name, english_name in persona_english_mapping.items():
                    result[english_name] = f"{korean_name} 분석 실패"
                return result

    # 모든 재시도 실패 시
    result = {
        "company_name": company_name,
        "analyzed_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
    }
    for korean_name, english_name in persona_english_mapping.items():
        result[english_name] = f"{korean_name} 분석 실패 (최대 재시도 횟수 초과)"
    return result


# ============================================================================
# 데이터 처리 및 저장
# ============================================================================


def process_company(company_name: str, company_info: str = "") -> Dict:
    """기업 분석 및 가공"""
    print(f"🏢 분석 중: {company_name}")

    # FastAPI 서버를 통해 분석
    analysis_result = analyze_company_via_api(company_name, company_info)

    # 분석 날짜 추출 (YYYY-MM-DD 형식)
    analyzed_at = analysis_result.get(
        "analyzed_at", datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    )
    analyzed_date = analyzed_at.split(" ")[0]  # 날짜만 추출

    # 가공된 데이터 구성
    # 뉴스 분석과 동일한 형식으로 페르소나별 개별 컬럼 생성 (persona_hyeolyeol, persona_deoksu, persona_jiyul, persona_teo, persona_minji)
    processed = {
        "company_name": company_name,
        "company_info": company_info,
        "ticker": COMPANY_TICKER_MAPPING.get(company_name, ""),  # 티커 추가
        "analyzed_at": analyzed_at,
        "analyzed_date": analyzed_date,  # 중복 체크용
        "created_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
    }

    # FastAPI 응답 필드명 -> 페르소나 이름 매핑
    fastapi_to_persona = {
        "heuyeol": "희열",
        "deoksu": "덕수",
        "jiyul": "지율",
        "teo": "테오",
        "minji": "민지",
    }

    # 각 페르소나를 persona_ 접두사를 붙인 필드명으로 저장 (뉴스 분석과 동일)
    for persona_name in PERSONAS:
        persona_field = f"persona_{PERSONA_FIELD_MAP[persona_name]}"
        # FastAPI 응답에서 해당 페르소나의 분석 내용 가져오기
        fastapi_field = [
            eng for eng, kor in fastapi_to_persona.items() if kor == persona_name
        ][0]
        processed[persona_field] = analysis_result.get(
            fastapi_field, f"{persona_name} 분석 생성 실패"
        )

    print(f"  ✓ 분석 완료")

    return processed


def save_to_mongodb(companies_data: List[Dict], collection=None) -> Dict[str, int]:
    """가공된 기업 분석 데이터를 MongoDB에 저장 (업데이트 또는 삽입)"""
    if collection is None:
        client = get_mongodb_client()
        collection = get_mongodb_collection(client)
        need_close = True
    else:
        need_close = False

    stats = {"total": len(companies_data), "inserted": 0, "updated": 0, "errors": 0}

    for company_data in companies_data:
        try:
            # company_name + analyzed_date를 기준으로 업데이트 또는 삽입
            filter_query = {
                "company_name": company_data["company_name"],
                "analyzed_date": company_data["analyzed_date"],
            }

            # upsert=True: 문서가 없으면 삽입, 있으면 업데이트
            result = collection.update_one(
                filter_query, {"$set": company_data}, upsert=True
            )

            if result.upserted_id:
                stats["inserted"] += 1
                print(
                    f"  ✅ 신규 저장: {company_data['company_name']} ({company_data.get('analyzed_date', 'N/A')})"
                )
            else:
                stats["updated"] += 1
                print(
                    f"  🔄 업데이트 완료: {company_data['company_name']} ({company_data.get('analyzed_date', 'N/A')})"
                )
        except Exception as e:
            stats["errors"] += 1
            print(
                f"  ❌ 오류 발생: {company_data.get('company_name', 'Unknown')} - {str(e)}"
            )

    if need_close:
        client.close()

    return stats


# ============================================================================
# 메인 함수
# ============================================================================


def process_companies(
    company_names: List[str], company_info_dict: Dict[str, str] = None, collection=None
) -> Dict[str, int]:
    """
    여러 기업을 분석하고 MongoDB에 저장

    Args:
        company_names: 기업명 리스트
        company_info_dict: 기업명별 추가 정보 (선택사항)
        collection: MongoDB 컬렉션 (None이면 새로 연결)

    Returns:
        통계 정보
    """
    print("=" * 70)
    print("🏢 기업 분석 MongoDB 저장 프로세스 시작")
    print("=" * 70)

    # MongoDB 연결
    if collection is None:
        print(
            f"\n1️⃣ MongoDB 연결 중: {MONGODB_HOST}:{MONGODB_PORT}/{MONGODB_DB}/{MONGODB_COLLECTION}"
        )
        client = get_mongodb_client()
        collection = get_mongodb_collection(client)
        need_close = True
    else:
        need_close = False

    # 오늘 날짜
    today = datetime.now().strftime("%Y-%m-%d")

    # 매일 모든 기업을 최신화하기 위해 중복 체크 제거
    # 모든 기업을 분석하여 업데이트 또는 삽입
    print(f"   분석 대상: {len(company_names)}개 (모두 최신화)")

    # 각 기업 분석
    print(f"\n2️⃣ 기업 분석 중 ({len(company_names)}개)...")
    processed_companies = []
    for idx, company_name in enumerate(company_names, 1):
        print(f"\n[{idx}/{len(company_names)}]")
        company_info = (
            company_info_dict.get(company_name, "") if company_info_dict else ""
        )
        try:
            processed = process_company(company_name, company_info)
            processed_companies.append(processed)
        except Exception as e:
            print(f"  ❌ 분석 실패: {str(e)}")
            continue

    # MongoDB에 저장
    print(f"\n3️⃣ MongoDB 저장 중 ({len(processed_companies)}개)...")
    stats = save_to_mongodb(processed_companies, collection)

    if need_close:
        client.close()

    # 결과 출력
    print("\n" + "=" * 70)
    print("📊 처리 결과")
    print("=" * 70)
    print(f"전체 기업: {len(company_names)}개")
    print(f"분석 완료: {len(processed_companies)}개")
    print(f"신규 저장: {stats['inserted']}개")
    print(f"업데이트: {stats['updated']}개")
    print(f"오류 발생: {stats['errors']}개")
    print("=" * 70)

    return {"total": len(company_names), "processed": len(processed_companies), **stats}


def main():
    """메인 실행 함수"""
    # 테스트용 기업 목록 (50개)
    test_companies = [
        "삼성전자",
        "SK하이닉스",
        "LG전자",
        "현대자동차",
        "기아",
        "네이버",
        "카카오",
        "KT",
        "SK텔레콤",
        "LG유플러스",
        "애플",
        "구글",
        "아마존",
        "마이크로소프트",
        "테슬라",
        "엔비디아",
        "페이스북",
        "넷플릭스",
        "인텔",
        "AMD",
        "삼성SDI",
        "LG화학",
        "포스코",
        "롯데",
        "CJ",
        "신한지주",
        "KB금융",
        "하나금융",
        "우리금융",
        "NH투자증권",
        "셀트리온",
        "한미약품",
        "유한양행",
        "대웅제약",
        "일양약품",
        "코스피200",
        "코스닥",
        "나스닥",
        "S&P500",
        "다우존스",
        "비트코인",
        "이더리움",
        "리플",
        "도지코인",
        "솔라나",
        "KOSPI",
        "KOSDAQ",
        "나스닥100",
        "S&P500지수",
        "다우존스30",
    ]

    # 프로세스 실행
    stats = process_companies(test_companies)

    print("\n✅ 프로세스 완료!")
    print(json.dumps(stats, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
