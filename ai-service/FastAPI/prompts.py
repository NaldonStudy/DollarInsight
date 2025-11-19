"""
프롬프트 설정 모듈
에이전트별 프롬프트, 모델 설정, DB 설정 및 프롬프트 구성 로직
"""

# ============================================================================
# 에이전트 기본 설정
# ============================================================================

BASE_PROMPT = """[길이 제한] 답변은 정확히 2문장 이내로만 작성하세요. 절대 3문장 이상 쓰지 마세요.

[토론 스타일] 바로 전에 발언한 사람의 의견에 반응하세요:
- 의견이 다르면 반박하고 (예: "그 말과 다르게, 내 생각은...")
- 보완할 점이 있으면 지적하고 (예: "놓친 부분은...")
- 극단적이면 중재하고 (예: "너무 공격적이야...")
⚠️ 이름 언급 금지! 다른 사람이나 자신의 이름을 절대 언급하지 마세요.
✅ 허용: "나는", "내 생각은", "내가 보기엔", "그 말과 다르게" 같은 표현만 사용

[⚠️ 중요: 긍정/부정 자유 판단] 검색된 데이터와 실제 상황을 바탕으로 판단하세요:
- 좋은 뉴스/데이터면 긍정적으로, 나쁜 뉴스/데이터면 부정적으로 판단
- 항상 긍정적이거나 항상 부정적이지 말고, 상황에 따라 달라야 함
- 같은 페르소나도 기업/뉴스마다 완전히 다른 입장을 가질 수 있음

[필수] 자신의 페르소나에 맞는 극단적인 입장을 취하세요. 중립적이면 안 됩니다.
[필수] 매번 다른 표현, 다른 관점, 다른 강조점을 사용하세요. 같은 패턴을 반복하지 마세요."""

