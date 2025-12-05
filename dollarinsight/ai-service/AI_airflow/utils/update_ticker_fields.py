# -*- coding: utf-8 -*-

"""
기존 MongoDB 컬렉션에 ticker 필드를 추가하는 스크립트
- company_analysis: company_name 기반으로 ticker 추가
- investing_news: related_companies 기반으로 ticker 리스트 추가
"""

import os
import sys
from pathlib import Path
from dotenv import load_dotenv
from pymongo import MongoClient
from urllib.parse import quote_plus

# .env 파일 경로 명시적으로 지정
env_path = Path("/opt/airflow/.env")
if env_path.exists():
    load_dotenv(dotenv_path=env_path, override=True)
else:
    env_path_abs = Path("/opt/S13P31B205/ai-service/.env")
    if env_path_abs.exists():
        load_dotenv(dotenv_path=env_path_abs, override=True)
    else:
        load_dotenv(override=True)

# 환경 변수
# MONGODB_HOST는 docker-compose에서 설정되지만, 기본값이 mongodb일 수 있음
# 실제 컨테이너 이름은 dollar-insight-mongodb이므로 .env 파일에서 읽도록 함
MONGODB_HOST = os.getenv("MONGODB_HOST", "dollar-insight-mongodb")
MONGODB_PORT = int(os.getenv("MONGODB_PORT", "27017"))
MONGODB_DB = os.getenv("MONGODB_DB", "dollar_insight")
MONGODB_NEWS_COLLECTION = os.getenv("MONGODB_NEWS_COLLECTION", "investing_news")
MONGODB_COMPANY_COLLECTION = os.getenv("MONGODB_COMPANY_COLLECTION", "company_analysis")

# MongoDB 인증 정보
# .env 파일의 MONGODB_USER, MONGODB_PASSWORD 또는 MONGO_USER, MONGO_PASSWORD 사용
# docker-compose-airflow.yml에서 MONGO_USER, MONGO_PASSWORD로 설정되므로 둘 다 확인
_mongodb_user = os.getenv("MONGODB_USER") or os.getenv("MONGODB_USERNAME") or os.getenv("MONGO_USER")
_mongodb_pass = os.getenv("MONGODB_PASSWORD") or os.getenv("MONGO_PASSWORD")
MONGODB_USERNAME = _mongodb_user.strip() if _mongodb_user else None
MONGODB_PASSWORD = _mongodb_pass.strip() if _mongodb_pass else None
MONGODB_AUTH_SOURCE = os.getenv("MONGODB_AUTH_SOURCE", "admin").strip()

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


def get_mongodb_client() -> MongoClient:
    """MongoDB 클라이언트 생성 (인증 지원)"""
    if MONGODB_USERNAME and MONGODB_PASSWORD:
        username = quote_plus(str(MONGODB_USERNAME))
        password = quote_plus(str(MONGODB_PASSWORD))
        connection_string = f"mongodb://{username}:{password}@{MONGODB_HOST}:{MONGODB_PORT}/{MONGODB_DB}?authSource={MONGODB_AUTH_SOURCE}"
        return MongoClient(connection_string)
    else:
        return MongoClient(MONGODB_HOST, MONGODB_PORT)


