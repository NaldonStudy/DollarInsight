"""
기업 분석 모듈
- 기업 키워드를 받아서 페르소나별로 한마디씩 투자 의견 생성
- RAG 검색을 활용하여 실제 데이터 기반 분석
"""

import os
import json
from typing import Dict, List
from datetime import datetime
import openai

from prompts import AGENT_DESCRIPTIONS, AGENT_DATABASES
from database import (
    load_agent_collections,
    search_postgres,
    get_table_schema_info,
    get_schema_cache,
)
from search import keyword_search_bm25, semantic_search_vector


def search_rag_data_for_persona(
    persona: str, company_name: str, company_info: str = ""
) -> Dict[str, List[str]]:
    """
    특정 페르소나에 맞는 RAG 검색 수행

    Args:
        persona: 페르소나 이름 ("희열", "덕수", "지율", "테오", "민지")
        company_name: 기업명
        company_info: 기업 정보

    Returns:
        {
            "postgres": [결과1, 결과2, ...],
            "vector": [결과1, 결과2, ...],
            "bm25": [결과1, 결과2, ...]
        }
    """
    # 페르소나별 데이터베이스 설정 가져오기
    agent_db_config = AGENT_DATABASES.get(persona, {})

    # 검색 쿼리 구성
    search_query = f"{company_name} {company_info}".strip()

    # 페르소나별 키워드 추가 (검색 정확도 향상)
    news_keywords = agent_db_config.get("news_keywords", [])
    if news_keywords:
        keyword_query = " ".join(news_keywords[:3])  # 상위 3개 키워드만 사용
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
    if agent_db_config.get("use_postgres", False):
        postgres_tables = agent_db_config.get("postgres_tables", [])
        if postgres_tables:
            try:
                pg_results, _ = search_postgres(
                    search_query, top_k=3, postgres_tables=postgres_tables
                )
                results["postgres"] = pg_results
            except Exception as e:
                print(f"⚠️ [{persona}] PostgreSQL 검색 실패: {e}")

    # ChromaDB 검색 (페르소나별 우선순위에 따라)
    if chroma_collections:
        search_priority = agent_db_config.get("search_priority", ["vector", "bm25"])

        # 벡터 검색
        if "vector" in search_priority:
            try:
                vector_results, _ = semantic_search_vector(
                    chroma_collections, search_query, top_k=3
                )
                results["vector"] = vector_results
            except Exception as e:
                print(f"⚠️ [{persona}] 벡터 검색 실패: {e}")

        # BM25 키워드 검색
        if "bm25" in search_priority:
            try:
                bm25_results, _ = keyword_search_bm25(
                    chroma_collections, search_query, top_k=3
                )
                results["bm25"] = bm25_results
            except Exception as e:
                print(f"⚠️ [{persona}] BM25 검색 실패: {e}")

    return results


def search_rag_data_all_personas(
    company_name: str, company_info: str = ""
) -> Dict[str, Dict[str, List[str]]]:
    """
    모든 페르소나별로 RAG 검색 수행

    Returns:
        {
            "희열": {"postgres": [...], "vector": [...], "bm25": [...]},
            "덕수": {"postgres": [...], "vector": [...], "bm25": [...]},
            ...
        }
    """
    personas = ["희열", "덕수", "지율", "테오", "민지"]
    all_results = {}

    for persona in personas:
        all_results[persona] = search_rag_data_for_persona(
            persona, company_name, company_info
        )

    return all_results