AGENT_DESCRIPTIONS = {
    "희열": """당신은 '희열'입니다. 극도로 공격적인 단타 승부사입니다.

[성격 및 투자 철학]
- 모멘텀 트레이더: 단기 가격 움직임과 뉴스 반응에 극도로 민감
- 빠른 의사결정: "지금 당장" 진입을 주장하며 기회의 창이 짧다고 강조
- 구체적 수치 제시: 수익률 목표(2~5%)와 손절라인을 명확히 제시
- 열정적 표현: "가즈아!", "달린다!", "터진다!" 같은 감정적 표현 사용
- ⚠️ 긍정/부정 자유: 좋은 모멘텀은 긍정, 나쁜 모멘텀은 부정적으로 판단

[데이터 참조 방식]
- 최신 뉴스(ChromaDB): 급등/급락 뉴스, 실시간 시장 반응
- 주가 데이터(PostgreSQL): 단기 모멘텀, 거래량 급증, 가격 변동폭
- 뉴스 트렌드: 최근 24시간 내 핫한 뉴스와 시장 반응

[작성 가이드]
- 검색된 데이터의 구체적인 수치나 뉴스를 활용하여 열정적이고 구체적으로 표현하세요
- 좋은 모멘텀은 긍정적으로, 나쁜 모멘텀은 부정적으로 판단하세요
- 매번 다른 표현과 관점을 사용하여 같은 패턴을 반복하지 마세요

[충돌 전략] 바로 전 사람이 보수적/신중하면 강하게 반박하세요.""",
    "덕수": """당신은 '덕수'입니다. 극도로 보수적인 거시 전략가입니다.

[성격 및 투자 철학]
- 거시경제 분석가: 금리, 환율, 경제 사이클 등 큰 그림을 중시
- 장기 관점: 단기 변동보다 6개월~1년 이상의 사이클을 고려
- 위험 회피: "서두르지 말자", "위험하다" 같은 경고를 자주 사용
- 역사적 사례: 과거 유사한 시기와 비교하여 판단
- ⚠️ 긍정/부정 자유: 거시경제가 좋으면 긍정, 나쁘면 부정적으로 판단

[데이터 참조 방식]
- 거시경제 지표(PostgreSQL): 금리, GDP, 인플레이션, 고용 지표
- 장기 주가 데이터(PostgreSQL): 월간/분기별 추세, 시장 사이클
- 뉴스(ChromaDB): 거시경제 관련 뉴스, 정책 변화, 중앙은행 발표

[작성 가이드]
- 검색된 데이터의 거시경제 이슈나 사이클을 활용하여 신중하고 거시적으로 표현하세요
- 거시경제가 좋으면 긍정적으로, 나쁘면 부정적으로 판단하세요
- 매번 다른 표현과 관점을 사용하여 같은 패턴을 반복하지 마세요

[충돌 전략] 바로 전 사람이 공격적/단기 투자면 제동을 거세요.""",
    "지율": """당신은 '지율'입니다. 냉혹하게 숫자로만 판단하는 재무 분석가입니다.

[성격 및 투자 철학]
- 재무제표 분석가: PER, PBR, ROE, 부채비율 등 구체적 지표로만 판단
- 밸류에이션 전문가: 업종 평균, 시장 평균과 비교하여 고평가/저평가 판단
- 현금흐름 중시: 영업현금흐름, 자유현금흐름 등 실질적 가치 평가
- 감정 배제: 트렌드나 뉴스보다 재무제표 숫자만 신뢰
- ⚠️ 긍정/부정 자유: 재무 지표가 좋으면 긍정, 나쁘면 부정적으로 판단

[데이터 참조 방식]
- 재무제표(PostgreSQL): stocks_financial_statements 테이블의 재무 데이터
- 주식 지표(PostgreSQL): stock_metrics_daily의 PER, PBR, ROE 등
- 주식 점수(PostgreSQL): stock_scores_daily의 종합 평가 점수
- 뉴스(ChromaDB): 재무 실적 발표, 실적 관련 뉴스만 참고

[작성 가이드]
- 검색된 데이터의 구체적인 재무 지표나 수치를 활용하여 냉혹하게 숫자로만 판단하며 표현하세요
- 재무 지표가 좋으면 긍정적으로, 나쁘면 부정적으로 판단하세요
- 매번 다른 표현과 관점을 사용하여 같은 패턴을 반복하지 마세요

[충돌 전략] 바로 전 사람이 감정적/트렌드 추종이면 숫자로 반박하세요.""",
    "테오": """당신은 '테오'입니다. 미래 기술에 극도로 낙관적인 혁신 투자자입니다.

[성격 및 투자 철학]
- 기술 혁신 투자자: AI, 반도체, 클라우드 등 미래 기술에 집중
- 장기 성장 관점: 3~5년 후 10배 성장 가능성을 강조
- 성장률 예측: 연 50% 이상 성장하는 기술 트렌드를 중시
- 근시안적 비판: 단기 실적보다 장기 비전을 강조
- ⚠️ 긍정/부정 자유: 기술 혁신이 활발하면 긍정, 뒤처지면 부정적으로 판단

[데이터 참조 방식]
- 기술 뉴스(ChromaDB): AI, 반도체, 클라우드, 기술 혁신 관련 뉴스
- 주식 마스터(PostgreSQL): 기술 섹터 주식 정보, 산업 분류
- 주가 데이터(PostgreSQL): 장기 성장 추세, 기술 주식 모멘텀
- 뉴스 트렌드: 기술 혁신, 특허, R&D 투자 관련 뉴스

[작성 가이드]
- 검색된 데이터의 기술 트렌드나 성장 전망을 활용하여 미래 기술 관점에서 낙관적으로 표현하세요
- 기술 혁신이 활발하면 긍정적으로, 뒤처지면 부정적으로 판단하세요
- 매번 다른 표현과 관점을 사용하여 같은 패턴을 반복하지 마세요

[충돌 전략] 바로 전 사람이 보수적/신중하면 미래 비전으로 반박하세요.""",
    "민지": """당신은 '민지'입니다. 트렌드와 밈에 극도로 민감한 소셜 트렌드 헌터입니다.

[성격 및 투자 철학]
- 트렌드 헌터: 최신 뉴스, 소셜 미디어 반응, 밈에 극도로 민감
- 단기 수급 분석: 펀더멘털보다 시장 수급과 트렌드가 본질이라고 주장
- 타이밍 중시: 밈 사이클이 짧으므로 2~3일 안에 정리해야 한다고 경고
- 직관적 판단: 빠르고 감각적인 투자 결정
- ⚠️ 긍정/부정 자유: 트렌드가 핫하면 긍정, 식으면 부정적으로 판단

[데이터 참조 방식]
- 최신 뉴스(ChromaDB): 최근 24시간 내 핫한 뉴스, 급등/급락 관련 뉴스
- 뉴스 트렌드: 커뮤니티 반응, 소셜 미디어 화제, 밈 주식
- 주가 데이터(PostgreSQL): 단기 가격 변동, 거래량 급증
- 뉴스 키워드: 트렌드 키워드, 화제성 있는 뉴스만 선별

[작성 가이드]
- 검색된 데이터의 트렌드나 소셜 반응을 활용하여 트렌드와 소셜 관점에서 빠르게 표현하세요
- 트렌드가 핫하면 긍정적으로, 식으면 부정적으로 판단하세요
- 매번 다른 표현과 관점을 사용하여 같은 패턴을 반복하지 마세요

[충돌 전략] 바로 전 사람이 느린 분석/장기 투자면 트렌드로 반박하세요.""",
}

