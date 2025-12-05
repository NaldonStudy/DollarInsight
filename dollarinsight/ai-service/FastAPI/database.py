"""
데이터베이스 연결 및 로드 모듈
ChromaDB 및 PostgreSQL 관련 함수들
"""

import os
import sys
from dotenv import load_dotenv

load_dotenv()

# pysqlite3를 sqlite3로 교체 (ChromaDB 호환성)
try:
    import pysqlite3

    sys.modules["sqlite3"] = pysqlite3
except ImportError:
    pass

from chromadb import HttpClient
from chromadb.config import Settings

# ============================================================================
# 환경 변수
# ============================================================================

CHROMADB_URL = os.getenv(
    "CHROMADB_URL", "dollar-insight-chromadb"
)  # Docker 네트워크 내에서는 컨테이너 이름 사용
CHROMADB_PORT = int(os.getenv("CHROMADB_PORT", "8000"))  # ChromaDB 기본 포트는 8000

POSTGRESQL_URL = os.getenv("POSTGRESQL_URL")
if not POSTGRESQL_URL:
    raise ValueError("POSTGRESQL_URL가 .env 파일에 설정되지 않았습니다.")
POSTGRESQL_NAME = os.getenv("POSTGRESQL_NAME", "dollar_insight")
POSTGRESQL_USER = os.getenv("POSTGRESQL_USER")
if not POSTGRESQL_USER:
    raise ValueError("POSTGRESQL_USER가 .env 파일에 설정되지 않았습니다.")
# ⚠️ 민감 정보: .env 파일에서 POSTGRESQL_PASSWORD를 반드시 설정하세요
POSTGRESQL_PASSWORD = os.getenv("POSTGRESQL_PASSWORD")
if not POSTGRESQL_PASSWORD:
    raise ValueError("POSTGRESQL_PASSWORD가 .env 파일에 설정되지 않았습니다.")
POSTGRESQL_PORT = os.getenv("POSTGRESQL_PORT", "5432")
POSTGRES_CONN = os.getenv(
    "POSTGRES_CONN",
    f"postgresql://{POSTGRESQL_USER}:{POSTGRESQL_PASSWORD}@{POSTGRESQL_URL}:{POSTGRESQL_PORT}/{POSTGRESQL_NAME}",
)

OPENAI_API_KEY = os.getenv("GMS_API_KEY")
if not OPENAI_API_KEY:
    raise ValueError("GMS_API_KEY가 .env 파일에 설정되지 않았습니다.")

GMS_BASE_URL = "https://gms.ssafy.io/gmsapi/api.openai.com/v1"
GEMINI_BASE_URL = "https://gms.ssafy.io/gmsapi/generativelanguage.googleapis.com/v1beta"

# ============================================================================
# 전역 캐시
# ============================================================================

_postgres_conn = None
_schema_cache = None


# ============================================================================
# ChromaDB 연결 및 로드
# ============================================================================


def make_chroma_client():
    """ChromaDB 클라이언트 생성"""
    return HttpClient(
        host=CHROMADB_URL,
        port=CHROMADB_PORT,
        settings=Settings(anonymized_telemetry=False),
    )


def load_agent_collections(collection_names):
    """에이전트별 컬렉션 이름 리스트를 받아서 ChromaDB 컬렉션 객체 리스트 반환"""
    if not collection_names:
        return []

    client = make_chroma_client()
    collections = []
    for name in collection_names:
        try:
            col = client.get_collection(name)
            collections.append(col)
            print(f"ChromaDB 컬렉션 로드: {name}")
        except Exception:
            print(f"경고: 컬렉션 '{name}'을 찾지 못했습니다.")

    return collections


# ============================================================================
# PostgreSQL 연결 및 검색
# ============================================================================


def get_postgres_connection():
    """PostgreSQL 연결 가져오기 (캐싱)"""
    global _postgres_conn
    if (_postgres_conn is None) or getattr(_postgres_conn, "closed", 1):
        import psycopg2

        _postgres_conn = psycopg2.connect(POSTGRES_CONN)
        # autocommit 모드로 설정하여 각 SQL이 독립적으로 실행되도록 함
        # 이렇게 하면 하나의 SQL 실패가 다른 SQL에 영향을 주지 않음
        _postgres_conn.autocommit = True
    return _postgres_conn


