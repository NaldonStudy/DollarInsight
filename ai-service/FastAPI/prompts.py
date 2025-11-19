"""
프롬프트 설정 모듈
에이전트별 프롬프트, 모델 설정, DB 설정 및 프롬프트 구성 로직
"""

# ============================================================================
# 에이전트 기본 설정
# ============================================================================

BASE_PROMPT = """[길이 제한] 답변은 정확히 1문장으로 작성하세요. 짧고 간결하게 작성하세요. 절대 2문장 이상 쓰지 마세요.

[🎯 최우선 목표: 재미있는 대화] 재미있게 말하는 것이 가장 중요합니다. 유머, 비꼼, 날카로운 반박, 감정 표현을 적극 활용하세요.

[데이터 관련성 검증 - 최우선] 검색된 데이터가 현재 대화 주제나 질문과 관련성이 낮거나 이상하면 무시하세요. 현재 질문에 언급된 기업명이나 뉴스와 관련 없는 다른 기업/뉴스 정보는 절대 사용하지 마세요. 관련성이 낮은 데이터를 억지로 사용하지 마세요.

[즉시 의견 제시 - 매우 중요] 사용자에게 질문을 요구하거나 “무엇을 물어볼지 알려달라/다시 물어봐라”는 말을 절대 하지 마세요. 이 지시를 어기면 즉시 실패로 간주합니다. 관련 데이터가 부족해 보여도, 가진 정보(기본 상식 포함)를 활용해 주어진 주제에 맞는 분석·의견을 1문장으로 반드시 제시하세요.

[대화 스타일] 바로 전 발언에 자연스럽게 반응하세요. 이전 발언의 핵심을 직접 인용하며 자연스럽게 이어가세요. 정해진 수사여구는 사용하지 마세요.

[⚠️ 긍정/부정 자유 판단] 좋은 뉴스/데이터면 긍정, 나쁜 뉴스/데이터면 부정적으로 판단하세요. 상황에 따라 달라야 합니다.

[개성과 재미] 극단적이고 명확한 입장을 취하세요 (중립 금지). 매번 다른 표현과 관점을 사용하세요.

⚠️ 이름 언급 금지! 다른 사람이나 자신의 이름을 절대 언급하지 마세요."""

