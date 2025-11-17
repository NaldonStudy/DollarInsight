# -*- coding: utf-8 -*-

"""
봇 감지로 크롤링 실패한 뉴스를 URL로 다시 크롤링하는 스크립트 (로컬 실행용)
"""

import json
import sys
import time
from pathlib import Path
from typing import List, Dict
from datetime import datetime
from playwright.sync_api import sync_playwright


def is_bot_detected(article: Dict) -> bool:
    """봇 감지로 크롤링 실패한 항목인지 확인"""
    title = article.get("title", "").strip()
    content = article.get("content", "").strip()
    
    # 봇 감지 페이지의 특징적인 텍스트 확인
    if title == "kr.investing.com":
        return True
    
    if "Verifying you are human" in content or "This may take a few seconds" in content:
        return True
    
    # 본문이 너무 짧거나 비어있으면 실패로 간주
    if len(content) < 50:
        return True
    
    return False


def load_json_file(json_path: str) -> List[Dict]:
    """JSON 파일 로드"""
    json_path = Path(json_path)
    if not json_path.exists():
        raise FileNotFoundError(f"파일을 찾을 수 없습니다: {json_path}")
    
    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    if not isinstance(data, list):
        raise ValueError(f"JSON 파일은 리스트 형태여야 합니다: {json_path}")
    
    return data


def get_date(page):
    """날짜 추출"""
    # time datetime 속성
    if page.locator("time").count() > 0:
        dt = page.locator("time").first.get_attribute("datetime")
        if dt:
            return dt.strip().split("T")[0] if "T" in dt else dt.strip()
    
    # 메타 태그
    for sel, attr in (
        ('meta[property="article:published_time"]', "content"),
        ('meta[name="date"]', "content"),
        ('meta[name="dc.date"]', "content"),
    ):
        if page.locator(sel).count() > 0:
            val = page.locator(sel).first.get_attribute(attr)
            if val:
                return val.strip().split("T")[0] if "T" in val else val.strip()
    
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def get_content(page):
    """본문 추출"""
    use_article = page.locator("#article").count() > 0
    base_selector = "#article" if use_article else "body"
    
    # 구독 유도 섹션과 광고 섹션 안의 p 태그는 제외
    paras = page.eval_on_selector_all(
        f"{base_selector} p",
        """els => {
            const excludeIds = ['contextual-subscription-hook', 'mid-article-hook'];
            const excludeDataTests = ['contextual-subscription-hook', 'ad-slot-visible'];
            const excludeClasses = ['ad_adgroup', 'ad_ad__II8vw'];
            
            return els
                .filter(el => {
                    let parent = el.parentElement;
                    let depth = 0;
                    while (parent && depth < 10) {
                        // ID 체크
                        if (parent.id && excludeIds.some(id => parent.id.includes(id))) return false;
                        // data-test 체크
                        const dataTest = parent.getAttribute('data-test');
                        if (dataTest && excludeDataTests.some(test => dataTest.includes(test))) return false;
                        // 클래스 체크
                        const className = parent.className;
                        if (className && typeof className === 'string' && excludeClasses.some(cls => className.includes(cls))) return false;
                        parent = parent.parentElement;
                        depth++;
                    }
                    return true;
                })
                .map(e => e.innerText.trim())
                .filter(Boolean);
        }""",
    )
    
    # 확실한 광고 텍스트만 필터링
    cleaned = []
    for t in paras:
        # 길이 체크
        if len(t) <= 20:
            continue
        # 확실한 광고 키워드만 체크
        if "광고" in t or "Advertisement" in t or "제3자 광고" in t:
            continue
        # "Investing.com-" 으로 시작하는 첫 문장 제외
        if t.startswith("Investing.com-") or t.startswith("Investing.com "):
            continue
        # 번역 안내 문구 제외
        if "이 기사는 인공지능의 도움을 받아 번역됐습니다" in t:
            continue
        cleaned.append(t)
    
    return "\n".join(cleaned).strip()


