# -*- coding: utf-8 -*-

"""Investing.com 뉴스 크롤링 스크립트 (RSS 피드 사용)"""

import feedparser
from playwright.sync_api import sync_playwright
from bs4 import BeautifulSoup
import time
from datetime import datetime
import json
from typing import List, Dict


class InvestingNewsCrawler:
    """Investing.com 뉴스 크롤링 클래스"""

    def __init__(self, rss_url: str = "https://kr.investing.com/rss/news.rss"):
        self.rss_url = rss_url

    def fetch_rss_feed(self):
        """RSS 피드 가져오기"""
        feedparser.USER_AGENT = (
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        )
        return feedparser.parse(self.rss_url)

    def get_date(self, page):
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

    def get_content(self, page):
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

    def parse_article(self, page, article_url: str, wait_for_content: bool = True):
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
                        content = self.get_content(page)
                        if content and len(content) > 50:
                            break
                    
                    # 진행 상황 출력
                    if waited % 6 == 0:  # 6초마다 출력
                        print(f"    ⏳ 봇 감지 페이지 대기 중... ({waited}초)")
            else:
                time.sleep(1)

            title = (page.locator("h1").first.text_content() or page.title() or "").strip()
            date = self.get_date(page)
            content = self.get_content(page)

            return {"title": title, "content": content, "date": date, "url": article_url}
        except Exception as e:
            print(f"  ⚠️ 페이지 로드 실패 ({type(e).__name__}): {str(e)[:100]}")
            # 에러 발생 시 기본 정보만 반환
            return {"title": "", "content": "", "date": "", "url": article_url}

    def crawl(self, max_articles: int = 10) -> List[Dict[str, str]]:
        """전체 크롤링 프로세스 실행"""
        print(f"RSS 피드에서 뉴스 가져오는 중: {self.rss_url}")
        feed = self.fetch_rss_feed()

        if not feed or not feed.entries:
            print("RSS 피드에서 기사를 찾을 수 없습니다.")
            return []

        print(f"총 {len(feed.entries)}개 기사 발견")

        results = []
        article_count = min(max_articles, len(feed.entries))
        article_urls = [
            entry.get("link", "")
            for entry in feed.entries[:article_count]
            if entry.get("link")
        ]

        import random
        
        # 랜덤 User-Agent 목록 (봇 감지 회피)
        user_agents = [
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:131.0) Gecko/20100101 Firefox/131.0",
        ]
        
        with sync_playwright() as p:
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
            context = browser.new_context(
                viewport={"width": 1920, "height": 1080},
                user_agent=random.choice(user_agents),  # 랜덤 User-Agent 사용
                ignore_https_errors=True,
                storage_state=None,  # 쿠키/세션 초기화
            )
            page = context.new_page()
            
            # 페이지 타임아웃 설정
            page.set_default_timeout(60000)  # 60초

            # webdriver 속성 숨기기 (강화된 봇 감지 회피)
            page.add_init_script("""
                Object.defineProperty(navigator, 'webdriver', {get: () => undefined});
                Object.defineProperty(navigator, 'plugins', {get: () => [1, 2, 3, 4, 5]});
                Object.defineProperty(navigator, 'languages', {get: () => ['ko-KR', 'ko', 'en-US', 'en']});
                window.chrome = {runtime: {}};
            """)

            for idx, url in enumerate(article_urls, 1):
                try:
                    print(f"[{idx}/{len(article_urls)}] 처리 중: {url[:60]}...")
                    # 첫 시도에서는 봇 감지 페이지 대기 활성화
                    article_data = self.parse_article(page, url, wait_for_content=True)

                    if article_data and article_data.get("content"):
                        results.append(article_data)
                        print(
                            f"  ✓ 완료: {article_data['title'][:50]}... (본문 {len(article_data['content'])}자)"
                        )
                    else:
                        print(f"  ✗ 본문 없음 (건너뜀)")

                    # 요청 간 랜덤 대기 (봇 감지 회피)
                    wait_time = random.uniform(1.0, 3.0)
                    time.sleep(wait_time)
                except Exception as e:
                    print(f"  ❌ 기사 처리 실패 ({type(e).__name__}): {str(e)[:100]}")
                    # 에러가 발생해도 다음 기사 계속 처리
                    continue

            browser.close()

        return results

    def save_to_json(
        self, data: List[Dict[str, str]], filename: str = "investing_news.json"
    ):
        """결과를 JSON 파일로 저장"""
        with open(filename, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"\n결과가 {filename}에 저장되었습니다.")

    def append_to_json(
        self, data: List[Dict[str, str]], filename: str = "investing_news.json"
    ):
        """결과를 기존 JSON 파일에 누적 저장 (중복 제거)"""
        import os
        from datetime import datetime

        # 기존 데이터 로드
        existing_data = []
        if os.path.exists(filename):
            try:
                with open(filename, "r", encoding="utf-8") as f:
                    existing_data = json.load(f)
            except (json.JSONDecodeError, FileNotFoundError):
                existing_data = []

        # 기존 URL 목록 (중복 체크용)
        existing_urls = {article.get("url", "") for article in existing_data}

        # 새 데이터 추가 (중복 제거)
        new_count = 0
        for article in data:
            url = article.get("url", "")
            if url and url not in existing_urls:
                # 크롤링 시간 추가
                article["crawled_at"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                existing_data.append(article)
                existing_urls.add(url)
                new_count += 1

        # 파일 저장
        with open(filename, "w", encoding="utf-8") as f:
            json.dump(existing_data, f, ensure_ascii=False, indent=2)

        print(
            f"\n{filename}에 {new_count}개 새 기사 추가 (총 {len(existing_data)}개 기사)"
        )
        return new_count

    def save_to_txt(
        self, data: List[Dict[str, str]], filename: str = "investing_news.txt"
    ):
        """결과를 텍스트 파일로 저장"""
        with open(filename, "w", encoding="utf-8") as f:
            for idx, article in enumerate(data, 1):
                f.write(f"\n{'='*80}\n")
                f.write(f"기사 {idx}\n")
                f.write(f"{'='*80}\n")
                f.write(f"제목: {article['title']}\n")
                f.write(f"날짜: {article['date']}\n")
                f.write(f"URL: {article['url']}\n")
                f.write(f"\n본문:\n{article['content']}\n")
        print(f"\n결과가 {filename}에 저장되었습니다.")


def main():
    """메인 실행 함수"""
    crawler = InvestingNewsCrawler()
    results = crawler.crawl(max_articles=10)

    if results:
        print("\n" + "=" * 80)
        print("크롤링 결과")
        print("=" * 80)
        for idx, article in enumerate(results, 1):
            print(f"\n[기사 {idx}]")
            print(f"제목: {article['title']}")
            print(f"날짜: {article['date']}")
            print(f"본문 (일부): {article['content'][:100]}...")
            print(f"URL: {article['url']}")

        crawler.save_to_json(results)
        crawler.save_to_txt(results)
    else:
        print("크롤링된 기사가 없습니다.")


if __name__ == "__main__":
    main()

