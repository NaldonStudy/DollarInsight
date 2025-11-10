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


def search_rag_data_for_persona(persona: str, company_name: str, company_info: str = "") -> Dict[str, List[str]]:
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
                pg_results, _ = search_postgres(search_query, top_k=3, postgres_tables=postgres_tables)
                results["postgres"] = pg_results
            except Exception as e:
                print(f"⚠️ [{persona}] PostgreSQL 검색 실패: {e}")
    
    # ChromaDB 검색 (페르소나별 우선순위에 따라)
    if chroma_collections:
        search_priority = agent_db_config.get("search_priority", ["vector", "bm25"])
        
        # 벡터 검색
        if "vector" in search_priority:
            try:
                vector_results, _ = semantic_search_vector(chroma_collections, search_query, top_k=3)
                results["vector"] = vector_results
            except Exception as e:
                print(f"⚠️ [{persona}] 벡터 검색 실패: {e}")
        
        # BM25 키워드 검색
        if "bm25" in search_priority:
            try:
                bm25_results, _ = keyword_search_bm25(chroma_collections, search_query, top_k=3)
                results["bm25"] = bm25_results
            except Exception as e:
                print(f"⚠️ [{persona}] BM25 검색 실패: {e}")
    
    return results


def search_rag_data_all_personas(company_name: str, company_info: str = "") -> Dict[str, Dict[str, List[str]]]:
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
        all_results[persona] = search_rag_data_for_persona(persona, company_name, company_info)
    
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
    
    client = openai.OpenAI(
        api_key=OPENAI_API_KEY,
        base_url=GMS_BASE_URL
    )
    
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
        if not any([rag_results.get("postgres"), rag_results.get("vector"), rag_results.get("bm25")]):
            print(f"  ⚠️ 검색 결과 없음")
    
    # 각 페르소나별 검색 결과 포맷팅
    persona_rag_contexts = {}
    personas = ["희열", "덕수", "지율", "테오", "민지"]
    
    for persona in personas:
        rag_results = all_rag_results.get(persona, {})
        rag_context = []
        
        # 페르소나별 우선순위에 따라 결과 구성
        agent_db_config = AGENT_DATABASES.get(persona, {})
        search_priority = agent_db_config.get("search_priority", ["vector", "bm25", "postgres"])
        
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
        
        persona_rag_contexts[persona] = "\n".join(rag_context) if rag_context else "검색 결과 없음"
    
    # 상세 페르소나 설명
    detailed_personas = "\n\n".join([
        f"### {name}\n{desc}"
        for name, desc in AGENT_DESCRIPTIONS.items()
    ])
    
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

- **형식적인 분석 금지**: "이 기업은..." 같은 형식적 표현 대신, 실제 사람이 말하는 것처럼 작성
- **⚠️ 매번 다른 관점과 표현 사용**: 같은 패턴의 반복을 절대 피하세요. 뉴스/기업별로 완전히 다른 관점과 표현을 사용해야 합니다.
- **고유한 말투 사용**: 
  * 희열: "가즈아!", "터진다!", "지금 당장!", "모멘텀 터졌네!", "손절 -2%, 익절 +3% 잡고!", "기회 놓칠 수 없어!", "달린다!", "폭등 예감!"
  * 덕수: "서두르지 말자", "큰 그림으로 보면", "역사적으로", "금리 사이클상", "6개월 기다려야 해", "위험 구간", "경기 사이클", "거시경제 흐름"
  * 지율: "PER 25배면", "업종 평균 대비", "재무제표상", "영업현금흐름", "리스크 대비 수익률", "고평가/저평가", "PBR", "ROE", "부채비율"
  * 테오: "근시안적이야", "향후 3년", "AI 반도체 수요 연 50%", "기술 혁신 사이클", "골든타임", "미래 비전", "R&D 투자", "특허 포트폴리오"
  * 민지: "커뮤니티 난리", "수급 폭발", "밈 사이클", "2~3일 안에 정리", "핫한 급등 테마", "트렌드 폭발", "소셜 반응", "화제성"

- **검색 데이터 활용**: 각 페르소나는 자신의 검색 데이터만 참고하여 구체적인 수치나 정보를 자연스럽게 언급
- **구체적이고 생생하게**: 너무 짧거나 추상적이지 말고, 검색된 데이터의 구체적인 내용을 활용하여 충분히 구체적으로 작성
- **기업별 차별화**: 같은 기업이라도 각 페르소나의 관점이 완전히 달라야 하며, 매번 다른 표현과 관점을 사용해야 합니다

## 응답 형식
다음 JSON 형식으로 응답하세요:
{{
  "persona_analyses": {{
    "희열": "희열이 실제로 말하는 것처럼 열정적이고 구체적으로 작성 (예: '모멘텀 터졌네! 지금 당장 3% 목표로 들어가야 해! 손절 -2%, 익절 +3% 잡고 가즈아!')",
    "덕수": "덕수가 실제로 말하는 것처럼 신중하고 거시적으로 작성 (예: '서두르지 말게. 큰 그림으로 보면 금리 사이클상 아직 위험 구간이야. 역사적으로 이런 시기엔 6개월 기다린 사람이 승자였네.')",
    "지율": "지율이 실제로 말하는 것처럼 냉혹하게 숫자로만 판단하며 작성 (예: '현재 PER 25배면 업종 평균 15배 대비 고평가야. 재무제표상 영업현금흐름이 마이너스인데 리스크 대비 수익률이 안 나와.')",
    "테오": "테오가 실제로 말하는 것처럼 미래 기술 관점에서 낙관적으로 작성 (예: '단기 실적만 보는 건 근시안적이야. 향후 3년 AI 반도체 수요 연 50% 성장하면 지금 가격은 저평가야. 기술 혁신 사이클상 지금이 골든타임!')",
    "민지": "민지가 실제로 말하는 것처럼 트렌드와 소셜 관점에서 빠르게 작성 (예: '지금 이 테마 커뮤니티 완전 난리인데 수급 폭발이야! 근데 밈 사이클 고려하면 2~3일 안에 정리해야 해.')"
  }}
}}

JSON만 응답하세요:"""

    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {
                "role": "system",
                "content": "You are a helpful assistant that analyzes companies from multiple investment personas. Always respond in valid JSON format only. Make the responses natural and conversational, not formulaic."
            },
            {"role": "user", "content": prompt}
        ],
        max_tokens=2000,  # 더 긴 응답을 위해 증가
        temperature=0.9,  # 다양성 향상을 위해 temperature 증가
        response_format={"type": "json_object"}  # JSON 형식 강제
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
        "analyzed_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }
    
    # 각 페르소나를 영문 필드명으로 추가
    persona_mapping = {
        "희열": "Heeyule",
        "덕수": "Ducksu",
        "지율": "Jiyule",
        "테오": "Taeo",
        "민지": "Minji"
    }
    
    for korean_name, english_name in persona_mapping.items():
        result[english_name] = persona_analyses.get(korean_name, f"{korean_name} 분석 생성 실패")
    
    return result