def get_schema_cache():
    """PostgreSQL 스키마 캐시 가져오기 (모든 테이블 정보)"""
    global _schema_cache
    if _schema_cache is not None:
        return _schema_cache

    try:
        conn = get_postgres_connection()
        cur = conn.cursor()

        # 모든 테이블 정보 가져오기
        cur.execute(
            """
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_type = 'BASE TABLE'
            ORDER BY table_name
        """
        )
        tables = [row[0] for row in cur.fetchall()]

        # 각 테이블의 컬럼 정보 가져오기
        schema_info = {}
        for table in tables:
            cur.execute(
                """
                SELECT column_name, data_type, is_nullable
                FROM information_schema.columns 
                WHERE table_schema = 'public' 
                AND table_name = %s
                ORDER BY ordinal_position
            """,
                (table,),
            )
            columns = [
                {"name": row[0], "type": row[1], "nullable": row[2] == "YES"}
                for row in cur.fetchall()
            ]
            schema_info[table] = columns

        _schema_cache = schema_info
        print(f"PostgreSQL 스키마 로딩: {len(tables)}개 테이블")
        return _schema_cache
    except Exception as e:
        print(f"PostgreSQL 스키마 로딩 실패: {e}")
        _schema_cache = {}
        return _schema_cache


def get_table_schema_info(table_names):
    """지정된 테이블들의 스키마 정보를 문자열로 반환 (JOIN 관계 포함)"""
    schema_cache = get_schema_cache()
    if not schema_cache:
        return ""

    # 테이블 간 관계 정의
    table_relationships = {
        "stocks_financial_statements": {
            "joins": ["stocks_master"],
            "join_key": "ticker",
            "description": "재무제표 데이터. stocks_master와 JOIN하여 종목 정보를 가져올 수 있음",
        },
        "stocks_master": {
            "joins": [],
            "join_key": "ticker",
            "description": "종목 마스터 정보 (PER, PBR, 시가총액 등 밸류에이션 지표 포함)",
        },
        "stock_price_daily": {
            "joins": ["stocks_master"],
            "join_key": "ticker",
            "description": "일별 주가 데이터. stocks_master와 JOIN하여 종목 정보를 가져올 수 있음",
        },
        "company_news": {
            "joins": ["stocks_master"],
            "join_key": "ticker",
            "description": "종목 뉴스. stocks_master와 JOIN하여 종목 정보를 가져올 수 있음",
        },
        "stock_metrics_daily": {
            "joins": ["stocks_master"],
            "join_key": "ticker",
            "description": "일별 기술적 지표. stocks_master와 JOIN하여 종목 정보를 가져올 수 있음",
        },
        "stocks_dividends": {
            "joins": ["stocks_master"],
            "join_key": "ticker",
            "description": "배당 정보. stocks_master와 JOIN하여 종목 정보를 가져올 수 있음",
        },
    }

    schema_texts = []
    for table_name in table_names:
        if table_name not in schema_cache:
            continue

        columns = schema_cache[table_name]
        col_info = ", ".join([f"{col['name']} ({col['type']})" for col in columns])

        # 테이블 정보
        table_info = f"Table: {table_name}\nColumns: {col_info}\n"

        # 관계 정보 추가
        if table_name in table_relationships:
            rel = table_relationships[table_name]
            table_info += f"Description: {rel['description']}\n"
            if rel["joins"]:
                table_info += f"Can JOIN with: {', '.join(rel['joins'])} ON {table_name}.{rel['join_key']} = {{joined_table}}.{rel['join_key']}\n"

        schema_texts.append(table_info)

    return "\n".join(schema_texts)


def is_structured_query(text):
    """정형 데이터 질문인지 판단"""
    kws = [
        "매출",
        "순이익",
        "재무재표",
        "수익",
        "이익",
        "자산",
        "부채",
        "ROE",
        "ROA",
        "영업현금흐름",
        "매출액",
        "주가",
        "PER",
        "PBR",
        "거래량",
        "시가총액",
    ]
    if any(kw in text for kw in kws):
        return True
    # 테이블명이 쿼리에 포함되어 있는지 확인
    schema = get_schema_cache()
    if schema:
        table_names = list(schema.keys())
        return any(table_name.lower() in text.lower() for table_name in table_names)
    return False


