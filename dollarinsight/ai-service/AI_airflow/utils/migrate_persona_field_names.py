#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
MongoDB 페르소나 필드명 마이그레이션 스크립트
persona_hyeolyeol -> persona_heuyeol 등으로 변경
"""

import os
from pathlib import Path
from pymongo import MongoClient
from pymongo.errors import ConnectionFailure, OperationFailure
from dotenv import load_dotenv

# .env 파일 로드
env_path = Path("/opt/airflow/.env")
if env_path.exists():
    load_dotenv(dotenv_path=env_path, override=True)
else:
    env_path_abs = Path("/opt/S13P31B205/ai-service/.env")
    if env_path_abs.exists():
        load_dotenv(dotenv_path=env_path_abs, override=True)
    else:
        load_dotenv(override=True)

# MongoDB 연결 설정
MONGODB_HOST = os.getenv("MONGODB_HOST", "dollar-insight-mongodb")
MONGODB_PORT = int(os.getenv("MONGODB_PORT", "27017"))
MONGODB_NAME = os.getenv("MONGODB_NAME", "dollar_insight")
_mongodb_user = os.getenv("MONGODB_USER") or os.getenv("MONGODB_USERNAME") or os.getenv("MONGO_USER")
_mongodb_pass = os.getenv("MONGODB_PASSWORD") or os.getenv("MONGO_PASSWORD")
MONGODB_USERNAME = _mongodb_user.strip() if _mongodb_user and _mongodb_user.strip() else None
MONGODB_PASSWORD = _mongodb_pass.strip() if _mongodb_pass and _mongodb_pass.strip() else None
MONGODB_AUTH_SOURCE = os.getenv("MONGODB_AUTH_SOURCE", "admin")

# 필드명 매핑 (구 필드명 -> 신 필드명)
FIELD_MAPPING = {
    "persona_hyeolyeol": "persona_heuyeol",
    "persona_deoksu": "persona_deoksu",  # 변경 없음
    "persona_jiyul": "persona_jiyul",  # 변경 없음
    "persona_teo": "persona_teo",  # 변경 없음
    "persona_minji": "persona_minji",  # 변경 없음
}


def migrate_collection(collection, collection_name: str):
    """컬렉션의 페르소나 필드명 마이그레이션"""
    print(f"\n📊 {collection_name} 컬렉션 마이그레이션 시작...")
    
    # 변경이 필요한 문서 찾기
    query = {"persona_hyeolyeol": {"$exists": True}}
    count = collection.count_documents(query)
    
    if count == 0:
        print(f"   ✅ 마이그레이션할 문서 없음 (이미 완료되었거나 필드가 없음)")
        return 0
    
    print(f"   발견된 문서: {count}개")
    
    # 배치 업데이트
    updated_count = 0
    for doc in collection.find(query):
        update_fields = {}
        
        # persona_hyeolyeol -> persona_heuyeol 변경
        if "persona_hyeolyeol" in doc:
            update_fields["persona_heuyeol"] = doc["persona_hyeolyeol"]
            update_fields["$unset"] = {"persona_hyeolyeol": ""}
        
        if update_fields:
            # $unset이 있으면 별도 처리
            unset_fields = update_fields.pop("$unset", {})
            
            result = collection.update_one(
                {"_id": doc["_id"]},
                {
                    "$set": update_fields,
                    "$unset": unset_fields
                }
            )
            
            if result.modified_count > 0:
                updated_count += 1
    
    print(f"   ✅ 업데이트 완료: {updated_count}개")
    return updated_count


def main():
    """메인 마이그레이션 함수"""
    print("=" * 80)
    print("MongoDB 페르소나 필드명 마이그레이션")
    print("=" * 80)
    print(f"변경 사항:")
    print(f"  - persona_hyeolyeol -> persona_heuyeol")
    print(f"  - 나머지 필드명은 변경 없음")
    print("=" * 80)
    
    # MongoDB 연결
    print("\n🔌 MongoDB 연결 중...")
    if MONGODB_USERNAME and MONGODB_PASSWORD:
        mongo_uri = f"mongodb://{MONGODB_USERNAME}:{MONGODB_PASSWORD}@{MONGODB_HOST}:{MONGODB_PORT}/{MONGODB_NAME}?authSource={MONGODB_AUTH_SOURCE}"
    else:
        mongo_uri = f"mongodb://{MONGODB_HOST}:{MONGODB_PORT}/{MONGODB_NAME}"
    
    try:
        client = MongoClient(mongo_uri, serverSelectionTimeoutMS=5000)
        client.admin.command('ping')
        print(f"   ✅ 연결 성공: {MONGODB_HOST}:{MONGODB_PORT}")
        
        db = client[MONGODB_NAME]
        
        # 1. news_persona_analysis 컬렉션 마이그레이션
        persona_collection = db["news_persona_analysis"]
        news_updated = migrate_collection(persona_collection, "news_persona_analysis")
        
        # 2. company_analysis 컬렉션 마이그레이션
        company_collection = db["company_analysis"]
        company_updated = migrate_collection(company_collection, "company_analysis")
        
        print("\n" + "=" * 80)
        print("✅ 마이그레이션 완료!")
        print(f"   - 뉴스 페르소나 분석: {news_updated}개 업데이트")
        print(f"   - 기업 분석: {company_updated}개 업데이트")
        print("=" * 80)
        
        client.close()
        
    except ConnectionFailure:
        print(f"❌ MongoDB 연결 실패: {MONGODB_HOST}:{MONGODB_PORT}")
    except OperationFailure as e:
        print(f"❌ MongoDB 인증 실패: {e}")
    except Exception as e:
        print(f"❌ 오류 발생: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()

