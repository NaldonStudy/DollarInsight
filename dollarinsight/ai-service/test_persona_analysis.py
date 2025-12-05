#!/usr/bin/env python3
"""
페르소나 분석 테스트 스크립트
- 기업 분석 테스트
- 뉴스 분석 테스트
"""

import requests
import json
from datetime import datetime

FASTAPI_URL = "http://localhost:8000"

def test_company_analysis():
    """기업 분석 테스트"""
    print("=" * 80)
    print("📊 기업 분석 테스트")
    print("=" * 80)
    
    url = f"{FASTAPI_URL}/analyze-company"
    data = {
        "company_name": "애플",
        "company_info": "애플은 세계 최대 기술 기업 중 하나로, iPhone, iPad, Mac 등을 생산합니다."
    }
    
    print(f"\n요청: {data['company_name']}")
    print(f"URL: {url}\n")
    
    try:
        response = requests.post(url, json=data, timeout=60)
        response.raise_for_status()
        result = response.json()
        
        print("\n✅ 응답 받음:")
        print(f"기업명: {result.get('company_name')}")
        print(f"분석 시간: {result.get('analyzed_at')}")
        print("\n페르소나별 분석:")
        print("-" * 80)
        for persona in ["heuyeol", "deoksu", "jiyul", "teo", "minji"]:
            analysis = result.get(persona, "분석 없음")
            print(f"\n[{persona}]")
            print(f"  {analysis}")
        
        return True
    except Exception as e:
        print(f"\n❌ 오류 발생: {e}")
        if hasattr(e, 'response'):
            print(f"응답 내용: {e.response.text}")
        return False

def test_news_analysis():
    """뉴스 분석 테스트"""
    print("\n" + "=" * 80)
    print("📰 뉴스 분석 테스트")
    print("=" * 80)
    
    url = f"{FASTAPI_URL}/analyze-news"
    data = {
        "title": "애플, AI 칩 개발 가속화... iPhone 16에 탑재 예정",
        "content": """애플이 자체 AI 칩 개발을 가속화하고 있다고 발표했습니다. 
        이번 AI 칩은 iPhone 16에 탑재될 예정이며, 기존 프로세서 대비 AI 성능이 2배 향상될 것으로 예상됩니다.
        애플은 이번 발표로 주가가 3% 상승했으며, 시장 전문가들은 이번 움직임이 애플의 AI 경쟁력 강화에 중요한 전환점이 될 것이라고 평가했습니다."""
    }
    
    print(f"\n제목: {data['title']}")
    print(f"URL: {url}\n")
    
    try:
        response = requests.post(url, json=data, timeout=60)
        response.raise_for_status()
        result = response.json()
        
        print("\n✅ 응답 받음:")
        print(f"\n요약:")
        print(f"  {result.get('summary', '요약 없음')}")
        
        print("\n페르소나별 분석:")
        print("-" * 80)
        persona_analyses = result.get('persona_analyses', {})
        persona_mapping = {
            "heuyeol": "희열",
            "deoksu": "덕수",
            "jiyul": "지율",
            "teo": "테오",
            "minji": "민지"
        }
        for english_name, korean_name in persona_mapping.items():
            analysis = persona_analyses.get(english_name, "분석 없음")
            print(f"\n[{korean_name}]")
            print(f"  {analysis}")
        
        print(f"\n관련 기업: {result.get('companies', [])}")
        
        return True
    except Exception as e:
        print(f"\n❌ 오류 발생: {e}")
        if hasattr(e, 'response'):
            print(f"응답 내용: {e.response.text}")
        return False

if __name__ == "__main__":
    print("\n🚀 페르소나 분석 테스트 시작\n")
    
    # 기업 분석 테스트
    company_success = test_company_analysis()
    
    # 뉴스 분석 테스트
    news_success = test_news_analysis()
    
    # 결과 요약
    print("\n" + "=" * 80)
    print("📊 테스트 결과 요약")
    print("=" * 80)
    print(f"기업 분석: {'✅ 성공' if company_success else '❌ 실패'}")
    print(f"뉴스 분석: {'✅ 성공' if news_success else '❌ 실패'}")
    print("=" * 80 + "\n")

