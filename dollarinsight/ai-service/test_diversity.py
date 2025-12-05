#!/usr/bin/env python3
"""
페르소나 분석 다양성 테스트 스크립트
- 같은 뉴스/기업을 여러 번 분석하여 다양성 확인
"""

import requests
import json
import time

FASTAPI_URL = "http://localhost:8000"

def test_news_diversity():
    """뉴스 분석 다양성 테스트"""
    print("=" * 80)
    print("📰 뉴스 분석 다양성 테스트 (같은 뉴스 3번 분석)")
    print("=" * 80)
    
    url = f"{FASTAPI_URL}/analyze-news"
    data = {
        "title": "테슬라, 전기차 판매 급증... 주가 5% 상승",
        "content": """테슬라가 전기차 판매량이 전년 대비 30% 증가했다고 발표했습니다. 
        특히 중국 시장에서의 판매가 크게 늘어났으며, 이에 따라 주가가 5% 상승했습니다.
        전문가들은 전기차 시장의 성장세가 지속될 것으로 전망하고 있습니다."""
    }
    
    results = []
    for i in range(3):
        print(f"\n{'='*80}")
        print(f"테스트 {i+1}/3")
        print(f"{'='*80}")
        
        try:
            response = requests.post(url, json=data, timeout=60)
            response.raise_for_status()
            result = response.json()
            
            persona_analyses = result.get('persona_analyses', {})
            persona_mapping = {
                "heuyeol": "희열",
                "deoksu": "덕수",
                "jiyul": "지율",
                "teo": "테오",
                "minji": "민지"
            }
            
            print("\n페르소나별 분석:")
            for english_name, korean_name in persona_mapping.items():
                analysis = persona_analyses.get(english_name, "분석 없음")
                print(f"\n[{korean_name}]")
                print(f"  {analysis}")
            
            results.append(persona_analyses)
            time.sleep(2)  # API 호출 간격
            
        except Exception as e:
            print(f"\n❌ 오류 발생: {e}")
            return False
    
    # 다양성 분석
    print("\n" + "=" * 80)
    print("📊 다양성 분석 결과")
    print("=" * 80)
    
    for english_name, korean_name in persona_mapping.items():
        analyses = [r.get(english_name, "") for r in results]
        unique_analyses = set(analyses)
        print(f"\n[{korean_name}]")
        print(f"  총 분석 수: {len(analyses)}")
        print(f"  고유 분석 수: {len(unique_analyses)}")
        if len(unique_analyses) < len(analyses):
            print(f"  ⚠️ 중복 발견: {len(analyses) - len(unique_analyses)}개")
        else:
            print(f"  ✅ 모두 다른 분석!")
    
    return True

if __name__ == "__main__":
    print("\n🚀 페르소나 분석 다양성 테스트 시작\n")
    test_news_diversity()
    print("\n" + "=" * 80 + "\n")