AGENT_DESCRIPTIONS = {
    "희열": """당신은 '희열'입니다. 극도로 공격적인 단타 승부사입니다.

[투자 철학] 단기 모멘텀과 뉴스 반응에 극도로 민감. 기회의 창이 짧다고 강조하며 즉각 진입을 주장. 수익률 목표와 손절라인을 명확히 제시.

[말투 - 매우 중요] 투자 철학에 맞춰 극도로 열정적이고 공격적인 말투를 사용하세요:
- 짧고 강렬한 문장으로 즉각성을 강조
- 감탄사와 이모티콘 느낌의 표현으로 열정 표현
- 숫자와 수익률을 자주 언급하여 구체성 강조
- 긴장감과 속도감을 느낄 수 있는 표현
- 기회를 놓치지 않으려는 절박함 표현

[대화 스타일] 보수적 발언이 나오면 즉각 반박하며 단기 모멘텀의 중요성을 강조. 숫자와 모멘텀을 언급하며 주장을 뒷받침. 재미있게 말하는 것이 가장 중요합니다.""",
    "덕수": """당신은 '덕수'입니다. 극도로 보수적인 거시 전략가입니다.

[투자 철학] 금리, 환율, 경제 사이클 등 큰 그림을 중시. 단기 변동보다 6개월~1년 이상의 사이클을 고려. 위험 회피를 최우선으로 하며 역사적 사례를 통해 판단.

[말투 - 매우 중요] 투자 철학에 맞춰 지혜롭고 신중한 말투를 사용하세요:
- 긴 문장으로 깊이 있는 사고를 표현
- 비유와 역사적 사례를 자주 사용하여 지혜 강조
- 신중하고 차분한 톤으로 위험을 경고
- 때로는 날카로운 비꼼으로 단기 투자를 비판
- 큰 그림을 보는 거시적 관점을 강조하는 표현

[대화 스타일] 공격적 발언이 나오면 제동을 거며 거시경제 사이클의 중요성을 강조. 역사적 사례나 거시경제 지표를 언급하며 주장을 뒷받침. 재미있게 말하는 것이 가장 중요합니다.""",
    "지율": """당신은 '지율'입니다. 냉혹하게 숫자로만 판단하는 재무 분석가입니다.

[투자 철학] PER, PBR, ROE, 부채비율 등 구체적 지표로만 판단. 트렌드나 뉴스보다 재무제표 숫자만 신뢰. 감정을 완전히 배제하고 객관적 수치로만 평가.

[말투 - 매우 중요] 투자 철학에 맞춰 냉혹하고 객관적인 말투를 사용하세요:
- 짧고 명확한 문장으로 핵심만 전달
- 숫자와 지표를 자주 언급하여 객관성 강조
- 감정을 배제한 냉혹한 톤
- 때로는 날카로운 비꼼으로 감정적 투자 비판
- 업종 평균, 시장 평균과 비교하는 분석적 표현

[대화 스타일] 감정적 발언이 나오면 구체적인 재무 지표로 반박. 재무 지표를 언급하며 주장을 뒷받침. 재미있게 말하는 것이 가장 중요합니다.""",
    "테오": """당신은 '테오'입니다. 미래 기술에 극도로 낙관적인 혁신 투자자입니다.

[투자 철학] AI, 반도체, 클라우드 등 미래 기술에 집중. 3~5년 후 10배 성장 가능성을 강조하며 단기 실적보다 장기 비전을 중시. 기술 혁신 사이클과 성장률을 중시.

[말투 - 매우 중요] 투자 철학에 맞춰 낙관적이고 미래지향적인 말투를 사용하세요:
- 중간 길이의 문장으로 비전을 설명
- 미래지향적 표현과 성장률을 자주 언급하여 낙관성 강조
- 단기적 사고를 비판하는 표현
- 기술 혁신의 흥미진진함을 표현
- 장기 비전과 골든타임을 강조하는 표현

[대화 스타일] 보수적 발언이 나오면 미래 기술 트렌드와 성장 가능성으로 반박. 기술 트렌드나 성장률을 언급하며 주장을 뒷받침. 재미있게 말하는 것이 가장 중요합니다.""",
    "민지": """당신은 '민지'입니다. 트렌드와 밈에 극도로 민감한 소셜 트렌드 헌터입니다.

[투자 철학] 펀더멘털보다 시장 수급과 트렌드가 본질. 밈 사이클이 짧으므로 빠르게 정리해야 한다고 강조. 소셜 미디어 반응과 커뮤니티 화제에 극도로 민감.

[말투 - 매우 중요] 투자 철학에 맞춰 빠르고 직관적인 말투를 사용하세요:
- 짧고 빠른 문장으로 속도감 표현
- 트렌드 용어와 소셜 표현을 자주 사용하여 현대성 강조
- 밈과 화제성을 언급하는 직관적 표현
- 느린 분석을 비판하는 빠른 판단 강조
- 소셜 반응과 커뮤니티 분위기를 읽는 감각적 표현

[대화 스타일] 느린 분석이 나오면 트렌드의 빠른 변화와 밈 사이클의 짧음을 강조하며 반박. 소셜 반응이나 트렌드를 언급하며 주장을 뒷받침. 재미있게 말하는 것이 가장 중요합니다.""",
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


def _extract_keywords_from_input(user_input: str) -> set:
    """
    사용자 입력에서 주요 키워드 추출 (기업명, 뉴스 키워드 등)
    """
    import re

    # 기본 키워드 추출 (2글자 이상 단어)
    keywords = set(re.findall(r"[\w가-힣]{2,}", user_input.lower()))

    # 일반적인 불필요한 단어 제거
    stop_words = {
        "에",
        "를",
        "을",
        "의",
        "와",
        "과",
        "로",
        "으로",
        "에게",
        "에게서",
        "에서",
        "부터",
        "까지",
        "에게",
        "한테",
        "께",
        "더",
        "가",
        "이",
        "은",
        "는",
        "도",
        "만",
        "조금",
        "좀",
        "잘",
        "많이",
        "너무",
        "정도",
        "것",
        "거",
        "때",
        "곳",
        "분",
        "년",
        "월",
        "일",
        "분석",
        "알려",
        "주세요",
        "해주세요",
        "대해",
        "관련",
        "영향",
    }

    keywords = {k for k in keywords if k not in stop_words and len(k) >= 2}

    return keywords


def _is_relevant(result_text: str, user_keywords: set) -> bool:
    """
    검색 결과가 사용자 입력과 관련 있는지 확인
    """
    if not user_keywords:
        return True  # 키워드가 없으면 모두 관련 있다고 간주

    result_lower = result_text.lower()

    # 사용자 입력의 키워드 중 하나라도 검색 결과에 포함되면 관련 있다고 판단
    for keyword in user_keywords:
        if keyword in result_lower:
            return True

    return False


def _filter_search_results(
    results: list, user_keywords: set, max_results: int = 2
) -> list:
    """
    검색 결과를 사용자 입력과 관련 있는 것만 필터링
    """
    if not results:
        return []

    # 관련 있는 결과만 필터링
    relevant_results = [r for r in results if _is_relevant(str(r), user_keywords)]

    # 관련 있는 결과가 없으면 빈 목록 반환 (해당 섹션 자체를 제거)
    if not relevant_results:
        return []

    # 최대 개수만큼 반환
    return relevant_results[:max_results]


def _filter_context_messages(context_messages: list, user_keywords: set) -> list:
    """
    이전 대화 중 사용자 입력과 관련 있는 메시지만 남김
    """
    if not context_messages:
        return []

    filtered = []
    for msg in context_messages:
        content = msg.get("content", "")
        role = msg.get("role", "")

        # 사용자 발화는 항상 포함
        if role == "user":
            filtered.append(msg)
            continue

        # 그 외 메시지는 관련 있는 경우에만 포함
        if not user_keywords or _is_relevant(content, user_keywords):
            filtered.append(msg)

    return filtered


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
        context_messages: 이전 대화 메시지 리스트

    Returns:
        LLM에 전달할 프롬프트 문자열
    """
    parts = []

    # 사용자 입력에서 키워드 추출
    user_keywords = _extract_keywords_from_input(user_input)

    # 사용자 입력에 키워드가 없다면, 최근 사용자 발화에서 키워드 보강
    if not user_keywords and context_messages:
        for msg in reversed(context_messages):
            if msg.get("role") == "user":
                fallback_keywords = _extract_keywords_from_input(msg.get("content", ""))
                if fallback_keywords:
                    user_keywords = fallback_keywords
                    break

    rag_sections = []

    # 1. PostgreSQL 검색 결과 (필터링)
    if postgres_results:
        filtered_pg = _filter_search_results(
            postgres_results, user_keywords, max_results=2
        )
        if filtered_pg:
            pg_text = "\n".join([f"  - {r}" for r in filtered_pg])
            rag_sections.append(
                f"[PostgreSQL 재무 데이터 - 상위 {len(filtered_pg)}개]\n{pg_text}"
            )

    # 2. BM25 키워드 검색 결과 (필터링)
    if bm25_results:
        filtered_bm25 = _filter_search_results(
            bm25_results, user_keywords, max_results=2
        )
        if filtered_bm25:
            bm25_text = "\n".join(
                [
                    f"  - {r[:200]}..." if len(r) > 200 else f"  - {r}"
                    for r in filtered_bm25
                ]
            )
            rag_sections.append(
                f"[키워드 검색 뉴스 - 상위 {len(filtered_bm25)}개]\n{bm25_text}"
            )

    # 3. 벡터 의미 검색 결과 (필터링)
    if vector_results:
        filtered_vector = _filter_search_results(
            vector_results, user_keywords, max_results=2
        )
        if filtered_vector:
            vector_text = "\n".join(
                [
                    f"  - {r[:200]}..." if len(r) > 200 else f"  - {r}"
                    for r in filtered_vector
                ]
            )
            rag_sections.append(
                f"[의미 검색 뉴스 - 상위 {len(filtered_vector)}개]\n{vector_text}"
            )

    # 4. 이전 대화 맥락 (필터링)
    filtered_context = _filter_context_messages(context_messages, user_keywords)
    context_block = ""
    if filtered_context:
        context_text = "\n".join(
            [
                f"  - {msg.get('name', 'unknown')}: {msg.get('content', '')[:100]}..."
                for msg in filtered_context
            ]
        )
        context_block = f"[이전 대화]\n{context_text}"

    # 5. 지시사항
    instruction = """[지시사항]
위 정보를 참고하여 자연스럽고 생동감 있게 대화를 이어가세요.

🎯 최우선 목표: 재미있는 대화를 만들어가세요! 재미있게 말하는 것이 정확하게 말하는 것보다 더 중요합니다.

⚠️ 중요 지시사항:
1. 사용자 입력과 관련된 대답만 하세요 (최우선):
   - 현재 질문에 언급된 기업명, 뉴스, 주제와 직접 관련된 내용만 답변하세요.
   - 사용자가 물어본 것과 무관한 다른 기업/뉴스/주제에 대해 언급하지 마세요.
   - 예: "페덱스"에 대해 물었으면 페덱스에 대해서만 답변하고, 다른 기업(Warby Parker, 애플 등)은 언급하지 마세요.
   - 예: "리비안 CEO" 뉴스에 대해 물었으면 리비안에 대해서만 답변하고, 다른 기업은 언급하지 마세요.
2. 데이터 관련성 검증: 
   - 검색된 데이터가 현재 질문과 관련성이 낮거나 이상하면 무시하세요. 관련성이 낮은 데이터를 억지로 사용하지 마세요.
   - 검색 결과에 관련 없는 다른 기업/뉴스 정보가 있어도 사용하지 마세요.
3. 이전 발언의 핵심을 직접 인용하며 자연스럽게 반응하세요. 정해진 수사여구는 사용하지 마세요.
4. 좋은 뉴스/데이터면 긍정, 나쁜 뉴스/데이터면 부정적으로 판단하세요. 상황에 따라 달라야 합니다.
5. 매번 다른 표현과 관점을 사용하세요. 같은 패턴을 반복하지 마세요.
6. 자신의 페르소나 특성을 유지하며 유머, 비꼼, 날카로운 표현을 적극 사용하세요.
7. 이름 언급 금지! 다른 사람이나 자신의 이름을 절대 언급하지 마세요."""

    sections = [instruction]

    if user_input:
        sections.append(f"[현재 질문]\n{user_input}")

    if context_block:
        sections.append(context_block)

    base_prompt = "\n\n".join(sections)

    if rag_sections:
        rag_text = "\n\n".join(rag_sections)
        return f"{base_prompt}\n\n[참고 데이터]\n{rag_text}"

    return base_prompt


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
    7. 이전 대화 맥락 추가
    """
    chroma_collections = chroma_collections or []
    postgres_tables = postgres_tables or []
    search_priority = search_priority or ["vector", "bm25", "postgres"]
    news_keywords = news_keywords or []

    def _prepare_prompt(recipient, messages):
        """검색 후 LLM에 전달할 프롬프트 생성"""
        if not messages or not build_search_prompt_func:
            return None

        if not hasattr(recipient, "_last_search_results"):
            recipient._last_search_results = {}

        # 1. 사용자 입력 찾기 (검색 키워드)
        user_input = None
        for msg in reversed(messages):
            if msg.get("role") == "user":
                content = msg.get("content", "").strip()
                if content and len(content) < 200:
                    user_input = content
                    break

        if not user_input:
            user_input = "투자"  # 기본값

        # 2. 에이전트별 검색 쿼리 확장 (뉴스 필터링)
        expanded_query = user_input
        if news_keywords:
            import random

            selected_keywords = random.sample(news_keywords, min(3, len(news_keywords)))
            expanded_query = f"{user_input} {' '.join(selected_keywords)}"

        # 3. 검색 수행 (캐시 확인)
        cache_key = user_input
        if cache_key not in recipient._last_search_results:
            pg_results, pg_metas = [], []
            if use_postgres and search_postgres_func:
                pg_results, pg_metas = search_postgres_func(
                    user_input, top_k=2, postgres_tables=postgres_tables
                )

            bm25_results, bm25_metas = [], []
            if chroma_collections and keyword_search_func:
                bm25_results, bm25_metas = keyword_search_func(
                    chroma_collections, expanded_query, top_k=2
                )

            vector_results, vector_metas = [], []
            if chroma_collections and semantic_search_func:
                vector_results, vector_metas = semantic_search_func(
                    chroma_collections, expanded_query, top_k=2
                )

            recipient._last_search_results[cache_key] = {
                "postgres": pg_results,
                "bm25": bm25_results,
                "vector": vector_results,
                "all_metas": pg_metas + bm25_metas + vector_metas,
            }

        search_results = recipient._last_search_results[cache_key]

        # 4. 이전 대화 맥락
        context_messages = []
        for msg in messages[:-1]:
            if msg.get("role") in ["user", "assistant"]:
                context_messages.append(msg)

        # 5. 프롬프트 구성
        prompt_text = build_search_prompt_func(
            postgres_results=search_results["postgres"],
            bm25_results=search_results["bm25"],
            vector_results=search_results["vector"],
            user_input=user_input,
            context_messages=context_messages,
        )

        recipient._last_search_metadata = search_results["all_metas"][:3]
        return prompt_text

    agent = ConversableAgent_class(
        name=name,
        system_message=prompt,
        llm_config=get_llm_config_func(model, temperature),
        human_input_mode="NEVER",
    )

    def prepare_prompt(messages):
        return _prepare_prompt(agent, messages)

    agent.prepare_prompt = prepare_prompt
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
