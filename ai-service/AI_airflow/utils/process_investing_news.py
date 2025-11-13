# -*- coding: utf-8 -*-

"""
Investing.com 뉴스 데이터를 MongoDB에 저장하는 유틸리티
- 뉴스 요약 생성
- 페르소나 5명 분석 (FastAPI prompts 사용)
- 영향 미칠 기업 목록 추출
- 중복 제거 로직
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
import openai

load_dotenv()

# ============================================================================
# 환경 변수
# ============================================================================

MONGODB_HOST = os.getenv("MONGODB_HOST", "localhost")
MONGODB_PORT = int(os.getenv("MONGODB_PORT", "27017"))
MONGODB_DB = os.getenv("MONGODB_DB", "dollar_insight")
# 컬렉션 2개: 뉴스 기본 정보, 페르소나 분석
MONGODB_NEWS_COLLECTION = os.getenv("MONGODB_NEWS_COLLECTION", "investing_news")
MONGODB_PERSONA_COLLECTION = os.getenv(
    "MONGODB_PERSONA_COLLECTION", "news_persona_analysis"
)
# MongoDB 인증 정보 (선택사항)
# .env 파일의 MONGODB_USER, MONGODB_PASSWORD 사용
# strip()으로 개행 문자 제거
_mongodb_user = os.getenv("MONGODB_USER", os.getenv("MONGODB_USERNAME", None))
_mongodb_pass = os.getenv("MONGODB_PASSWORD", None)
# 빈 문자열도 None으로 처리 (인증 없이 연결 시도 방지)
MONGODB_USERNAME = (
    _mongodb_user.strip() if _mongodb_user and _mongodb_user.strip() else None
)
MONGODB_PASSWORD = (
    _mongodb_pass.strip() if _mongodb_pass and _mongodb_pass.strip() else None
)
MONGODB_AUTH_SOURCE = os.getenv("MONGODB_AUTH_SOURCE", "admin").strip()

# FastAPI 서버 설정
FASTAPI_URL = os.getenv("FASTAPI_URL", "http://localhost:8000")

# 페르소나 목록
PERSONAS = ["희열", "덕수", "지율", "테오", "민지"]

# 페르소나 이름을 영문 필드명으로 매핑
PERSONA_FIELD_MAP = {
    "희열": "hyeolyeol",
    "덕수": "deoksu",
    "지율": "jiyul",
    "테오": "teo",
    "민지": "minji",
}

# FastAPI에서 반환하는 영문 키를 한글로 매핑
PERSONA_ENGLISH_TO_KOREAN = {
    "Heeyule": "희열",
    "Ducksu": "덕수",
    "Jiyule": "지율",
    "Taeo": "테오",
    "Minji": "민지",
}

# 추적 대상 기업/ETF 목록 (36개 기업 + 14개 ETF)
TRACKED_COMPANIES = [
    # 기술 기업 (12개)
    "애플",
    "마이크로소프트",
    "구글(알파벳)",
    "아마존",
    "메타",
    "엔비디아",
    "AMD",
    "인텔",
    "TSMC",
    "ASML",
    "어도비",
    "오라클",
    # 커머스 (2개)
    "쿠팡",
    "알리바바",
    # 자동차 (1개)
    "테슬라",
    # 항공 (2개)
    "보잉",
    "델타항공",
    # 모빌리티 (1개)
    "우버",
    # 산업/물류 (1개)
    "페덱스",
    # 리테일 (2개)
    "월마트",
    "코스트코",
    # 금융 (3개)
    "JP모건",
    "BOA",
    "골드만삭스",
    # 결제 (3개)
    "비자",
    "마스터카드",
    "페이팔",
    # 보험 (1개)
    "AIG",
    # 소비재 (5개)
    "코카콜라",
    "펩시",
    "맥도날드",
    "스타벅스",
    "나이키",
    # 미디어/엔터 (3개)
    "넷플릭스",
    "디즈니",
    "소니",
    # ETF (14개)
    "VOO",
    "SPY",
    "VTI",
    "QQQ",
    "QQQM",
    "TQQQ",
    "SCHD",
    "SOXX",
    "SMH",
    "ITA",
    "XLF",
    "XLY",
    "XLP",
    "ICLN",
]

# 기업명 매핑 (영어/다양한 표기 -> 한글)
COMPANY_NAME_MAPPING = {
    # 기술 기업
    "apple": "애플",
    "aapl": "애플",
    "microsoft": "마이크로소프트",
    "msft": "마이크로소프트",
    "google": "구글(알파벳)",
    "alphabet": "구글(알파벳)",
    "googl": "구글(알파벳)",
    "goog": "구글(알파벳)",
    "amazon": "아마존",
    "amzn": "아마존",
    "meta": "메타",
    "facebook": "메타",
    "fb": "메타",
    "nvidia": "엔비디아",
    "nvda": "엔비디아",
    "amd": "AMD",
    "intel": "인텔",
    "intc": "인텔",
    "tsmc": "TSMC",
    "asml": "ASML",
    "adobe": "어도비",
    "adbe": "어도비",
    "oracle": "오라클",
    "orcl": "오라클",
    # 커머스
    "coupang": "쿠팡",
    "cpng": "쿠팡",
    "alibaba": "알리바바",
    "baba": "알리바바",
    # 자동차
    "tesla": "테슬라",
    "tsla": "테슬라",
    # 항공
    "boeing": "보잉",
    "ba": "보잉",
    "delta": "델타항공",
    "dal": "델타항공",
    # 모빌리티
    "uber": "우버",
    # 산업/물류
    "fedex": "페덱스",
    "fdx": "페덱스",
    # 리테일
    "walmart": "월마트",
    "wmt": "월마트",
    "costco": "코스트코",
    "cost": "코스트코",
    # 금융
    "jpmorgan": "JP모건",
    "jpm": "JP모건",
    "jp morgan": "JP모건",
    "bank of america": "BOA",
    "boa": "BOA",
    "bac": "BOA",
    "goldman sachs": "골드만삭스",
    "gs": "골드만삭스",
    # 결제
    "visa": "비자",
    "v": "비자",
    "mastercard": "마스터카드",
    "ma": "마스터카드",
    "paypal": "페이팔",
    "pypl": "페이팔",
    # 보험
    "aig": "AIG",
    # 소비재
    "coca-cola": "코카콜라",
    "coca cola": "코카콜라",
    "ko": "코카콜라",
    "pepsi": "펩시",
    "pep": "펩시",
    "mcdonald": "맥도날드",
    "mcdonalds": "맥도날드",
    "mcd": "맥도날드",
    "starbucks": "스타벅스",
    "sbux": "스타벅스",
    "nike": "나이키",
    "nke": "나이키",
    # 미디어/엔터
    "netflix": "넷플릭스",
    "nflx": "넷플릭스",
    "disney": "디즈니",
    "dis": "디즈니",
    "sony": "소니",
    "sne": "소니",
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


def get_mongodb_news_collection(client: MongoClient = None):
    """뉴스 기본 정보 컬렉션 가져오기"""
    if client is None:
        client = get_mongodb_client()
    db = client[MONGODB_DB]
    collection = db[MONGODB_NEWS_COLLECTION]

    # URL을 기준으로 unique 인덱스 생성 (중복 방지)
    collection.create_index("url", unique=True)

    return collection


def get_mongodb_persona_collection(client: MongoClient = None):
    """뉴스 페르소나 분석 컬렉션 가져오기"""
    if client is None:
        client = get_mongodb_client()
    db = client[MONGODB_DB]
    collection = db[MONGODB_PERSONA_COLLECTION]

    # news_id를 기준으로 unique 인덱스 생성 (중복 방지)
    collection.create_index("news_id", unique=True)
    # news_url도 인덱스로 유지 (기존 호환성 및 검색용)
    collection.create_index("news_url")

    return collection


# ============================================================================
# LLM을 통한 관련 기업 추출
# ============================================================================


def extract_related_companies_with_llm(title: str, content: str) -> List[str]:
    """
    LLM을 사용하여 뉴스에서 관련 기업/ETF 추출 (최대 5개)

    Args:
        title: 뉴스 제목
        content: 뉴스 본문

    Returns:
        관련 기업/ETF 목록 (최대 5개, 없으면 빈 리스트)
    """
    OPENAI_API_KEY = os.getenv("GMS_API_KEY")
    GMS_BASE_URL = "https://gms.ssafy.io/gmsapi/api.openai.com/v1"

    if not OPENAI_API_KEY:
        print("⚠️ GMS_API_KEY가 설정되지 않았습니다. LLM 기업 추출을 건너뜁니다.")
        return []

    try:
        client = openai.OpenAI(api_key=OPENAI_API_KEY, base_url=GMS_BASE_URL)

        # 추적 대상 기업 목록을 문자열로 변환
        tracked_companies_str = ", ".join(TRACKED_COMPANIES)

        # LLM 프롬프트
        prompt = f"""다음 뉴스 기사에서 직접 언급되거나 영향을 받을 수 있는 기업/ETF를 추출하세요.

