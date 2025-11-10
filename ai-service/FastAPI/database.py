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
    sys.modules['sqlite3'] = pysqlite3
except ImportError:
    pass

from chromadb import HttpClient
from chromadb.config import Settings

# ============================================================================
# 환경 변수
# ============================================================================

CHROMADB_URL = os.getenv("CHROMADB_URL", "dollar-insight-chromadb")  # Docker 네트워크 내에서는 컨테이너 이름 사용
CHROMADB_PORT = int(os.getenv("CHROMADB_PORT", "8000"))  # ChromaDB 기본 포트는 8000

POSTGRESQL_URL = os.getenv("POSTGRESQL_URL", "3.34.50.3")
POSTGRESQL_NAME = os.getenv("POSTGRESQL_NAME", "dollar_insight")
POSTGRESQL_USER = os.getenv("POSTGRESQL_USER", "dopamine")
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
        cur.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_type = 'BASE TABLE'
            ORDER BY table_name
        """)
        tables = [row[0] for row in cur.fetchall()]

        # 각 테이블의 컬럼 정보 가져오기
        schema_info = {}
        for table in tables:
            cur.execute("""
                SELECT column_name, data_type, is_nullable
                FROM information_schema.columns 
                WHERE table_schema = 'public' 
                AND table_name = %s
                ORDER BY ordinal_position
            """, (table,))
            columns = [
                {
                    "name": row[0],
                    "type": row[1],
                    "nullable": row[2] == "YES"
                }
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
    """지정된 테이블들의 스키마 정보를 문자열로 반환"""
    schema_cache = get_schema_cache()
    if not schema_cache:
        return ""
    
    schema_texts = []
    for table_name in table_names:
        if table_name not in schema_cache:
            continue
        
        columns = schema_cache[table_name]
        col_info = ", ".join([f"{col['name']} ({col['type']})" for col in columns])
        schema_texts.append(f"Table: {table_name}\nColumns: {col_info}\n")
    
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
                print(f"[PostgreSQL] 지정된 테이블을 찾을 수 없습니다: {postgres_tables}")
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
            f"Generate a PostgreSQL query to search for: {query}\n\n"
            f"{schema_info}\n"
            "Rules:\n"
            "1. Use appropriate WHERE clause to filter based on the query\n"
            "2. You can JOIN multiple tables if needed\n"
            "3. Return relevant columns (use SELECT * only if all columns are needed)\n"
            f"4. Add LIMIT {top_k}\n"
            "5. Return ONLY the SQL query (no markdown, no explanation, no backticks)\n"
            "6. Use proper PostgreSQL syntax\n\n"
            "SQL:"
        )

        resp = client_llm.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {
                    "role": "system",
                    "content": "You are a PostgreSQL expert. Generate valid SQL queries only. Return only SQL, no explanations.",
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
        cur.execute(sql)
        rows = cur.fetchall()
        
        # 컬럼명 가져오기
        column_names = [desc[0] for desc in cur.description] if cur.description else []

        # 5. 결과 포맷팅
        results = []
        metas = []
        for row in rows:
            # 컬럼명과 값을 매핑하여 문자열로 변환
            if column_names:
                row_dict = dict(zip(column_names, row))
                row_str = ", ".join([f"{k}: {v}" if v is not None else f"{k}: N/A" for k, v in row_dict.items()])
            else:
                row_str = ", ".join([str(v) if v is not None else "N/A" for v in row])
            results.append(row_str)
            metas.append({"source": "postgresql", "tables": available_tables})

        elapsed = time.time() - start_time
        print(f"[PostgreSQL 검색 완료] {len(results)}개 결과 ({elapsed:.2f}초)")

        return results, metas

    except Exception as e:
        print(f"[PostgreSQL 오류] {type(e).__name__}: {e}")
        import traceback
        traceback.print_exc()
        return [], []