def update_company_analysis_ticker():
    """company_analysis 컬렉션에 ticker 필드 추가"""
    print("=" * 70)
    print("🏢 company_analysis 컬렉션 ticker 필드 업데이트")
    print("=" * 70)

    client = get_mongodb_client()
    db = client[MONGODB_DB]
    collection = db[MONGODB_COMPANY_COLLECTION]

    # 전체 문서 수 확인
    total_count = collection.count_documents({})
    print(f"\n전체 문서 수: {total_count:,}개")

    if total_count == 0:
        print("⚠️ 업데이트할 문서가 없습니다.")
        client.close()
        return

    # ticker가 없는 문서만 필터링
    docs_without_ticker = collection.find({"ticker": {"$exists": False}})
    docs_to_update = list(docs_without_ticker)

    print(f"ticker 필드가 없는 문서: {len(docs_to_update)}개")

    if len(docs_to_update) == 0:
        print("✅ 모든 문서에 ticker 필드가 이미 존재합니다.")
        client.close()
        return

    # 업데이트 진행
    updated_count = 0
    not_found_count = 0

    for doc in docs_to_update:
        company_name = doc.get("company_name", "")
        if not company_name:
            print(f"  ⚠️ company_name이 없는 문서 건너뜀: {doc.get('_id', 'N/A')}")
            continue

        ticker = COMPANY_TICKER_MAPPING.get(company_name)

        if ticker:
            collection.update_one({"_id": doc["_id"]}, {"$set": {"ticker": ticker}})
            updated_count += 1
            if updated_count % 10 == 0:
                print(f"  진행 중... {updated_count}/{len(docs_to_update)}")
        else:
            not_found_count += 1
            print(f"  ⚠️ 티커 매핑 없음: {company_name}")

    print(f"\n✅ 업데이트 완료:")
    print(f"  - 업데이트된 문서: {updated_count}개")
    print(f"  - 티커 매핑 없음: {not_found_count}개")

    client.close()


def update_investing_news_ticker():
    """investing_news 컬렉션에 ticker 필드 추가"""
    print("\n" + "=" * 70)
    print("📰 investing_news 컬렉션 ticker 필드 업데이트")
    print("=" * 70)

    client = get_mongodb_client()
    db = client[MONGODB_DB]
    collection = db[MONGODB_NEWS_COLLECTION]

    # 전체 문서 수 확인
    total_count = collection.count_documents({})
    print(f"\n전체 문서 수: {total_count:,}개")

    if total_count == 0:
        print("⚠️ 업데이트할 문서가 없습니다.")
        client.close()
        return

    # ticker가 없는 문서만 필터링
    docs_without_ticker = collection.find({"ticker": {"$exists": False}})
    docs_to_update = list(docs_without_ticker)

    print(f"ticker 필드가 없는 문서: {len(docs_to_update)}개")

    if len(docs_to_update) == 0:
        print("✅ 모든 문서에 ticker 필드가 이미 존재합니다.")
        client.close()
        return

    # 업데이트 진행
    updated_count = 0
    empty_ticker_count = 0

    for doc in docs_to_update:
        related_companies = doc.get("related_companies", [])

        if not related_companies or not isinstance(related_companies, list):
            # related_companies가 없거나 빈 리스트인 경우 빈 리스트로 설정
            collection.update_one({"_id": doc["_id"]}, {"$set": {"ticker": []}})
            empty_ticker_count += 1
            continue

        # related_companies에서 티커 리스트 생성
        related_tickers = [
            COMPANY_TICKER_MAPPING.get(company)
            for company in related_companies
            if COMPANY_TICKER_MAPPING.get(company)
        ]

        collection.update_one(
            {"_id": doc["_id"]}, {"$set": {"ticker": related_tickers}}
        )
        updated_count += 1

        if updated_count % 10 == 0:
            print(f"  진행 중... {updated_count}/{len(docs_to_update)}")

    print(f"\n✅ 업데이트 완료:")
    print(f"  - 업데이트된 문서: {updated_count}개")
    print(f"  - 티커 없는 문서 (빈 리스트): {empty_ticker_count}개")

    client.close()


def main():
    """메인 실행 함수"""
    print("\n" + "=" * 70)
    print("🔄 MongoDB 컬렉션 ticker 필드 업데이트 시작")
    print("=" * 70)

    try:
        # company_analysis 컬렉션 업데이트
        update_company_analysis_ticker()

        # investing_news 컬렉션 업데이트
        update_investing_news_ticker()

        print("\n" + "=" * 70)
        print("✅ 모든 업데이트 완료!")
        print("=" * 70)

    except Exception as e:
        print(f"\n❌ 오류 발생: {str(e)}")
        import traceback

        traceback.print_exc()
        raise


if __name__ == "__main__":
    main()