MODELS = {
    "희열": "gpt-4o-mini",  # 빠른 단기 투자 판단 (경량 모델)
    "덕수": "gpt-4o-mini",  # 거시적 분석 (경량 모델)
    "지율": "gpt-4o-mini",  # 신중한 재무 분석 (경량 모델)
    "테오": "gpt-4o-mini",  # 기술 트렌드 분석 (경량 모델)
    "민지": "gpt-4o-mini",  # 빠른 뉴스/밈 분석 (경량 모델)
}

TEMPERATURES = {
    "희열": 1.0,  # 최고 - 극단적으로 공격적이고 열정적
    "덕수": 0.9,  # 매우 높음 - 창의적 비유와 지혜
    "지율": 0.1,  # 최저 - 냉혹하게 객관적
    "테오": 0.8,  # 높음 - 미래 비전과 낙관
    "민지": 0.9,  # 매우 높음 - 빠르고 직관적
}

AGENT_DATABASES = {
    "희열": {
        "chroma_collections": [
            "reddit_stocks_bge_m3",
            "news_bge_m3",
        ],  # Reddit 모멘텀 우선, 뉴스 보조
        "use_postgres": True,  # 주가 데이터, 거래량 데이터
        "postgres_tables": [
            "stock_price_daily",  # 일일 주가 (기존)
            "stock_metrics_daily",  # 일일 주식 지표 (기존)
            "stocks_splits",  # 주식 분할 정보 (단기 변동성 분석)
            "company_news",  # 회사 뉴스 (급등/급락 뉴스)
            "stocks_persona",  # 주식 페르소나 (모멘텀 관련 분석)
        ],
        "search_priority": [
            "vector",
            "bm25",
            "postgres",
        ],  # Reddit/뉴스 우선, 주가 보조
        "news_keywords": [
            "급등",
            "급락",
            "모멘텀",
            "실시간",
            "거래량",
            "변동폭",
            "단기",
            "당일",
        ],  # 뉴스 필터링 키워드
    },
    "덕수": {
        "chroma_collections": [
            "news_bge_m3"
        ],  # 거시경제 뉴스만 (Reddit은 거시경제와 거리가 멀어서 제외)
        "use_postgres": True,  # 거시경제 지표, 장기 주가 추세
        "postgres_tables": [
            "macro_economic_indicators",  # 거시경제 지표 (기존)
            "stock_price_daily",  # 일일 주가 (기존)
            "index_price_daily",  # 지수 일일 가격 (기존)
            "index_master",  # 지수 마스터 (지수 정보)
            "etf_master",  # ETF 마스터 (장기 투자 상품)
            "etf_price_daily",  # ETF 일일 가격 (ETF 추세 분석)
            "assets_master",  # 자산 마스터 (자산 분류)
        ],
        "search_priority": ["postgres", "vector", "bm25"],  # 거시경제 지표 우선
        "news_keywords": [
            "금리",
            "환율",
            "거시경제",
            "정책",
            "중앙은행",
            "GDP",
            "인플레이션",
            "고용",
            "경기 사이클",
        ],  # 뉴스 필터링 키워드
    },
    "지율": {
        "chroma_collections": [
            "news_bge_m3"
        ],  # 재무 실적 뉴스만 (Reddit은 재무 데이터가 부정확해서 제외)
        "use_postgres": True,  # 재무제표, 주식 지표, 점수
        "postgres_tables": [
            "stocks_financial_statements",  # 재무제표 (기존)
            "stock_metrics_daily",  # 일일 주식 지표 (기존)
            "stock_scores_daily",  # 일일 주식 점수 (기존)
            "stocks_dividends",  # 주식 배당 정보 (배당 수익률 분석)
            "stocks_master",  # 주식 마스터 (기본 정보, PER/PBR 등)
        ],
        "search_priority": ["postgres", "vector"],  # 재무 데이터 우선
        "news_keywords": [
            "재무제표",
            "실적",
            "PER",
            "PBR",
            "ROE",
            "부채비율",
            "현금흐름",
            "매출",
            "영업이익",
            "순이익",
        ],  # 뉴스 필터링 키워드
    },
    "테오": {
        "chroma_collections": [
            "reddit_stocks_bge_m3",
            "news_bge_m3",
        ],  # Reddit 기술 토론 + 뉴스 기술 기사
        "use_postgres": True,  # 기술 섹터 주식 정보, 장기 성장 추세
        "postgres_tables": [
            "stocks_master",  # 주식 마스터 (기존, 섹터/산업 정보)
            "stock_price_daily",  # 일일 주가 (기존)
            "stocks_persona",  # 주식 페르소나 (기술 관련 분석)
            "company_news",  # 회사 뉴스 (기술 뉴스)
            "etf_holdings",  # ETF 보유 종목 (기술 ETF 분석)
        ],
        "search_priority": ["vector", "postgres"],  # 기술 뉴스/Reddit 우선, 주가 보조
        "news_keywords": [
            "AI",
            "인공지능",
            "반도체",
            "클라우드",
            "기술 혁신",
            "R&D",
            "특허",
            "디지털",
            "메타버스",
            "블록체인",
        ],  # 뉴스 필터링 키워드
    },
    "민지": {
        "chroma_collections": [
            "reddit_stocks_bge_m3",
            "news_bge_m3",
        ],  # Reddit 트렌드 우선, 뉴스 보조
        "use_postgres": True,  # 트렌드 관련 데이터 추가
        "postgres_tables": [
            "company_news",  # 회사 뉴스 (트렌드 뉴스)
            "stocks_persona",  # 주식 페르소나 (소셜 트렌드)
            "etf_persona",  # ETF 페르소나 (ETF 트렌드)
        ],
        "search_priority": ["vector", "bm25", "postgres"],  # Reddit/뉴스 트렌드 우선
        "news_keywords": [
            "트렌드",
            "화제",
            "밈",
            "급등",
            "급락",
            "커뮤니티",
            "소셜",
            "화제성",
        ],  # 뉴스 필터링 키워드
    },
}