def parse_article(page, article_url: str, wait_for_content: bool = True):
    """개별 기사 페이지에서 제목, 본문, 날짜 추출"""
    try:
        # 타임아웃을 60초로 증가 (DOM 로드 완료 대기)
        page.goto(article_url, wait_until="domcontentloaded", timeout=60000)
        
        # 지연 로딩 유도를 위한 스크롤
        for _ in range(4):
            page.evaluate("window.scrollBy(0, 800);")
            time.sleep(0.1)
        
        # 봇 감지 페이지인지 확인하고 실제 콘텐츠가 로드될 때까지 대기
        if wait_for_content:
            max_wait_time = 30  # 최대 30초 대기
            wait_interval = 2  # 2초마다 확인
            waited = 0
            
            while waited < max_wait_time:
                time.sleep(wait_interval)
                waited += wait_interval
                
                # 페이지 내용 확인
                page_title = (page.locator("h1").first.text_content() or page.title() or "").strip()
                page_content = page.content()
                
                # 봇 감지 페이지가 아닌지 확인
                if "Verifying you are human" not in page_content and page_title != "kr.investing.com":
                    # 실제 콘텐츠가 있는지 확인
                    content = get_content(page)
                    if content and len(content) > 50:
                        break
                
                # 진행 상황 출력
                if waited % 6 == 0:  # 6초마다 출력
                    print(f"    ⏳ 봇 감지 페이지 대기 중... ({waited}초)")
        else:
            time.sleep(1)
        
        title = (page.locator("h1").first.text_content() or page.title() or "").strip()
        date = get_date(page)
        content = get_content(page)
        
        return {"title": title, "content": content, "date": date, "url": article_url}
    except Exception as e:
        print(f"  ⚠️ 페이지 로드 실패 ({type(e).__name__}): {str(e)[:100]}")
        # 에러 발생 시 기본 정보만 반환
        return {"title": "", "content": "", "date": "", "url": article_url}


def filter_failed_articles(json_path: str) -> List[Dict]:
    """JSON 파일에서 크롤링 실패한 항목들 필터링"""
    print("=" * 70)
    print("🔍 크롤링 실패한 뉴스 필터링 중...")
    print("=" * 70)
    
    articles = load_json_file(json_path)
    print(f"   총 {len(articles)}개 기사 발견")
    
    failed_articles = []
    for article in articles:
        if is_bot_detected(article):
            url = article.get("url", "")
            if url:  # URL이 있는 경우만 추가
                failed_articles.append(article)
    
    print(f"   ❌ 크롤링 실패한 기사: {len(failed_articles)}개")
    print(f"   ✅ 정상 크롤링된 기사: {len(articles) - len(failed_articles)}개")
    
    return failed_articles


