"""
뉴스 분석 모듈
- 뉴스 요약
- 페르소나 5명 분석
- 영향 미칠 기업 목록 추출
"""

import os
import json
from typing import Dict, List
import openai

from prompts import AGENT_DESCRIPTIONS, AGENT_DATABASES
from database import (
    load_agent_collections,
    search_postgres,
)
from search import keyword_search_bm25, semantic_search_vector

# 추적 대상 기업/ETF 목록 (LLM에게 제공하여 정확한 매칭)
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
    # ETF는 그대로
}


def search_rag_data_for_news_persona(
    persona: str, news_title: str, news_content: str, companies: List[str] = None
) -> Dict[str, List[str]]:
    """
    뉴스 분석을 위한 페르소나별 RAG 검색 수행

    Args:
        persona: 페르소나 이름
        news_title: 뉴스 제목
        news_content: 뉴스 본문
        companies: 관련 기업 목록

    Returns:
        {
            "postgres": [결과1, 결과2, ...],
            "vector": [결과1, 결과2, ...],
            "bm25": [결과1, 결과2, ...]
        }
    """
    # 페르소나별 데이터베이스 설정 가져오기
    agent_db_config = AGENT_DATABASES.get(persona, {})

    # 검색 쿼리 구성 (뉴스 내용 + 관련 기업)
    search_query_parts = [news_title]
    if companies:
        search_query_parts.extend(companies[:3])  # 최대 3개 기업만 사용

    search_query = " ".join(search_query_parts)

    # 페르소나별 키워드 추가
    news_keywords = agent_db_config.get("news_keywords", [])
    if news_keywords:
        keyword_query = " ".join(news_keywords[:2])  # 상위 2개 키워드만 사용
        search_query = f"{search_query} {keyword_query}"

    # 검색 결과
    results = {
        "postgres": [],
        "vector": [],
        "bm25": [],
    }

    # ChromaDB 컬렉션 로드 (페르소나별)
    chroma_collection_names = agent_db_config.get("chroma_collections", ["news_bge_m3"])
    chroma_collections = load_agent_collections(chroma_collection_names)

    # PostgreSQL 검색 (페르소나별 테이블 사용)
    if agent_db_config.get("use_postgres", False) and companies:
        postgres_tables = agent_db_config.get("postgres_tables", [])
        if postgres_tables:
            try:
                # 관련 기업별로 검색
                for company in companies[:2]:  # 최대 2개 기업만 검색
                    pg_results, _ = search_postgres(
                        f"{company} {search_query}",
                        top_k=2,
                        postgres_tables=postgres_tables,
                    )
                    results["postgres"].extend(pg_results[:1])  # 각 기업당 1개씩만
            except Exception as e:
                print(f"⚠️ [{persona}] PostgreSQL 검색 실패: {e}")

    # ChromaDB 검색 (페르소나별 우선순위에 따라)
    if chroma_collections:
        search_priority = agent_db_config.get("search_priority", ["vector", "bm25"])

        # 벡터 검색
        if "vector" in search_priority:
            try:
                vector_results, _ = semantic_search_vector(
                    chroma_collections, search_query, top_k=2
                )
                results["vector"] = vector_results
            except Exception as e:
                print(f"⚠️ [{persona}] 벡터 검색 실패: {e}")

        # BM25 키워드 검색
        if "bm25" in search_priority:
            try:
                bm25_results, _ = keyword_search_bm25(
                    chroma_collections, search_query, top_k=2
                )
                results["bm25"] = bm25_results
            except Exception as e:
                print(f"⚠️ [{persona}] BM25 검색 실패: {e}")

    return results