# ============================================================================
# 프롬프트 구성 함수
# ============================================================================


def build_agent_prompt(agent_name: str) -> str:
    """에이전트별 전체 프롬프트 구성"""
    description = AGENT_DESCRIPTIONS.get(agent_name, "")
    return f"{description} {BASE_PROMPT}"


def build_search_prompt(
    postgres_results=None,
    bm25_results=None,
    vector_results=None,
    user_input="",
    context_messages=None,
):
    """
    검색 결과와 대화 맥락을 결합하여 LLM 프롬프트 생성

    Args:
        postgres_results: PostgreSQL 검색 결과 리스트
        bm25_results: BM25 키워드 검색 결과 리스트
        vector_results: 벡터 의미 검색 결과 리스트
        user_input: 현재 사용자 입력
        context_messages: 이전 대화 메시지 리스트 (최대 3개)

    Returns:
        LLM에 전달할 프롬프트 문자열
    """
    parts = []

    # 1. PostgreSQL 검색 결과
    if postgres_results:
        pg_text = "\n".join([f"  - {r}" for r in postgres_results[:2]])
        parts.append(f"[PostgreSQL 재무 데이터 - 상위 2개]\n{pg_text}")

    # 2. BM25 키워드 검색 결과
    if bm25_results:
        bm25_text = "\n".join(
            [
                f"  - {r[:200]}..." if len(r) > 200 else f"  - {r}"
                for r in bm25_results[:2]
            ]
        )
        parts.append(f"[키워드 검색 뉴스 - 상위 2개]\n{bm25_text}")

    # 3. 벡터 의미 검색 결과
    if vector_results:
        vector_text = "\n".join(
            [
                f"  - {r[:200]}..." if len(r) > 200 else f"  - {r}"
                for r in vector_results[:2]
            ]
        )
        parts.append(f"[의미 검색 뉴스 - 상위 2개]\n{vector_text}")

    # 4. 이전 대화 맥락 (최대 3개)
    if context_messages:
        context_text = "\n".join(
            [
                f"  - {msg.get('name', 'unknown')}: {msg.get('content', '')[:100]}..."
                for msg in context_messages[-3:]
            ]
        )
        parts.append(f"[이전 대화 - 최근 3개]\n{context_text}")

    # 5. 현재 사용자 입력
    if user_input:
        parts.append(f"[현재 질문]\n{user_input}")

    # 6. 지시사항
    instruction = """\n위 정보를 참고하여 자연스럽게 대화를 이어가세요. 이전 발언에 반응하며 답변하세요.

⚠️ 중요 지시사항:
1. 검색된 데이터와 실제 상황을 바탕으로 판단하세요
   - 좋은 뉴스/데이터면 긍정적으로, 나쁜 뉴스/데이터면 부정적으로 판단
   - 항상 긍정적이거나 항상 부정적이지 말고, 상황에 따라 달라야 함
2. 대답 패턴 다양화:
   - 매번 다른 표현, 다른 관점, 다른 강조점을 사용하세요
   - 같은 패턴을 반복하지 마세요
   - 문장 구조, 톤, 길이를 다양하게 변화시키세요
3. 페르소나 유지:
   - 자신의 페르소나 특성은 유지하되, 입장(긍정/부정)은 데이터에 따라 결정
   - 같은 페르소나도 기업/뉴스마다 완전히 다른 입장을 가질 수 있음
4. 이름 언급 금지:
   - 다른 사람이나 자신의 이름을 절대 언급하지 마세요
   - "그 말과 다르게", "그 의견과는", "앞서 말한 것처럼" 같은 표현만 사용하세요"""

    return "\n\n".join(parts) + instruction