def recrawl_urls(urls: List[str], json_path: str, max_retries: int = 3) -> List[Dict]:
    """URL 리스트를 다시 크롤링하고 하나씩 즉시 저장"""
    print("=" * 70)
    print(f"🔄 {len(urls)}개 URL 재크롤링 시작...")
    print("=" * 70)
    
    results = []
    success_count = 0
    import random
    
    # 랜덤한 User-Agent 목록
    user_agents = [
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:131.0) Gecko/20100101 Firefox/131.0",
    ]
    
    # Playwright 인스턴스는 한 번만 생성하고 재사용
    with sync_playwright() as p:
        # 브라우저는 한 번만 시작
        browser = p.chromium.launch(
            headless=True,
            args=[
                "--disable-blink-features=AutomationControlled",
                "--disable-gpu",
                "--no-sandbox",
                "--disable-dev-shm-usage",
                "--disable-setuid-sandbox",
                "--disable-web-security",
            ]
        )
        
        for idx, url in enumerate(urls, 1):
            print(f"\n[{idx}/{len(urls)}] 크롤링 중: {url[:60]}...")
            
            # 각 요청마다 완전히 새로운 컨텍스트 생성 (쿠키/세션 초기화)
            context = browser.new_context(
                viewport={"width": 1920, "height": 1080},
                user_agent=random.choice(user_agents),
                ignore_https_errors=True,
                storage_state=None,  # 쿠키나 로컬 스토리지 없이 시작
            )
            
            page = context.new_page()
            page.set_default_timeout(60000)
            
            # webdriver 속성 숨기기 (더 강화)
            page.add_init_script("""
                Object.defineProperty(navigator, 'webdriver', {get: () => undefined});
                Object.defineProperty(navigator, 'plugins', {get: () => [1, 2, 3, 4, 5]});
                Object.defineProperty(navigator, 'languages', {get: () => ['ko-KR', 'ko', 'en-US', 'en']});
                window.chrome = {runtime: {}};
            """)
            
            retry_count = 0
            success = False
            
            while retry_count < max_retries and not success:
                try:
                    # 첫 시도에서는 봇 감지 페이지 대기 활성화, 재시도에서는 비활성화
                    article_data = parse_article(page, url, wait_for_content=(retry_count == 0))
                    
                    # 크롤링 성공 여부 확인
                    if article_data and article_data.get("content") and len(article_data.get("content", "")) > 50:
                        # 봇 감지 페이지인지 다시 확인
                        if not is_bot_detected(article_data):
                            article_data["crawled_at"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                            results.append(article_data)
                            success_count += 1
                            print(f"  ✅ 성공: {article_data['title'][:50]}... (본문 {len(article_data['content'])}자)")
                            
                            # 즉시 JSON 파일 업데이트
                            update_json_file_single(json_path, article_data)
                            print(f"  💾 JSON 파일에 저장 완료")
                            
                            success = True
                        else:
                            print(f"  ⚠️ 여전히 봇 감지 페이지입니다. 재시도 중... ({retry_count + 1}/{max_retries})")
                            retry_count += 1
                            if retry_count < max_retries:
                                # 재시도 전에 페이지를 닫고 새로 열기
                                page.close()
                                page = context.new_page()
                                page.set_default_timeout(60000)
                                page.add_init_script("""
                                    Object.defineProperty(navigator, 'webdriver', {get: () => undefined});
                                    Object.defineProperty(navigator, 'plugins', {get: () => [1, 2, 3, 4, 5]});
                                    Object.defineProperty(navigator, 'languages', {get: () => ['ko-KR', 'ko', 'en-US', 'en']});
                                    window.chrome = {runtime: {}};
                                """)
                                time.sleep(1)
                    else:
                        print(f"  ⚠️ 본문이 비어있습니다. 재시도 중... ({retry_count + 1}/{max_retries})")
                        retry_count += 1
                        if retry_count < max_retries:
                            page.close()
                            page = context.new_page()
                            page.set_default_timeout(60000)
                            page.add_init_script("""
                                Object.defineProperty(navigator, 'webdriver', {get: () => undefined});
                                Object.defineProperty(navigator, 'plugins', {get: () => [1, 2, 3, 4, 5]});
                                Object.defineProperty(navigator, 'languages', {get: () => ['ko-KR', 'ko', 'en-US', 'en']});
                                window.chrome = {runtime: {}};
                            """)
                            time.sleep(1)
                            
                except Exception as e:
                    retry_count += 1
                    print(f"  ❌ 오류 발생 ({type(e).__name__}): {str(e)[:100]}")
                    if retry_count < max_retries:
                        try:
                            page.close()
                            page = context.new_page()
                            page.set_default_timeout(60000)
                            page.add_init_script("""
                                Object.defineProperty(navigator, 'webdriver', {get: () => undefined});
                                Object.defineProperty(navigator, 'plugins', {get: () => [1, 2, 3, 4, 5]});
                                Object.defineProperty(navigator, 'languages', {get: () => ['ko-KR', 'ko', 'en-US', 'en']});
                                window.chrome = {runtime: {}};
                            """)
                        except:
                            pass
                        time.sleep(1)
            
            # 컨텍스트 완전히 종료 (세션 초기화)
            try:
                page.close()
                context.close()
            except:
                pass
            
            if not success:
                print(f"  ❌ 최종 실패: {url}")
            
            # 요청 간 짧은 대기 (세션 격리를 위해)
            if idx < len(urls):  # 마지막이 아닐 때만 대기
                wait_time = random.uniform(0.5, 1.5)  # 0.5~1.5초 랜덤 대기
                print(f"  ⏸️  {wait_time:.1f}초 대기 중...")
                time.sleep(wait_time)
        
        # 브라우저 종료
        try:
            browser.close()
        except:
            pass
    
    print(f"\n✅ 재크롤링 완료: {success_count}개 성공")
    return results


def update_json_file_single(json_path: str, recrawled_article: Dict):
    """단일 재크롤링된 데이터를 즉시 JSON 파일에 업데이트"""
    json_path_obj = Path(json_path)
    
    # 기존 데이터 로드
    try:
        all_articles = load_json_file(json_path)
    except:
        all_articles = []
    
    # URL을 키로 하는 딕셔너리 생성 (빠른 검색용)
    url_to_article = {article.get("url"): article for article in all_articles}
    
    # 재크롤링된 데이터로 업데이트
    url = recrawled_article.get("url")
    if url:
        if url in url_to_article:
            # 기존 항목 업데이트
            url_to_article[url].update(recrawled_article)
        else:
            # 새 항목 추가
            url_to_article[url] = recrawled_article
    
    # 업데이트된 리스트로 변환
    updated_articles = list(url_to_article.values())
    
    # 파일 저장
    with open(json_path_obj, "w", encoding="utf-8") as f:
        json.dump(updated_articles, f, ensure_ascii=False, indent=2)


def update_json_file(json_path: str, recrawled_articles: List[Dict]):
    """재크롤링된 데이터로 JSON 파일 업데이트 (일괄 처리용)"""
    print("=" * 70)
    print("💾 JSON 파일 업데이트 중...")
    print("=" * 70)
    
    # 기존 데이터 로드
    all_articles = load_json_file(json_path)
    
    # URL을 키로 하는 딕셔너리 생성 (빠른 검색용)
    url_to_article = {article.get("url"): article for article in all_articles}
    
    # 재크롤링된 데이터로 업데이트
    updated_count = 0
    for recrawled in recrawled_articles:
        url = recrawled.get("url")
        if url and url in url_to_article:
            # 기존 항목 업데이트
            url_to_article[url].update(recrawled)
            updated_count += 1
            print(f"  ✅ 업데이트: {recrawled['title'][:50]}...")
    
    # 업데이트된 리스트로 변환
    updated_articles = list(url_to_article.values())
    
    # 파일 저장
    json_path_obj = Path(json_path)
    
    # 새 파일 저장
    with open(json_path_obj, "w", encoding="utf-8") as f:
        json.dump(updated_articles, f, ensure_ascii=False, indent=2)
    
    print(f"\n✅ JSON 파일 업데이트 완료: {updated_count}개 항목 업데이트")
    print(f"   총 {len(updated_articles)}개 기사")


def main():
    """메인 실행 함수"""
    import argparse
    
    parser = argparse.ArgumentParser(description="크롤링 실패한 뉴스를 재크롤링하고 JSON 파일 업데이트")
    parser.add_argument(
        "--json-path",
        type=str,
        default="data/investing_news.json",
        help="investing_news.json 파일 경로"
    )
    
    args = parser.parse_args()
    
    # JSON 파일 경로 확인
    json_path = Path(args.json_path)
    if not json_path.is_absolute():
        # 상대 경로인 경우 스크립트 위치 기준으로 계산
        script_dir = Path(__file__).parent
        json_path = script_dir / json_path
    
    if not json_path.exists():
        print(f"❌ 파일을 찾을 수 없습니다: {json_path}")
        return
    
    print("=" * 70)
    print("🚀 크롤링 실패 뉴스 재처리 스크립트 시작")
    print("=" * 70)
    print(f"📁 JSON 파일: {json_path}")
    print()
    
    # 1. 실패한 기사 필터링
    failed_articles = filter_failed_articles(str(json_path))
    
    if not failed_articles:
        print("\n✅ 크롤링 실패한 기사가 없습니다. 작업을 종료합니다.")
        return
    
    # 2. URL 추출
    urls = [article.get("url") for article in failed_articles if article.get("url")]
    print(f"\n📋 재크롤링 대상 URL: {len(urls)}개")
    
    # 3. 재크롤링 (하나씩 즉시 저장)
    recrawled_articles = recrawl_urls(urls, str(json_path))
    
    if not recrawled_articles:
        print("\n❌ 재크롤링된 기사가 없습니다.")
        print("   (일부 성공한 항목은 이미 JSON 파일에 저장되었습니다)")
        return
    
    # 5. 결과 출력
    print("\n" + "=" * 70)
    print("📊 최종 결과")
    print("=" * 70)
    print(f"   재크롤링 성공: {len(recrawled_articles)}개")
    print("=" * 70)


if __name__ == "__main__":
    main()