def search_postgres(query, top_k=2, postgres_tables=None):
    """
    PostgreSQL에서 키워드 검색 (LLM으로 SQL 생성)

    Args:
        query: 검색 쿼리 (키워드 포함)
        top_k: 반환할 결과 수 (기본값: 2)
        postgres_tables: 검색할 테이블 리스트 (None이면 모든 테이블 사용)

    Returns:
        (결과 리스트, 메타데이터 리스트) 튜플
    """
    if not POSTGRES_CONN or not query.strip():
        return [], []

    try:
        from openai import OpenAI
        import time

        start_time = time.time()

        # 1. 스키마 정보 가져오기
        schema_cache = get_schema_cache()
        if not schema_cache:
            return [], []

        # 사용할 테이블 결정
        if postgres_tables:
            # 에이전트별로 지정된 테이블만 사용
            available_tables = [t for t in postgres_tables if t in schema_cache]
            if not available_tables:
                print(
                    f"[PostgreSQL] 지정된 테이블을 찾을 수 없습니다: {postgres_tables}"
                )
                return [], []
        else:
            # 모든 테이블 사용
            available_tables = list(schema_cache.keys())

        # 2. 테이블 스키마 정보를 문자열로 구성
        schema_info = get_table_schema_info(available_tables)
        if not schema_info:
            return [], []

        # 3. LLM으로 SQL 생성
        client_llm = OpenAI(api_key=OPENAI_API_KEY, base_url=GMS_BASE_URL)

        sql_prompt = (
            f"Query: {query}\n\n"
            f"Available tables and columns:\n{schema_info}\n\n"
            "Generate a PostgreSQL query following these rules:\n\n"
            "1. TABLE ALIASES (MANDATORY - ALWAYS USE):\n"
            "   - stocks_master → sm\n"
            "   - stocks_financial_statements → sf\n"
            "   - stock_price_daily → spd\n"
            "   - company_news → cn\n"
            "   - stock_metrics_daily → smd\n"
            "   - stocks_dividends → sd\n\n"
            "2. COLUMN OWNERSHIP (CRITICAL - CHECK BEFORE USE):\n"
            "   - sm ONLY: per, pbr, market_cap, current_price, name, ticker, sector_name, industry\n"
            "   - sf ONLY: revenue, net_income, operating_income, period, period_type, ticker\n"
            "   - spd ONLY: close, open, high, low, volume, price_date, ticker, change_pct\n"
            "   - cn ONLY: title, summary, published_at, ticker, url\n"
            "   - smd ONLY: mom_1m, mom_3m, mom_6m, ticker, metric_date\n\n"
            "3. JOIN REQUIREMENTS (MANDATORY WHEN NEEDING MULTIPLE TABLES):\n"
            "   - If query asks for columns from DIFFERENT tables, you MUST JOIN them\n"
            "   - Example: Query asks for 'PER and revenue' → JOIN sm and sf\n"
            "   - Example: Query asks for 'price and name' → JOIN spd and sm\n"
            "   - JOIN pattern: FROM table1 alias1 JOIN table2 alias2 ON alias1.ticker = alias2.ticker\n"
            "   - ALWAYS use table aliases in SELECT and JOIN clauses\n\n"
            "4. CORRECT EXAMPLES:\n"
            "   - PER + revenue: SELECT sm.per, sf.revenue FROM stocks_master sm JOIN stocks_financial_statements sf ON sm.ticker = sf.ticker WHERE sm.name LIKE '%애플%'\n"
            "   - Price + name: SELECT sm.name, spd.close FROM stocks_master sm JOIN stock_price_daily spd ON sm.ticker = spd.ticker WHERE sm.ticker = 'NVDA'\n"
            "   - PER only: SELECT sm.per FROM stocks_master sm WHERE sm.ticker = 'TSLA'\n"
            "   - Revenue only: SELECT sf.revenue FROM stocks_financial_statements sf WHERE sf.ticker = 'AAPL'\n\n"
            "5. CRITICAL ERRORS TO AVOID:\n"
            "   ❌ WRONG: SELECT per, revenue FROM stocks_master (revenue is NOT in stocks_master)\n"
            "   ✅ CORRECT: SELECT sm.per, sf.revenue FROM stocks_master sm JOIN stocks_financial_statements sf ON sm.ticker = sf.ticker\n"
            "   ❌ WRONG: SELECT sf.per (per is NOT in stocks_financial_statements)\n"
            "   ✅ CORRECT: SELECT sm.per (per is in stocks_master)\n"
            "   ❌ WRONG: SELECT ticker, per, revenue FROM stocks_master (revenue needs JOIN)\n"
            "   ✅ CORRECT: SELECT sm.ticker, sm.per, sf.revenue FROM stocks_master sm JOIN stocks_financial_statements sf ON sm.ticker = sf.ticker\n\n"
            "6. DECISION FLOW:\n"
            "   Step 1: Identify which columns are needed\n"
            "   Step 2: Check which table each column belongs to\n"
            "   Step 3: If columns are from different tables → MUST JOIN\n"
            "   Step 4: Use appropriate table aliases (sm, sf, spd, cn, etc.)\n"
            "   Step 5: Add WHERE clause and LIMIT\n\n"
            "7. QUERY FORMAT:\n"
            f"   - Add WHERE clause based on query\n"
            f"   - Add LIMIT {top_k}\n"
            "   - Use proper PostgreSQL syntax\n"
            "   - Return only relevant columns (avoid SELECT *)\n\n"
            "SQL Query:"
        )

        resp = client_llm.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {
                    "role": "system",
                    "content": """You are a PostgreSQL expert. Your task is to generate valid SQL queries.

CRITICAL RULES:
1. ALWAYS use table aliases (sm, sf, spd, cn, smd) when referencing columns
2. NEVER reference a column without its table alias prefix
3. If you need columns from multiple tables, you MUST JOIN them
4. Return ONLY the SQL query - no markdown, no explanations, no backticks
5. Verify each column exists in the table you're referencing it from

Common aliases:
- sm = stocks_master (contains: per, pbr, market_cap, current_price, name, ticker)
- sf = stocks_financial_statements (contains: revenue, net_income, operating_income, period, ticker)
- spd = stock_price_daily (contains: close, open, high, low, volume, price_date, ticker)
- cn = company_news (contains: title, summary, published_at, ticker)
- smd = stock_metrics_daily (contains: mom_1m, mom_3m, mom_6m, ticker)

JOIN pattern: Always JOIN on ticker column (e.g., sf.ticker = sm.ticker)""",
                },
                {"role": "user", "content": sql_prompt},
            ],
            temperature=0,
        )

        sql = resp.choices[0].message.content.strip()
        # 마크다운 제거
        if sql.startswith("```"):
            sql = sql.split("```")[1] if len(sql.split("```")) > 1 else sql
        sql = sql.replace("sql\n", "").replace("postgresql\n", "").strip()

        # SQL 로그 출력 (디버깅용)
        print(f"[PostgreSQL 생성된 SQL] {sql}")

        # 4. SQL 실행
        conn = get_postgres_connection()
        cur = conn.cursor()
        try:
            cur.execute(sql)
            rows = cur.fetchall()

            # 컬럼명 가져오기
            column_names = (
                [desc[0] for desc in cur.description] if cur.description else []
            )

            # 5. 결과 포맷팅
            results = []
            metas = []
            for row in rows:
                # 컬럼명과 값을 매핑하여 문자열로 변환
                if column_names:
                    row_dict = dict(zip(column_names, row))
                    row_str = ", ".join(
                        [
                            f"{k}: {v}" if v is not None else f"{k}: N/A"
                            for k, v in row_dict.items()
                        ]
                    )
                else:
                    row_str = ", ".join(
                        [str(v) if v is not None else "N/A" for v in row]
                    )
                results.append(row_str)
                metas.append({"source": "postgresql", "tables": available_tables})

            elapsed = time.time() - start_time
            print(f"[PostgreSQL 검색 완료] {len(results)}개 결과 ({elapsed:.2f}초)")

            return results, metas
        except Exception as sql_error:
            # autocommit 모드이므로 롤백 불필요
            # 에러를 상위로 전달하여 처리
            raise sql_error

    except Exception as e:
        print(f"[PostgreSQL 오류] {type(e).__name__}: {e}")
        import traceback

        traceback.print_exc()
        return [], []