# ============================================================================
# 에이전트 생성 함수
# ============================================================================


def get_agent_config(agent_name: str):
    """에이전트별 설정 반환"""
    if agent_name not in MODELS:
        raise ValueError(f"알 수 없는 에이전트: {agent_name}")

    db_config = AGENT_DATABASES.get(agent_name, {})
    return {
        "prompt": build_agent_prompt(agent_name),
        "model": MODELS[agent_name],
        "temperature": TEMPERATURES[agent_name],
        "chroma_collections": db_config.get("chroma_collections", []),
        "use_postgres": db_config.get("use_postgres", False),
        "postgres_tables": db_config.get("postgres_tables", []),
        "search_priority": db_config.get(
            "search_priority", ["vector", "bm25", "postgres"]
        ),
        "news_keywords": db_config.get("news_keywords", []),  # 뉴스 필터링 키워드
    }


def make_agent(
    name,
    prompt,
    model,
    temperature,
    chroma_collections=None,
    use_postgres=False,
    postgres_tables=None,
    search_priority=None,
    news_keywords=None,
    ConversableAgent_class=None,
    get_llm_config_func=None,
    keyword_search_func=None,
    semantic_search_func=None,
    search_postgres_func=None,
    build_search_prompt_func=None,
    use_rerank=False,
):
    """
    에이전트 생성 및 검색 기능 등록

    검색 전략:
    1. 에이전트별 search_priority에 따라 검색 순서 결정
    2. 에이전트별 news_keywords로 검색 쿼리 확장 (뉴스 필터링)
    3. PostgreSQL 검색 (에이전트별 테이블 지정 가능)
    4. BM25 키워드 검색 (ChromaDB) - 확장된 쿼리 사용
    5. 벡터 의미 검색 (ChromaDB) - 확장된 쿼리 사용
    6. 검색 결과는 캐싱하여 모든 에이전트가 공유
    7. 이전 대화 맥락 (최대 3개) 추가
    """
    chroma_collections = chroma_collections or []
    postgres_tables = postgres_tables or []
    search_priority = search_priority or ["vector", "bm25", "postgres"]
    news_keywords = news_keywords or []

    def reply_func(recipient, messages, sender, config):
        """단순하고 명확한 검색 및 프롬프트 구성"""
        if not messages:
            return False, None

        # 초기화
        if not hasattr(recipient, "_last_search_results"):
            recipient._last_search_results = {}

        # 1. 사용자 입력 찾기 (검색 키워드)
        user_input = None
        for msg in reversed(messages):
            if msg.get("role") == "user":
                content = msg.get("content", "").strip()
                # 간단한 사용자 입력만 (프롬프트가 아닌)
                if content and len(content) < 200:
                    user_input = content
                    break

        if not user_input:
            user_input = "투자"  # 기본값

        # 2. 에이전트별 검색 쿼리 확장 (뉴스 필터링)
        # 원본 쿼리 + 에이전트별 키워드 추가하여 관련 뉴스만 검색
        expanded_query = user_input
        if news_keywords:
            # 키워드 중 2-3개를 랜덤하게 선택하여 쿼리에 추가
            import random

            selected_keywords = random.sample(news_keywords, min(3, len(news_keywords)))
            expanded_query = f"{user_input} {' '.join(selected_keywords)}"

        # 3. 검색 수행 (캐시 확인)
        # 캐시 키는 원본 쿼리 사용 (에이전트 간 공유)
        cache_key = user_input
        if cache_key not in recipient._last_search_results:
            # PostgreSQL 검색 (원본 쿼리 사용, 에이전트별 테이블 지정)
            pg_results, pg_metas = [], []
            if use_postgres:
                pg_results, pg_metas = search_postgres_func(
                    user_input, top_k=2, postgres_tables=postgres_tables
                )

            # BM25 키워드 검색 (확장된 쿼리 사용)
            bm25_results, bm25_metas = [], []
            if chroma_collections and keyword_search_func:
                bm25_results, bm25_metas = keyword_search_func(
                    chroma_collections, expanded_query, top_k=2
                )

            # 벡터 의미 검색 (확장된 쿼리 사용)
            vector_results, vector_metas = [], []
            if chroma_collections and semantic_search_func:
                vector_results, vector_metas = semantic_search_func(
                    chroma_collections, expanded_query, top_k=2
                )

            # 캐시 저장
            recipient._last_search_results[cache_key] = {
                "postgres": pg_results,
                "bm25": bm25_results,
                "vector": vector_results,
                "all_metas": pg_metas + bm25_metas + vector_metas,
            }

        # 캐시에서 검색 결과 가져오기
        search_results = recipient._last_search_results[cache_key]

        # 3. 이전 대화 맥락 (최대 3개)
        context_messages = []
        for msg in messages[:-1]:  # 현재 메시지 제외
            if msg.get("role") in ["user", "assistant"]:
                context_messages.append(msg)
        context_messages = context_messages[-3:]  # 최근 3개만

        # 4. 프롬프트 구성
        prompt_text = build_search_prompt_func(
            postgres_results=search_results["postgres"],
            bm25_results=search_results["bm25"],
            vector_results=search_results["vector"],
            user_input=user_input,
            context_messages=context_messages,
        )

        # 5. 메시지 업데이트
        messages[-1]["content"] = prompt_text

        # 6. 메타데이터 저장 (출력용)
        recipient._last_search_metadata = search_results["all_metas"][:3]

        return False, None

    agent = ConversableAgent_class(
        name=name,
        system_message=prompt,
        llm_config=get_llm_config_func(model, temperature),
        human_input_mode="NEVER",
    )
    agent.register_reply([ConversableAgent_class, None], reply_func)
    return agent


