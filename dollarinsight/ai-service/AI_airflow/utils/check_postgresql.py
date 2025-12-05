#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
PostgreSQL 상태 확인 스크립트
"""

import os
from dotenv import load_dotenv
from pathlib import Path
import psycopg2
from psycopg2.extras import RealDictCursor

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

# PostgreSQL 설정
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
POSTGRESQL_PORT = int(os.getenv("POSTGRESQL_PORT", "5432"))


def check_postgresql():
    """PostgreSQL 연결 및 상태 확인"""
    print("=" * 70)
    print("🔍 PostgreSQL 상태 확인")
    print("=" * 70)
    
    try:
        # PostgreSQL 연결
        print(f"\n1️⃣ PostgreSQL 연결 시도: {POSTGRESQL_URL}:{POSTGRESQL_PORT}")
        conn = psycopg2.connect(
            host=POSTGRESQL_URL,
            port=POSTGRESQL_PORT,
            database=POSTGRESQL_NAME,
            user=POSTGRESQL_USER,
            password=POSTGRESQL_PASSWORD
        )
        print("✅ PostgreSQL 연결 성공!")
        
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        # PostgreSQL 버전 확인
        print(f"\n2️⃣ PostgreSQL 버전:")
        cursor.execute("SELECT version();")
        version = cursor.fetchone()["version"]
        print(f"   {version}")
        
        # 데이터베이스 목록 확인
        print(f"\n3️⃣ 데이터베이스 목록:")
        cursor.execute("""
            SELECT datname, pg_size_pretty(pg_database_size(datname)) as size
            FROM pg_database
            WHERE datistemplate = false
            ORDER BY datname;
        """)
        databases = cursor.fetchall()
        print(f"   총 {len(databases)}개 데이터베이스:")
        for db in databases:
            print(f"   - {db['datname']}: {db['size']}")
        
        # 현재 데이터베이스의 테이블 목록
        print(f"\n4️⃣ '{POSTGRESQL_NAME}' 데이터베이스 테이블 목록:")
        cursor.execute("""
            SELECT 
                table_name,
                pg_size_pretty(pg_total_relation_size(quote_ident(table_name))) as size
            FROM information_schema.tables
            WHERE table_schema = 'public'
            ORDER BY table_name;
        """)
        tables = cursor.fetchall()
        print(f"   총 {len(tables)}개 테이블:")
        for table in tables:
            print(f"   - {table['table_name']}: {table['size']}")
        
        # 각 테이블의 행 수 확인
        if tables:
            print(f"\n5️⃣ 테이블별 행 수:")
            for table in tables:
                table_name = table['table_name']
                try:
                    cursor.execute(f"SELECT COUNT(*) as count FROM {table_name};")
                    count = cursor.fetchone()["count"]
                    print(f"   - {table_name}: {count:,}개 행")
                except Exception as e:
                    print(f"   - {table_name}: (조회 실패: {str(e)[:50]})")
        
        # stocks_master 테이블 상세 정보 (주식 마스터 데이터)
        print(f"\n6️⃣ 'stocks_master' 테이블 상세 정보:")
        try:
            cursor.execute("""
                SELECT COUNT(*) as total_count
                FROM stocks_master;
            """)
            total_count = cursor.fetchone()["total_count"]
            print(f"   ✅ 테이블 존재")
            print(f"   총 주식 수: {total_count:,}개")
            
            if total_count > 0:
                # 컬럼 정보
                cursor.execute("""
                    SELECT column_name, data_type, character_maximum_length
                    FROM information_schema.columns
                    WHERE table_name = 'stocks_master'
                    ORDER BY ordinal_position;
                """)
                columns = cursor.fetchall()
                print(f"\n   컬럼 정보 ({len(columns)}개):")
                for col in columns[:15]:  # 최대 15개만 표시
                    col_info = f"   - {col['column_name']}: {col['data_type']}"
                    if col['character_maximum_length']:
                        col_info += f"({col['character_maximum_length']})"
                    print(col_info)
                if len(columns) > 15:
                    print(f"   ... 외 {len(columns) - 15}개 컬럼")
                
                # 샘플 데이터 (최대 5개)
                print(f"\n   샘플 데이터 (최대 5개):")
                cursor.execute("""
                    SELECT *
                    FROM stocks_master
                    LIMIT 5;
                """)
                samples = cursor.fetchall()
                for i, sample in enumerate(samples, 1):
                    # 주요 필드 표시
                    name = sample.get('name') or sample.get('company_name') or sample.get('stock_name') or 'N/A'
                    ticker = sample.get('ticker') or sample.get('symbol') or 'N/A'
                    print(f"\n   [{i}] 회사명: {name}")
                    print(f"       티커: {ticker}")
                    # 다른 주요 필드들
                    key_fields = [k for k in sample.keys() if k not in ['name', 'company_name', 'stock_name', 'ticker', 'symbol']]
                    if key_fields:
                        print(f"       기타 필드: {', '.join(key_fields[:8])}")
        except Exception as e:
            print(f"   ❌ 테이블 조회 실패: {str(e)}")
        
        # 주요 테이블 요약
        print(f"\n7️⃣ 주요 테이블 요약:")
        major_tables = [
            ('stocks_master', '주식 마스터'),
            ('stock_price_daily', '일일 주가'),
            ('stock_metrics_daily', '일일 주식 지표'),
            ('stock_scores_daily', '일일 주식 점수'),
            ('stocks_financial_statements', '재무제표'),
            ('etf_master', 'ETF 마스터'),
            ('etf_price_daily', 'ETF 일일 가격'),
            ('macro_economic_indicators', '거시경제 지표'),
        ]
        for table_name, description in major_tables:
            try:
                cursor.execute(f"SELECT COUNT(*) as count FROM {table_name};")
                count = cursor.fetchone()["count"]
                print(f"   - {description} ({table_name}): {count:,}개 행")
            except Exception:
                pass
        
        # 연결 종료
        cursor.close()
        conn.close()
        
        print("\n" + "=" * 70)
        print("✅ PostgreSQL 상태 확인 완료")
        print("=" * 70)
        
        return True
        
    except Exception as e:
        print(f"\n❌ PostgreSQL 연결 실패: {str(e)}")
        import traceback
        traceback.print_exc()
        return False


if __name__ == "__main__":
    check_postgresql()