## 뉴스 기사
제목: {title}
내용: {content[:2000]}

## 추적 대상 기업/ETF 목록
{tracked_companies_str}

## 요청
위 목록 중에서 뉴스에 직접 언급되거나 영향을 받을 수 있는 기업/ETF만 선택하세요 (최대 5개).
뉴스에 직접 언급된 기업이 없거나 관련이 없으면 빈 배열을 반환하세요.
정확하게 매칭되는 기업만 선택하고, 확실하지 않으면 포함하지 마세요.

## 응답 형식
{{"companies": ["애플", "테슬라"]}}

JSON만 응답하세요:"""

        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {
                    "role": "system",
                    "content": "You are a helpful assistant that extracts company names from news. Always respond in valid JSON format only. Be precise and only include companies that are clearly mentioned or directly affected.",
                },
                {"role": "user", "content": prompt},
            ],
            max_tokens=200,
            temperature=0.3,
            response_format={"type": "json_object"},
        )

        result = json.loads(response.choices[0].message.content.strip())
        extracted_companies = result.get("companies", [])

        # 기업명 매칭 (정확도 향상)
        matched_companies = []
        tracked_lower = {c.lower(): c for c in TRACKED_COMPANIES}

        for company in extracted_companies:
            company_clean = company.strip()
            company_lower = company_clean.lower()

            # 직접 매칭
            if company_lower in tracked_lower:
                matched = tracked_lower[company_lower]
                if matched not in matched_companies:
                    matched_companies.append(matched)
            # 매핑 테이블 확인
            elif company_lower in COMPANY_NAME_MAPPING:
                matched = COMPANY_NAME_MAPPING[company_lower]
                if matched not in matched_companies:
                    matched_companies.append(matched)

        return matched_companies[:5]

    except Exception as e:
        print(f"⚠️ LLM 기업 추출 오류: {str(e)}")
        return []


# ============================================================================
# FastAPI 서버를 통한 뉴스 분석
# ============================================================================


def analyze_news_via_api(title: str, content: str) -> Dict:
    """
    FastAPI 서버를 통해 뉴스 분석 (한 번의 호출로 모든 분석 수행)

    Returns:
        {
            "summary": str,
            "persona_analyses": {persona: analysis},
            "companies": [str]
        }
    """
    try:
        response = requests.post(
            f"{FASTAPI_URL}/analyze-news",
            json={"title": title, "content": content},
            timeout=60,  # 60초 타임아웃
        )

        if response.status_code == 200:
            return response.json()
        else:
            print(f"⚠️ FastAPI 오류 (HTTP {response.status_code}): {response.text}")
            return {
                "summary": "요약 생성 실패",
                "persona_analyses": {p: f"{p} 분석 실패" for p in PERSONAS},
                "companies": [],
            }
    except requests.exceptions.ConnectionError:
        print(f"⚠️ FastAPI 서버에 연결할 수 없습니다: {FASTAPI_URL}")
        print("   FastAPI 서버가 실행 중인지 확인하세요.")
        return {
            "summary": "요약 생성 실패 (서버 연결 실패)",
            "persona_analyses": {
                p: f"{p} 분석 실패 (서버 연결 실패)" for p in PERSONAS
            },
            "companies": [],
        }
    except Exception as e:
        print(f"⚠️ FastAPI 호출 오류: {str(e)}")
        return {
            "summary": "요약 생성 실패",
            "persona_analyses": {p: f"{p} 분석 실패" for p in PERSONAS},
            "companies": [],
        }


# ============================================================================
# 데이터 처리 및 저장
# ============================================================================


def process_news_article(article: Dict) -> tuple:
    """
    뉴스 기사 가공 (2개 컬렉션으로 분리)

    Returns:
        (news_data, persona_data) 튜플
        - news_data: 뉴스 기본 정보
        - persona_data: 페르소나 분석 정보 (news_id는 저장 시 추가됨)
    """
    title = article.get("title", "")
    content = article.get("content", "")
    url = article.get("url", "")
    date = article.get("date", "")
    crawled_at = article.get("crawled_at", "")

    print(f"📰 처리 중: {title[:50]}...")

    # FastAPI 서버를 통해 한 번에 모든 분석 수행
    analysis_result = analyze_news_via_api(title, content)

    summary = analysis_result.get("summary", "요약 생성 실패")
    # FastAPI는 영문 키로 반환하므로 한글로 변환
    persona_analyses_english = analysis_result.get("persona_analyses", {})
    persona_analyses = {
        PERSONA_ENGLISH_TO_KOREAN.get(eng_key, eng_key): value
        for eng_key, value in persona_analyses_english.items()
    }

    print(f"  ✓ 요약 완료")
    print(f"  ✓ 페르소나 5명 분석 완료")

    # LLM을 사용하여 관련 기업 추출 (최대 5개)
    related_companies = extract_related_companies_with_llm(title, content)

    if related_companies:
        print(f"  ✓ 관련 기업 추출: {len(related_companies)}개 - {related_companies}")
    else:
        print(f"  ✓ 관련 기업 없음")

    # 관련 기업의 티커 리스트 생성 (빈 문자열 제외)
    related_tickers = [
        COMPANY_TICKER_MAPPING.get(company)
        for company in related_companies
        if COMPANY_TICKER_MAPPING.get(company)
    ]

    # 1. 뉴스 기본 정보 (컬렉션 1)
    news_data = {
        "title": title,
        "content": content,
        "url": url,
        "date": date,
        "summary": summary,  # 요약 추가
        "related_companies": related_companies,  # 관련 기업/ETF 목록 추가
        "ticker": related_tickers,  # 관련 기업/ETF 티커 리스트 추가
        "crawled_at": crawled_at,
        "created_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        # persona_analysis_id는 저장 후 업데이트됨
    }

    # 2. 페르소나 분석 정보 (컬렉션 2)
    # news_id는 저장 시 뉴스의 _id로 설정됨
    # 각 페르소나별로 별도 컬럼 생성 (persona_hyeolyeol, persona_deoksu, persona_jiyul, persona_teo, persona_minji)
    persona_data = {
        "news_url": url,  # 호환성을 위해 유지 (검색용)
        "analyzed_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        # news_id는 저장 시 추가됨
    }

    # 각 페르소나별로 별도 컬럼으로 저장 (영문 필드명 사용)
    for persona_name in PERSONAS:
        persona_field = f"persona_{PERSONA_FIELD_MAP[persona_name]}"
        # 분석 결과 저장
        persona_data[persona_field] = persona_analyses.get(
            persona_name, f"{persona_name} 분석 실패"
        )

    return news_data, persona_data


def save_to_mongodb(
    news_list: List[Dict],
    persona_list: List[Dict],
    news_collection=None,
    persona_collection=None,
) -> Dict[str, int]:
    """
    가공된 뉴스 데이터를 2개 컬렉션에 저장 (중복 제거, _id 기반 참조/역참조)

    Args:
        news_list: 뉴스 기본 정보 리스트
        persona_list: 페르소나 분석 정보 리스트 (news_list와 같은 순서)
        news_collection: 뉴스 컬렉션
        persona_collection: 페르소나 분석 컬렉션
    """
    if news_collection is None or persona_collection is None:
        client = get_mongodb_client()
        if news_collection is None:
            news_collection = get_mongodb_news_collection(client)
        if persona_collection is None:
            persona_collection = get_mongodb_persona_collection(client)
        need_close = True
    else:
        need_close = False

    stats = {
        "total": len(news_list),
        "news_inserted": 0,
        "news_duplicates": 0,
        "persona_inserted": 0,
        "persona_duplicates": 0,
        "errors": 0,
    }

    # 뉴스와 페르소나를 쌍으로 처리 (같은 인덱스)
    for idx, (news_data, persona_data) in enumerate(zip(news_list, persona_list)):
        news_id = None
        persona_analysis_id = None

        # 1. 뉴스 기본 정보 저장 (또는 기존 뉴스 찾기)
        try:
            # 중복 체크: URL로 기존 뉴스 찾기
            existing_news = news_collection.find_one({"url": news_data.get("url")})

            if existing_news:
                # 기존 뉴스가 있으면 그 _id 사용
                news_id = existing_news["_id"]
                stats["news_duplicates"] += 1
                print(
                    f"  ⚠️ 뉴스 중복 건너뜀: {news_data['title'][:50]}... (기존 ID 사용)"
                )
            else:
                # 새 뉴스 저장
                result = news_collection.insert_one(news_data)
                news_id = result.inserted_id
                stats["news_inserted"] += 1
                print(
                    f"  ✅ 뉴스 저장 완료: {news_data['title'][:50]}... (ID: {news_id})"
                )
        except Exception as e:
            stats["errors"] += 1
            print(f"  ❌ 뉴스 저장 오류: {str(e)}")
            continue

        # 2. 페르소나 분석 정보 저장 (news_id 포함)
        if news_id:
            try:
                # persona_data에 news_id 추가
                persona_data["news_id"] = news_id

                # 중복 체크: news_id로 기존 페르소나 분석 찾기
                existing_persona = persona_collection.find_one({"news_id": news_id})

                if existing_persona:
                    # 기존 페르소나 분석이 있으면 그 _id 사용
                    persona_analysis_id = existing_persona["_id"]
                    stats["persona_duplicates"] += 1
                    print(
                        f"  ⚠️ 페르소나 분석 중복 건너뜀: {persona_data.get('news_url', 'N/A')} (기존 ID 사용)"
                    )
                else:
                    # 새 페르소나 분석 저장
                    result = persona_collection.insert_one(persona_data)
                    persona_analysis_id = result.inserted_id
                    stats["persona_inserted"] += 1
                    print(
                        f"  ✅ 페르소나 분석 저장 완료: {persona_data.get('news_url', 'N/A')} (ID: {persona_analysis_id})"
                    )

                # 3. 뉴스에 persona_analysis_id 역참조 추가
                if persona_analysis_id:
                    try:
                        news_collection.update_one(
                            {"_id": news_id},
                            {"$set": {"persona_analysis_id": persona_analysis_id}},
                        )
                        print(
                            f"  ✅ 뉴스에 페르소나 분석 ID 역참조 추가: {persona_analysis_id}"
                        )
                    except Exception as e:
                        print(f"  ⚠️ 뉴스 역참조 업데이트 실패: {str(e)}")
            except Exception as e:
                stats["errors"] += 1
                print(f"  ❌ 페르소나 분석 저장 오류: {str(e)}")

    if need_close:
        client.close()

    return stats


# ============================================================================
# 메인 함수
# ============================================================================


def load_investing_news_json(json_path: str) -> List[Dict]:
    """investing_news.json 파일 로드"""
    json_path = Path(json_path)
    if not json_path.exists():
        raise FileNotFoundError(f"파일을 찾을 수 없습니다: {json_path}")

    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    if not isinstance(data, list):
        raise ValueError(f"JSON 파일은 리스트 형태여야 합니다: {json_path}")

    return data


def process_and_save(
    json_path: str, news_collection=None, persona_collection=None
) -> Dict[str, int]:
    """
    전체 프로세스 실행: JSON 로드 → 가공 → MongoDB 저장 (2개 컬렉션)

    Args:
        json_path: investing_news.json 파일 경로
        news_collection: 뉴스 컬렉션 (None이면 새로 연결)
        persona_collection: 페르소나 분석 컬렉션 (None이면 새로 연결)
    """
    print("=" * 70)
    print("📊 Investing.com 뉴스 MongoDB 저장 프로세스 시작")
    print("=" * 70)

    # 1. JSON 파일 로드
    print(f"\n1️⃣ JSON 파일 로드 중: {json_path}")
    articles = load_investing_news_json(json_path)
    print(f"   총 {len(articles)}개 기사 발견")

    # 2. MongoDB 연결
    if news_collection is None or persona_collection is None:
        print(f"\n2️⃣ MongoDB 연결 중:")
        print(f"   - 뉴스 컬렉션: {MONGODB_DB}/{MONGODB_NEWS_COLLECTION}")
        print(f"   - 페르소나 분석 컬렉션: {MONGODB_DB}/{MONGODB_PERSONA_COLLECTION}")
        client = get_mongodb_client()
        if news_collection is None:
            news_collection = get_mongodb_news_collection(client)
        if persona_collection is None:
            persona_collection = get_mongodb_persona_collection(client)
        need_close = True
    else:
        need_close = False

    # 3. 기존 데이터 확인 (중복 체크)
    existing_news_urls = set(news_collection.distinct("url"))
    existing_persona_news_ids = set(
        str(doc["news_id"])
        for doc in persona_collection.find({}, {"news_id": 1})
        if "news_id" in doc
    )
    print(f"   기존 뉴스 데이터: {len(existing_news_urls)}개")
    print(f"   기존 페르소나 분석: {len(existing_persona_news_ids)}개")

    # 4. 새 기사만 필터링 (뉴스가 없거나 페르소나 분석이 없는 경우)
    new_articles = []
    for article in articles:
        url = article.get("url", "")
        if url:
            # 뉴스가 없거나, 뉴스는 있지만 페르소나 분석이 없는 경우
            if url not in existing_news_urls:
                new_articles.append(article)
            else:
                # 뉴스는 있지만 페르소나 분석이 없는지 확인
                existing_news = news_collection.find_one({"url": url})
                if existing_news and "persona_analysis_id" not in existing_news:
                    new_articles.append(article)

    print(f"   신규/업데이트 기사: {len(new_articles)}개")

    if not new_articles:
        print("\n✅ 신규 기사가 없습니다. 프로세스를 종료합니다.")
        if need_close:
            client.close()
        return {
            "total": len(articles),
            "new": 0,
            "processed": 0,
            "news_inserted": 0,
            "news_duplicates": 0,
            "persona_inserted": 0,
            "persona_duplicates": 0,
            "errors": 0,
        }

    # 5. 각 기사 가공
    print(f"\n3️⃣ 뉴스 가공 중 ({len(new_articles)}개)...")
    news_list = []
    persona_list = []
    for idx, article in enumerate(new_articles, 1):
        print(f"\n[{idx}/{len(new_articles)}]")
        try:
            news_data, persona_data = process_news_article(article)
            news_list.append(news_data)
            persona_list.append(persona_data)
        except Exception as e:
            print(f"  ❌ 가공 실패: {str(e)}")
            continue

    # 6. MongoDB에 저장 (2개 컬렉션)
    print(f"\n4️⃣ MongoDB 저장 중...")
    print(f"   - 뉴스 기본 정보: {len(news_list)}개")
    print(f"   - 페르소나 분석: {len(persona_list)}개")
    stats = save_to_mongodb(
        news_list, persona_list, news_collection, persona_collection
    )

    if need_close:
        client.close()

    # 7. 결과 출력
    print("\n" + "=" * 70)
    print("📊 처리 결과")
    print("=" * 70)
    print(f"전체 기사: {len(articles)}개")
    print(f"신규 기사: {len(new_articles)}개")
    print(f"가공 완료: {len(news_list)}개")
    print(f"\n뉴스 기본 정보:")
    print(f"  - 저장 성공: {stats['news_inserted']}개")
    print(f"  - 중복 건너뜀: {stats['news_duplicates']}개")
    print(f"\n페르소나 분석:")
    print(f"  - 저장 성공: {stats['persona_inserted']}개")
    print(f"  - 중복 건너뜀: {stats['persona_duplicates']}개")
    print(f"\n오류 발생: {stats['errors']}개")
    print("=" * 70)

    return {
        "total": len(articles),
        "new": len(new_articles),
        "processed": len(news_list),
        **stats,
    }


def main():
    """메인 실행 함수"""
    # JSON 파일 경로 (AI_airflow/data/investing_news.json)
    current_dir = Path(__file__).resolve().parent
    json_path = current_dir.parent / "data" / "investing_news.json"

    if not json_path.exists():
        print(f"❌ 파일을 찾을 수 없습니다: {json_path}")
        return

    # 프로세스 실행
    stats = process_and_save(str(json_path))

    print("\n✅ 프로세스 완료!")
    print(json.dumps(stats, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
