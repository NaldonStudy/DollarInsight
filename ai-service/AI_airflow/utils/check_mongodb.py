#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
MongoDB 상태 확인 스크립트
"""

import os
from dotenv import load_dotenv
from pymongo import MongoClient
from urllib.parse import quote_plus
from datetime import datetime

load_dotenv()

# MongoDB 설정
MONGODB_HOST = os.getenv("MONGODB_HOST", "mongodb")
MONGODB_PORT = int(os.getenv("MONGODB_PORT", "27017"))
MONGODB_DB = os.getenv("MONGODB_DB", "dollar_insight")
MONGODB_NEWS_COLLECTION = os.getenv("MONGODB_NEWS_COLLECTION", "investing_news")
# MongoDB 인증 정보 (vectorize_news.py와 동일한 방식)
_mongodb_user = os.getenv("MONGODB_USER", os.getenv("MONGODB_USERNAME", None))
_mongodb_pass = os.getenv("MONGODB_PASSWORD", None)
MONGODB_USERNAME = _mongodb_user.strip() if _mongodb_user else None
MONGODB_PASSWORD = _mongodb_pass.strip() if _mongodb_pass else None
MONGODB_AUTH_SOURCE = os.getenv("MONGODB_AUTH_SOURCE", "admin").strip()


def get_mongodb_client():
    """MongoDB 클라이언트 생성 (vectorize_news.py와 동일한 방식)"""
    if MONGODB_USERNAME and MONGODB_PASSWORD:
        username = quote_plus(str(MONGODB_USERNAME))
        password = quote_plus(str(MONGODB_PASSWORD))
        connection_string = f"mongodb://{username}:{password}@{MONGODB_HOST}:{MONGODB_PORT}/{MONGODB_DB}?authSource={MONGODB_AUTH_SOURCE}"
        return MongoClient(connection_string)
    else:
        return MongoClient(MONGODB_HOST, MONGODB_PORT)


def check_mongodb():
    """MongoDB 연결 및 상태 확인"""
    print("=" * 70)
    print("🔍 MongoDB 상태 확인")
    print("=" * 70)
    
    try:
        # MongoDB 클라이언트 생성
        print(f"\n1️⃣ MongoDB 연결 시도: {MONGODB_HOST}:{MONGODB_PORT}")
        client = get_mongodb_client()
        
        # 연결 테스트
        client.admin.command('ping')
        print("✅ MongoDB 연결 성공!")
        
        # 데이터베이스 목록 확인 (인증이 필요한 경우 스킵)
        print(f"\n2️⃣ 데이터베이스 목록:")
        try:
            db_list = client.list_database_names()
            print(f"   총 {len(db_list)}개 데이터베이스:")
            for db_name in db_list:
                try:
                    db = client[db_name]
                    collections = db.list_collection_names()
                    print(f"   - {db_name}: {len(collections)}개 컬렉션")
                except Exception:
                    print(f"   - {db_name}: (접근 권한 없음)")
        except Exception as e:
            print(f"   ⚠️ 데이터베이스 목록 조회 실패 (인증 필요): {str(e)}")
            print(f"   → 특정 데이터베이스로 직접 접근 시도")
        
        # 특정 데이터베이스 확인
        if MONGODB_DB:
            print(f"\n3️⃣ '{MONGODB_DB}' 데이터베이스 상세 정보:")
            db = client[MONGODB_DB]
            try:
                collections = db.list_collection_names()
                print(f"   ✅ 데이터베이스 존재")
                print(f"   컬렉션 수: {len(collections)}개")
                
                if collections:
                    print(f"\n   컬렉션 목록:")
                    for i, coll_name in enumerate(collections, 1):
                        try:
                            coll = db[coll_name]
                            count = coll.count_documents({})
                            print(f"   [{i}] {coll_name}: {count:,}개 문서")
                        except Exception as e:
                            print(f"   [{i}] {coll_name}: (접근 실패: {str(e)[:50]})")
            except Exception as e:
                print(f"   ⚠️ 컬렉션 목록 조회 실패: {str(e)}")
                print(f"   → 특정 컬렉션으로 직접 접근 시도")
        
        # investing_news 컬렉션 상세 정보
        if MONGODB_NEWS_COLLECTION:
            print(f"\n4️⃣ '{MONGODB_NEWS_COLLECTION}' 컬렉션 상세 정보:")
            db = client[MONGODB_DB]
            collection = db[MONGODB_NEWS_COLLECTION]
            
            # 전체 문서 수
            total_count = collection.count_documents({})
            print(f"   ✅ 컬렉션 존재")
            print(f"   총 문서 수: {total_count:,}개")
            
            if total_count > 0:
                # 최신 문서 날짜 범위 확인
                latest_doc = collection.find_one(sort=[("date", -1)])
                oldest_doc = collection.find_one(sort=[("date", 1)])
                
                if latest_doc and oldest_doc:
                    print(f"\n   날짜 범위:")
                    print(f"   - 최신 기사: {latest_doc.get('date', 'N/A')}")
                    print(f"   - 가장 오래된 기사: {oldest_doc.get('date', 'N/A')}")
                
                # 샘플 데이터 확인 (최대 5개)
                print(f"\n   샘플 데이터 (최대 5개):")
                sample_docs = collection.find().limit(5).sort("date", -1)
                for i, doc in enumerate(sample_docs, 1):
                    doc_id = str(doc.get("_id", ""))
                    title = doc.get("title", "")[:80]
                    date = doc.get("date", "N/A")
                    url = doc.get("url", "")[:60]
                    content_length = len(doc.get("content", ""))
                    
                    print(f"\n   [{i}] ID: {doc_id}")
                    print(f"       제목: {title}...")
                    print(f"       날짜: {date}")
                    print(f"       URL: {url}...")
                    print(f"       본문 길이: {content_length:,}자")
                
                # 필드 통계
                print(f"\n   필드 통계:")
                sample = collection.find_one()
                if sample:
                    fields = list(sample.keys())
                    print(f"   - 필드 수: {len(fields)}개")
                    print(f"   - 필드 목록: {', '.join(fields[:10])}{'...' if len(fields) > 10 else ''}")
        
        print("\n" + "=" * 70)
        print("✅ MongoDB 상태 확인 완료")
        print("=" * 70)
        
        client.close()
        return True
        
    except Exception as e:
        print(f"\n❌ MongoDB 연결 실패: {str(e)}")
        import traceback
        traceback.print_exc()
        return False


if __name__ == "__main__":
    check_mongodb()

