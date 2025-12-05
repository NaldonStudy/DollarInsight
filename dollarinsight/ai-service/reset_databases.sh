#!/bin/bash
# MongoDB, ChromaDB, reddit_stocks.json 초기화 스크립트

set -e

echo "=========================================="
echo "🔄 MongoDB, ChromaDB, reddit_stocks.json 초기화"
echo "=========================================="

# MongoDB 설정
MONGODB_HOST="${MONGODB_HOST:-mongodb}"
MONGODB_PORT="${MONGODB_PORT:-27017}"
MONGODB_DB="${MONGODB_DB:-dollar_insight}"
MONGODB_USER="${MONGODB_USER:-admin}"
# ⚠️ 민감 정보: .env 파일에서 설정하세요
MONGODB_PASSWORD="${MONGODB_PASSWORD:-}"
MONGODB_AUTH_SOURCE="${MONGODB_AUTH_SOURCE:-admin}"

# MONGODB_PASSWORD가 설정되지 않았으면 에러
if [ -z "$MONGODB_PASSWORD" ]; then
    echo "❌ 오류: MONGODB_PASSWORD가 설정되지 않았습니다."
    echo "   .env 파일에 MONGODB_PASSWORD를 설정하세요."
    exit 1
fi

# ChromaDB 설정
CHROMADB_URL="${CHROMADB_URL:-3.34.50.3}"
CHROMADB_PORT="${CHROMADB_PORT:-9000}"
CHROMADB_COLLECTION="${CHROMADB_COLLECTION_NAME:-news_bge_m3}"

echo ""
echo "1️⃣ MongoDB 초기화 중..."
echo "   Host: ${MONGODB_HOST}:${MONGODB_PORT}"
echo "   Database: ${MONGODB_DB}"

# MongoDB 컬렉션 삭제
docker exec dollar-insight-mongodb mongosh -u "${MONGODB_USER}" -p "${MONGODB_PASSWORD}" --authenticationDatabase "${MONGODB_AUTH_SOURCE}" --quiet --eval "
db = db.getSiblingDB('${MONGODB_DB}');
print('삭제 전:');
print('investing_news:', db.investing_news.countDocuments());
print('news_persona_analysis:', db.news_persona_analysis.countDocuments());
print('company_analysis:', db.company_analysis.countDocuments());
db.investing_news.drop();
db.news_persona_analysis.drop();
db.company_analysis.drop();
print('✅ MongoDB 컬렉션 삭제 완료');
"

echo ""
echo "2️⃣ ChromaDB 초기화 중..."
echo "   URL: ${CHROMADB_URL}:${CHROMADB_PORT}"
echo "   Collection: ${CHROMADB_COLLECTION}"

# Airflow 컨테이너에서 실행 (chromadb가 설치되어 있음)
docker exec ai_airflow-airflow-webserver-1 python3 << PYEOF
import os
from chromadb import HttpClient
from chromadb.config import Settings

CHROMADB_URL = "${CHROMADB_URL}"
CHROMADB_PORT = ${CHROMADB_PORT}
CHROMADB_COLLECTION = "${CHROMADB_COLLECTION}"

try:
    client = HttpClient(
        host=CHROMADB_URL,
        port=CHROMADB_PORT,
        settings=Settings(anonymized_telemetry=False),
    )
    
    # 컬렉션 삭제 시도
    try:
        collection = client.get_collection(CHROMADB_COLLECTION)
        client.delete_collection(CHROMADB_COLLECTION)
        print("✅ ChromaDB 컬렉션 삭제 완료")
    except Exception as e:
        error_msg = str(e).lower()
        if "does not exist" in error_msg or "not found" in error_msg:
            print("ℹ️  ChromaDB 컬렉션이 이미 존재하지 않음 (초기화 완료)")
        else:
            print(f"⚠️  ChromaDB 컬렉션 삭제 중 오류 (무시): {e}")
            print("ℹ️  컬렉션이 존재하지 않을 수 있습니다 (초기화 완료로 간주)")
    
except Exception as e:
    print(f"❌ ChromaDB 초기화 실패: {e}")
    import traceback
    traceback.print_exc()
    exit(1)
PYEOF

echo ""
echo "3️⃣ reddit_stocks.json 초기화 중..."

# Airflow 컨테이너에서 파일 초기화 (권한 문제 해결)
docker exec ai_airflow-airflow-webserver-1 bash -c "echo '[]' > /opt/airflow/data/reddit_stocks.json && echo '✅ reddit_stocks.json 초기화 완료'"

echo ""
echo "=========================================="
echo "✅ 모든 초기화 완료!"
echo "=========================================="
echo ""
echo "📌 초기화된 항목:"
echo "   - MongoDB 컬렉션: investing_news, news_persona_analysis, company_analysis"
echo "   - ChromaDB 컬렉션: ${CHROMADB_COLLECTION}"
echo "   - reddit_stocks.json: 빈 배열로 초기화"
echo ""