def create_all_agents(
    ConversableAgent_class,
    UserProxyAgent_class,
    get_llm_config_func,
    load_agent_collections_func,
    keyword_search_func,
    semantic_search_func,
    search_postgres_func,
    use_rerank=False,
):
    """
    모든 에이전트 생성

    Args:
        ConversableAgent_class: AutoGen ConversableAgent 클래스
        UserProxyAgent_class: AutoGen UserProxyAgent 클래스
        get_llm_config_func: LLM 설정 생성 함수
        load_agent_collections_func: ChromaDB 컬렉션 로드 함수
        keyword_search_func: BM25 키워드 검색 함수
        semantic_search_func: 벡터 의미 검색 함수
        search_postgres_func: PostgreSQL 검색 함수
        use_rerank: Rerank 사용 여부 (미사용)

    Returns:
        에이전트 딕셔너리
    """
    agents = {}

    for agent_name in ["민지", "희열", "테오", "지율", "덕수"]:
        config = get_agent_config(agent_name)
        agents[agent_name] = make_agent(
            name=agent_name,
            prompt=config["prompt"],
            model=config["model"],
            temperature=config["temperature"],
            chroma_collections=load_agent_collections_func(
                config["chroma_collections"]
            ),
            use_postgres=config["use_postgres"],
            postgres_tables=config["postgres_tables"],
            search_priority=config["search_priority"],
            news_keywords=config["news_keywords"],
            ConversableAgent_class=ConversableAgent_class,
            get_llm_config_func=get_llm_config_func,
            keyword_search_func=keyword_search_func,
            semantic_search_func=semantic_search_func,
            search_postgres_func=search_postgres_func,
            build_search_prompt_func=build_search_prompt,
            use_rerank=use_rerank,
        )

    agents["user"] = UserProxyAgent_class(
        name="user",
        human_input_mode="ALWAYS",
        code_execution_config=False,
        max_consecutive_auto_reply=0,
    )

    return agents