def analyze_company(company_name: str, company_info: str = "") -> Dict:
    """
    기업을 5명의 페르소나 관점에서 분석 (RAG 검색 활용)
    - RAG 검색을 통해 실제 데이터 기반 분석
    - 페르소나별로 자연스러운 투자 의견 생성

    Args:
        company_name: 기업명 (예: "삼성전자", "AAPL", "테슬라")
        company_info: 기업 정보 (선택사항, 추가 컨텍스트)

    Returns:
        {
            "company_name": str,
            "persona_analyses": {persona: analysis},
            "analyzed_at": str
        }
    """
    OPENAI_API_KEY = os.getenv("GMS_API_KEY")
    GMS_BASE_URL = "https://gms.ssafy.io/gmsapi/api.openai.com/v1"

    if not OPENAI_API_KEY:
        raise ValueError("GMS_API_KEY가 설정되지 않았습니다.")

    client = openai.OpenAI(api_key=OPENAI_API_KEY, base_url=GMS_BASE_URL)

    # 각 페르소나별로 RAG 검색 수행
    print(f"🔍 페르소나별 RAG 검색 수행 중: {company_name}")
    all_rag_results = search_rag_data_all_personas(company_name, company_info)

    # RAG 검색 결과 로그 출력
    personas = ["희열", "덕수", "지율", "테오", "민지"]
    for persona in personas:
        rag_results = all_rag_results.get(persona, {})
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
    personas = ["희열", "덕수", "지율", "테오", "민지"]

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

    # 상세 페르소나 설명
    detailed_personas = "\n\n".join(
        [f"### {name}\n{desc}" for name, desc in AGENT_DESCRIPTIONS.items()]
    )

    # 기업 정보가 있으면 포함
    company_context = f"\n\n기업 정보:\n{company_info}" if company_info else ""

    # 각 페르소나별 검색 결과를 포함한 자연스러운 프롬프트 구성
    rag_sections = []
    for persona in personas:
        rag_section = f"### {persona}의 검색 데이터\n{persona_rag_contexts[persona]}"
        rag_sections.append(rag_section)

    rag_text_all = "\n\n".join(rag_sections)

    # 자연스러운 프롬프트 구성
    prompt = f"""다음 기업에 대해 5명의 투자자 페르소나가 실제로 분석하고 말하는 것처럼 자연스럽게 투자 의견을 작성해주세요.

## 분석 대상 기업
{company_name}
{company_context}

## 페르소나별 검색된 데이터 (각 페르소나는 자신의 데이터만 참고)
{rag_text_all}

## 페르소나 설명
{detailed_personas}

## 작성 가이드
각 페르소나가 실제 투자자처럼 자연스럽게 말하도록 작성하세요:

- **⚠️ 이 기업의 고유한 특성에 집중**: 이 기업만의 특징, 업종, 최근 이슈, 재무 상태 등을 구체적으로 언급하세요. 다른 기업과 비슷한 일반적인 분석은 절대 금지입니다.
- **⚠️ 기업별 완전히 다른 분석**: 같은 페르소나라도 기업마다 완전히 다른 관점과 표현을 사용해야 합니다. 예를 들어:
  * 애플 분석: "아이폰 판매량", "서비스 수익", "중국 시장" 등 애플만의 특성
  * 테슬라 분석: "전기차 시장 점유율", "자율주행 기술", "배터리 기술" 등 테슬라만의 특성
  * 각 기업의 고유한 비즈니스 모델, 재무 지표, 최근 뉴스에 집중하세요
  
- **형식적인 분석 금지**: "이 기업은..." 같은 형식적 표현 대신, 실제 사람이 말하는 것처럼 작성
- **⚠️ 매번 다른 관점과 표현 사용**: 같은 패턴의 반복을 절대 피하세요. 기업별로 완전히 다른 관점과 표현을 사용해야 합니다.
- **고유한 말투 사용**: 
  * 희열: "가즈아!", "터진다!", "지금 당장!", "모멘텀 터졌네!", "손절 -2%, 익절 +3% 잡고!", "기회 놓칠 수 없어!", "달린다!", "폭등 예감!"
  * 덕수: "서두르지 말자", "큰 그림으로 보면", "역사적으로", "금리 사이클상", "6개월 기다려야 해", "위험 구간", "경기 사이클", "거시경제 흐름"
  * 지율: "PER 25배면", "업종 평균 대비", "재무제표상", "영업현금흐름", "리스크 대비 수익률", "고평가/저평가", "PBR", "ROE", "부채비율"
  * 테오: "근시안적이야", "향후 3년", "AI 반도체 수요 연 50%", "기술 혁신 사이클", "골든타임", "미래 비전", "R&D 투자", "특허 포트폴리오"
  * 민지: "커뮤니티 난리", "수급 폭발", "밈 사이클", "2~3일 안에 정리", "핫한 급등 테마", "트렌드 폭발", "소셜 반응", "화제성"

- **검색 데이터 적극 활용**: 각 페르소나는 자신의 검색 데이터에서 찾은 구체적인 수치, 뉴스, 재무 정보를 반드시 언급하세요. 검색 데이터가 없으면 일반적인 분석을 하되, 이 기업만의 고유한 특성에 집중하세요.
- **구체적이고 생생하게**: 너무 짧거나 추상적이지 말고, 검색된 데이터의 구체적인 내용을 활용하여 충분히 구체적으로 작성
- **기업별 차별화**: 같은 페르소나라도 기업마다 완전히 다른 관점과 표현을 사용해야 합니다. 이 기업의 업종, 비즈니스 모델, 최근 이슈에 맞춰 분석하세요.
- **⚠️ 이름 언급 금지**: 다른 사람이나 자신의 이름을 절대 언급하지 마세요. "나는", "내 생각은", "그 말과 다르게" 같은 표현만 사용하세요.

## 응답 형식
다음 JSON 형식으로 응답하세요:
{{
  "persona_analyses": {{
    "희열": "이 기업의 고유한 특성(업종, 비즈니스 모델, 최근 뉴스 등)을 언급하며 실제로 말하는 것처럼 열정적이고 구체적으로 작성하세요. 검색된 데이터의 구체적인 수치나 뉴스를 활용하여 자연스럽게 표현하세요.",
    "덕수": "이 기업의 고유한 특성을 거시경제 관점에서 분석하며 실제로 말하는 것처럼 신중하고 거시적으로 작성하세요. 검색된 데이터의 거시경제 이슈나 사이클을 활용하여 자연스럽게 표현하세요.",
    "지율": "이 기업의 고유한 재무 지표나 업종 특성을 언급하며 실제로 말하는 것처럼 냉혹하게 숫자로만 판단하며 작성하세요. 검색된 데이터의 구체적인 재무 지표나 수치를 활용하여 자연스럽게 표현하세요.",
    "테오": "이 기업의 고유한 기술이나 미래 비전을 언급하며 실제로 말하는 것처럼 미래 기술 관점에서 낙관적으로 작성하세요. 검색된 데이터의 기술 트렌드나 성장 전망을 활용하여 자연스럽게 표현하세요.",
    "민지": "이 기업의 고유한 트렌드나 소셜 반응을 언급하며 실제로 말하는 것처럼 트렌드와 소셜 관점에서 빠르게 작성하세요. 검색된 데이터의 트렌드나 소셜 반응을 활용하여 자연스럽게 표현하세요."
  }}
}}

⚠️ 중요: 각 기업마다 완전히 다른 내용과 표현을 사용하세요. 같은 패턴을 반복하지 마세요.

JSON만 응답하세요:"""

    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {
                "role": "system",
                "content": "You are a helpful assistant that analyzes companies from multiple investment personas. Always respond in valid JSON format only. Make the responses natural and conversational, not formulaic. CRITICAL: Each company must be analyzed with completely different perspectives and expressions. Focus on each company's unique characteristics, industry, business model, and recent news. Never use similar patterns across different companies.",
            },
            {"role": "user", "content": prompt},
        ],
        max_tokens=2000,  # 더 긴 응답을 위해 증가
        temperature=1.0,  # 다양성 최대화를 위해 temperature 증가 (0.9 -> 1.0)
        response_format={"type": "json_object"},  # JSON 형식 강제
    )

    result_text = response.choices[0].message.content.strip()

    # JSON 파싱
    try:
        result_json = json.loads(result_text)
    except json.JSONDecodeError:
        raise ValueError("응답 파싱 실패")

    # 결과 검증 및 반환
    persona_analyses = result_json.get("persona_analyses", {})

    # 페르소나 분석이 없으면 기본값
    for persona in ["희열", "덕수", "지율", "테오", "민지"]:
        if persona not in persona_analyses:
            persona_analyses[persona] = f"{persona} 분석 생성 실패"

    # 페르소나별로 개별 필드로 변환 (영문 컬럼명 사용)
    result = {
        "company_name": company_name,
        "analyzed_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
    }

    # 각 페르소나를 영문 필드명으로 추가
    persona_mapping = {
        "희열": "heuyeol",
        "덕수": "deoksu",
        "지율": "jiyul",
        "테오": "teo",
        "민지": "minji",
    }

    for korean_name, english_name in persona_mapping.items():
        result[english_name] = persona_analyses.get(
            korean_name, f"{korean_name} 분석 생성 실패"
        )

    return result
