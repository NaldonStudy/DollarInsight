#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ChromaDB 상태 확인 스크립트
"""

import os
from dotenv import load_dotenv
from pathlib import Path
from chromadb import HttpClient
from chromadb.config import Settings

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

# ChromaDB 설정
# ⚠️ 민감 정보: .env 파일에서 반드시 설정하세요
# <<여기에 ChromaDB 서버 주소를 넣어주세요>>
# 예시: CHROMADB_URL=xxx.xxx.xxx.xxx (실제 IP 주소) 또는 CHROMADB_URL=localhost (로컬 개발) 또는 CHROMADB_URL=dollar-insight-chromadb (Docker)
# .env 파일에 다음과 같이 추가: CHROMADB_URL=xxx.xxx.xxx.xxx
# Docker 네트워크 내에서는 컨테이너 이름(dollar-insight-chromadb) 사용 가능
CHROMADB_URL = os.getenv("CHROMADB_URL")
if not CHROMADB_URL:
    raise ValueError("CHROMADB_URL가 .env 파일에 설정되지 않았습니다.")
CHROMADB_PORT = int(os.getenv("CHROMADB_PORT", "9000"))
CHROMADB_COLLECTION_NAME = os.getenv("CHROMADB_COLLECTION_NAME", "news_bge_m3")

def check_chromadb():
    """ChromaDB 연결 및 상태 확인"""
    print("=" * 70)
    print("🔍 ChromaDB 상태 확인")
    print("=" * 70)
    
    try:
        # ChromaDB 클라이언트 생성
        print(f"\n1️⃣ ChromaDB 연결 시도: {CHROMADB_URL}:{CHROMADB_PORT}")
        client = HttpClient(
            host=CHROMADB_URL,
            port=CHROMADB_PORT,
            settings=Settings(anonymized_telemetry=False),
        )
        print("✅ ChromaDB 연결 성공!")
        
        # 컬렉션 목록 가져오기
        print(f"\n2️⃣ 컬렉션 목록 조회 중...")
        collections = client.list_collections()
        print(f"   총 {len(collections)}개 컬렉션 발견:")
        
        for i, collection in enumerate(collections, 1):
            print(f"\n   [{i}] {collection.name}")
            print(f"       ID: {collection.id}")
            print(f"       Metadata: {collection.metadata}")
            
            # 각 컬렉션의 문서 수 확인
            try:
                count_result = collection.count()
                print(f"       문서 수: {count_result:,}개")
            except Exception as e:
                print(f"       문서 수 확인 실패: {str(e)}")
        
        # 특정 컬렉션 상세 정보
        if CHROMADB_COLLECTION_NAME:
            print(f"\n3️⃣ '{CHROMADB_COLLECTION_NAME}' 컬렉션 상세 정보:")
            try:
                collection = client.get_collection(CHROMADB_COLLECTION_NAME)
                count = collection.count()
                print(f"   ✅ 컬렉션 존재")
                print(f"   문서 수: {count:,}개")
                
                # 샘플 데이터 확인 (최대 5개)
                if count > 0:
                    print(f"\n   샘플 데이터 (최대 5개):")
                    sample = collection.peek(limit=5)
                    for i, (doc_id, doc_text, metadata) in enumerate(zip(
                        sample.get("ids", [])[:5],
                        sample.get("documents", [])[:5],
                        sample.get("metadatas", [])[:5]
                    ), 1):
                        print(f"\n   [{i}] ID: {doc_id}")
                        print(f"       텍스트: {doc_text[:100]}..." if len(doc_text) > 100 else f"       텍스트: {doc_text}")
                        print(f"       메타데이터: {metadata}")
            except Exception as e:
                print(f"   ❌ 컬렉션 조회 실패: {str(e)}")
        
        print("\n" + "=" * 70)
        print("✅ ChromaDB 상태 확인 완료")
        print("=" * 70)
        
    except Exception as e:
        print(f"\n❌ ChromaDB 연결 실패: {str(e)}")
        import traceback
        traceback.print_exc()
        return False
    
    return True

if __name__ == "__main__":
    check_chromadb()

