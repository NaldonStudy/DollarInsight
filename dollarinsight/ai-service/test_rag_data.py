#!/usr/bin/env python3
"""
RAG 검색 결과 확인 테스트 스크립트
- 뉴스 분석과 기업 분석에서 사용된 RAG 데이터 확인
"""

import requests
import json

FASTAPI_URL = "http://localhost:8000"

def test_rag_data():
    """RAG 검색 결과 확인 테스트"""
    print("=" * 80)
    print("🔍 RAG 검색 결과 확인 테스트")
    print("=" * 80)
    
    # 1. 뉴스 분석 테스트
    print("\n📰 뉴스 분석 RAG 검색 확인")
    print("-" * 80)
    
    news_data = {
        "title": "애플, AI 칩 개발 가속화... iPhone 16에 탑재 예정",
        "content": """애플이 자체 AI 칩 개발을 가속화하고 있다고 발표했습니다. 
        이번 AI 칩은 iPhone 16에 탑재될 예정이며, 기존 프로세서 대비 AI 성능이 2배 향상될 것으로 예상됩니다.
        애플은 이번 발표로 주가가 3% 상승했으며, 시장 전문가들은 이번 움직임이 애플의 AI 경쟁력 강화에 중요한 전환점이 될 것이라고 평가했습니다."""
    }
    
    print(f"제목: {news_data['title']}")
    print("\n⚠️ Docker 로그에서 RAG 검색 결과를 확인하세요:")
    print("   docker logs dollar-insight-ai-service --tail 100 | grep -A 20 'RAG 검색'")
    
    try:
        response = requests.post(f"{FASTAPI_URL}/analyze-news", json=news_data, timeout=60)
        response.raise_for_status()
        result = response.json()
        print("\n✅ 뉴스 분석 완료")
        print(f"관련 기업: {result.get('companies', [])}")
    except Exception as e:
        print(f"\n❌ 오류: {e}")
    
    # 2. 기업 분석 테스트
    print("\n\n📊 기업 분석 RAG 검색 확인")
    print("-" * 80)
    
    company_data = {
        "company_name": "애플",
        "company_info": "애플은 세계 최대 기술 기업 중 하나로, iPhone, iPad, Mac 등을 생산합니다."
    }
    
    print(f"기업명: {company_data['company_name']}")
    print("\n⚠️ Docker 로그에서 RAG 검색 결과를 확인하세요:")
    print("   docker logs dollar-insight-ai-service --tail 100 | grep -A 20 'RAG 검색'")
    
    try:
        response = requests.post(f"{FASTAPI_URL}/analyze-company", json=company_data, timeout=60)
        response.raise_for_status()
        result = response.json()
        print("\n✅ 기업 분석 완료")
    except Exception as e:
        print(f"\n❌ 오류: {e}")
    
    print("\n" + "=" * 80)
    print("📌 로그 확인 명령어:")
    print("=" * 80)
    print("docker logs dollar-insight-ai-service --tail 200 | grep -A 30 'RAG 검색'")
    print("=" * 80 + "\n")

if __name__ == "__main__":
    test_rag_data()