def analyze_news(title: str, content: str) -> Dict:
    """
    뉴스 기사를 5명의 페르소나 관점에서 분석 (RAG 검색 활용)
    - 뉴스 요약
    - 페르소나 5명 분석 (희열, 덕수, 지율, 테오, 민지)
    - 영향 미칠 기업 목록 추출 후 RAG 검색 수행

    Args:
        title: 뉴스 제목
        content: 뉴스 본문

    Returns:
        {
            "summary": str,
            "persona_analyses": {persona: analysis},
            "companies": [str]
        }
    """
    OPENAI_API_KEY = os.getenv("GMS_API_KEY")
    GMS_BASE_URL = "https://gms.ssafy.io/gmsapi/api.openai.com/v1"

    if not OPENAI_API_KEY:
        raise ValueError("GMS_API_KEY가 설정되지 않았습니다.")

    client = openai.OpenAI(api_key=OPENAI_API_KEY, base_url=GMS_BASE_URL)

    # 상세 페르소나 설명
    detailed_personas = "\n\n".join(
        [f"### {name}\n{desc}" for name, desc in AGENT_DESCRIPTIONS.items()]
    )

    # 추적 대상 기업 목록을 문자열로 변환
    tracked_companies_str = ", ".join(TRACKED_COMPANIES)

    # 1단계: 먼저 관련 기업 추출 (RAG 없이 빠르게)
    initial_prompt = f"""다음 뉴스 기사에서 직접 언급되거나 영향을 받을 수 있는 기업/ETF를 추출하세요.

## 뉴스 기사
제목: {title}
내용: {content[:1000]}

## 추적 대상 기업/ETF 목록
{tracked_companies_str}

## 요청
위 목록 중에서 뉴스에 직접 언급되거나 영향을 받을 수 있는 기업/ETF만 선택하세요 (최대 5개).
뉴스에 직접 언급된 기업이 없으면 빈 배열을 반환하세요.

## 응답 형식
{{"companies": ["애플", "테슬라"]}}

JSON만 응답하세요:"""

    initial_response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {
                "role": "system",
                "content": "You are a helpful assistant that extracts company names from news. Always respond in valid JSON format only.",
            },
            {"role": "user", "content": initial_prompt},
        ],
        max_tokens=200,
        temperature=0.3,
        response_format={"type": "json_object"},
    )

    initial_result = json.loads(initial_response.choices[0].message.content.strip())
    extracted_companies = initial_result.get("companies", [])

    # 기업명 매칭 (정확도 향상)
    matched_companies = []
    tracked_lower = {c.lower(): c for c in TRACKED_COMPANIES}

    for company in extracted_companies:
        company_clean = company.strip()
        company_lower = company_clean.lower()

        if company_lower in tracked_lower:
            matched = tracked_lower[company_lower]
            if matched not in matched_companies:
                matched_companies.append(matched)
        elif company_lower in COMPANY_NAME_MAPPING:
            matched = COMPANY_NAME_MAPPING[company_lower]
            if matched not in matched_companies:
                matched_companies.append(matched)

    companies = matched_companies[:5]

    # 2단계: 각 페르소나별로 RAG 검색 수행
    print(f"🔍 뉴스 분석 RAG 검색 수행 중: {title[:50]}...")
    print(f"📌 추출된 관련 기업: {companies}")
    all_rag_results = {}
    personas = ["희열", "덕수", "지율", "테오", "민지"]

    for persona in personas:
        all_rag_results[persona] = search_rag_data_for_news_persona(
            persona, title, content, companies
        )
        # RAG 검색 결과 로그 출력
        rag_results = all_rag_results[persona]
        print(f"\n[{persona}] RAG 검색 결과:")
        if rag_results.get("postgres"):
            print(f"  PostgreSQL: {len(rag_results['postgres'])}개")
            for i, pg in enumerate(rag_results["postgres"][:2], 1):
                print(f"    {i}. {pg[:100]}...")
        if rag_results.get("vector"):
            print(f"  벡터 검색: {len(rag_results['vector'])}개")
            for i, vec in enumerate(rag_results["vector"][:2], 1):
                print(f"    {i}. {vec[:100]}...")
        if rag_results.get("bm25"):
            print(f"  BM25 검색: {len(rag_results['bm25'])}개")
            for i, bm in enumerate(rag_results["bm25"][:2], 1):
                print(f"    {i}. {bm[:100]}...")
        if not any(
            [
                rag_results.get("postgres"),
                rag_results.get("vector"),
                rag_results.get("bm25"),
            ]
        ):
            print(f"  ⚠️ 검색 결과 없음")

    # 각 페르소나별 검색 결과 포맷팅
    persona_rag_contexts = {}
    for persona in personas:
        rag_results = all_rag_results.get(persona, {})
        rag_context = []

        # 페르소나별 우선순위에 따라 결과 구성
        agent_db_config = AGENT_DATABASES.get(persona, {})
        search_priority = agent_db_config.get(
            "search_priority", ["vector", "bm25", "postgres"]
        )

        for search_type in search_priority:
            if search_type == "postgres" and rag_results.get("postgres"):
                rag_context.append(f"[{persona} - 재무/주가 데이터]")
                rag_context.extend(rag_results["postgres"][:2])
            elif search_type == "vector" and rag_results.get("vector"):
                rag_context.append(f"[{persona} - 관련 뉴스 - 의미 검색]")
                rag_context.extend(rag_results["vector"][:2])
            elif search_type == "bm25" and rag_results.get("bm25"):
                rag_context.append(f"[{persona} - 관련 뉴스 - 키워드 검색]")
                rag_context.extend(rag_results["bm25"][:2])

        persona_rag_contexts[persona] = (
            "\n".join(rag_context) if rag_context else "검색 결과 없음"
        )

    # RAG 검색 결과를 프롬프트에 포함
    rag_sections = []
    for persona in personas:
        rag_section = f"### {persona}의 검색 데이터\n{persona_rag_contexts[persona]}"
        rag_sections.append(rag_section)

    rag_text_all = "\n\n".join(rag_sections)

    # 3단계: RAG 검색 결과를 포함한 최종 분석 수행
    prompt = f"""다음 뉴스 기사를 읽고, 5명의 투자자 페르소나가 두괄식으로 간결하게 분석해주세요.

## 뉴스 기사
제목: {title}

내용:
{content[:2000]}

## 페르소나별 검색된 데이터 (각 페르소나는 자신의 데이터만 참고)
{rag_text_all}

## 페르소나 설명
{detailed_personas}

## 작성 요청
🎯 최우선 목표: 재미있게 말하는 것이 가장 중요합니다.

1. **summary**: 뉴스의 핵심 내용을 2-3문장으로 요약

2. **persona_analyses**: 각 페르소나가 이 뉴스를 읽고 두괄식으로 간결하게 작성하세요
   - 두괄식으로 작성: 핵심 의견을 먼저 제시하고 간결하게 표현하세요.
   - 각 페르소나의 고유한 말투를 투자 철학에 맞춰 강하게 사용하세요:
     * 희열: 극도로 열정적이고 공격적인 말투. 짧고 강렬한 문장, 감탄사와 이모티콘 느낌의 표현, 숫자와 수익률을 자주 언급. 긴장감과 속도감, 기회를 놓치지 않으려는 절박함 표현
     * 덕수: 지혜롭고 신중한 말투. 긴 문장, 비유와 역사적 사례를 자주 사용. 신중하고 차분한 톤으로 위험을 경고. 때로는 날카로운 비꼼으로 단기 투자를 비판
     * 지율: 냉혹하고 객관적인 말투. 짧고 명확한 문장, 숫자와 지표를 자주 언급. 감정을 배제한 냉혹한 톤. 때로는 날카로운 비꼼으로 감정적 투자 비판
     * 테오: 낙관적이고 미래지향적인 말투. 중간 길이의 문장, 미래지향적 표현과 성장률을 자주 언급. 기술 혁신의 흥미진진함을 표현. 장기 비전과 골든타임을 강조
     * 민지: 빠르고 직관적인 말투. 짧고 빠른 문장, 트렌드 용어와 소셜 표현을 자주 사용. 밈과 화제성을 언급. 소셜 반응과 커뮤니티 분위기를 읽는 감각적 표현
   - 뉴스에 나온 구체적인 내용(기업명, 수치, 사건)과 검색된 데이터를 자연스럽게 언급하세요.
   - 매번 다른 관점과 표현을 사용하세요. 같은 패턴을 반복하지 마세요.
   - 이름 언급 금지! 다른 사람이나 자신의 이름을 절대 언급하지 마세요.

3. **companies**: {companies if companies else "[]"} (이미 추출됨)

## 응답 형식
다음 JSON 형식으로 응답하세요:
{{
  "summary": "뉴스 요약 (2-3문장)",
  "persona_analyses": {{
    "희열": "핵심 의견을 먼저 제시하고 간결하게 작성하세요. 각 페르소나의 고유한 말투를 사용하세요.",
    "덕수": "핵심 의견을 먼저 제시하고 간결하게 작성하세요. 각 페르소나의 고유한 말투를 사용하세요.",
    "지율": "핵심 의견을 먼저 제시하고 간결하게 작성하세요. 각 페르소나의 고유한 말투를 사용하세요.",
    "테오": "핵심 의견을 먼저 제시하고 간결하게 작성하세요. 각 페르소나의 고유한 말투를 사용하세요.",
    "민지": "핵심 의견을 먼저 제시하고 간결하게 작성하세요. 각 페르소나의 고유한 말투를 사용하세요."
  }},
  "companies": {companies if companies else []}
}}

JSON만 응답하세요:"""

    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {
                "role": "system",
                "content": "You are a helpful assistant that analyzes news and provides investment opinions from multiple personas. Always respond in valid JSON format only.",
            },
            {"role": "user", "content": prompt},
        ],
        max_tokens=2000,  # 더 긴 응답을 위해 증가
        temperature=0.9,  # 다양성 향상을 위해 temperature 증가
        response_format={"type": "json_object"},  # JSON 형식 강제
    )

    result_text = response.choices[0].message.content.strip()

    # JSON 파싱
    try:
        result_json = json.loads(result_text)
    except json.JSONDecodeError:
        raise ValueError("응답 파싱 실패")

    # 결과 검증 및 반환
    summary = result_json.get("summary", "요약 생성 실패")
    persona_analyses = result_json.get("persona_analyses", {})
    # companies는 이미 추출되어 있음

    # 페르소나 분석이 없으면 기본값
    for persona in ["희열", "덕수", "지율", "테오", "민지"]:
        if persona not in persona_analyses:
            persona_analyses[persona] = f"{persona} 분석 생성 실패"

    return {
        "summary": summary,
        "persona_analyses": persona_analyses,
        "companies": companies,
    }
