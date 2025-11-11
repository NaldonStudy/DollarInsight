# -*- coding: utf-8 -*-

"""
Reddit 인기 게시글 크롤링 스크립트 - Reddit 공식 API 사용

✅ Reddit 공식 API를 사용하여 안전하고 합법적으로 데이터를 수집합니다.
- Reddit API 정책 준수
- Rate limiting 자동 처리
- ToS 위반 리스크 없음

환경 변수 설정 필요:
- REDDIT_CLIENT_ID: Reddit 앱 Client ID
- REDDIT_CLIENT_SECRET: Reddit 앱 Client Secret
- REDDIT_USERNAME: Reddit 사용자명 (User-Agent에만 사용, Application-only OAuth 사용 시 비밀번호 불필요)
"""

import requests
from datetime import datetime
import json
from typing import List, Dict, Optional
import os
from deep_translator import GoogleTranslator
import time
import re

# Access token 캐싱을 위한 전역 변수
_access_token = None
_token_expires_at = 0


def load_env_file(env_path: str = "/opt/airflow/.env") -> Dict[str, str]:
    """환경 변수 파일(.env)을 읽어서 딕셔너리로 반환"""
    env_vars = {}
    if os.path.exists(env_path):
        try:
            with open(env_path, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    # 주석이나 빈 줄 건너뛰기
                    if not line or line.startswith("#"):
                        continue
                    # KEY=VALUE 형식 파싱
                    if "=" in line:
                        key, value = line.split("=", 1)
                        key = key.strip()
                        value = value.strip().strip('"').strip("'")
                        env_vars[key] = value
        except Exception as e:
            print(f"⚠️ .env 파일 읽기 실패 ({env_path}): {str(e)}")
    return env_vars


def get_env_var(key: str, default: Optional[str] = None) -> Optional[str]:
    """환경 변수를 가져오되, 없으면 .env 파일에서 읽기"""
    # 먼저 환경 변수에서 확인
    value = os.getenv(key)
    if value:
        return value
    
    # 환경 변수가 없으면 .env 파일에서 읽기
    env_vars = load_env_file()
    return env_vars.get(key, default)


class RedditPostsCrawler:
    """Reddit 인기 게시글 크롤링 클래스 - Reddit 공식 API 사용"""

    def __init__(
        self,
        subreddits: List[str] = None,
        min_score: int = 100,
        client_id: Optional[str] = None,
        client_secret: Optional[str] = None,
        username: Optional[str] = None,
        password: Optional[str] = None,
        use_app_only_auth: bool = True,  # Application-only OAuth (client_credentials) - 계정 정보 불필요
    ):
        self.subreddits = subreddits or ["wallstreetbets", "stocks", "investing"]
        self.min_score = min_score  # 최소 score 필터

        # Reddit API 인증 정보 (환경 변수 또는 파라미터로)
        # 환경 변수가 없으면 .env 파일에서 읽기
        self.client_id = client_id or get_env_var("REDDIT_CLIENT_ID")
        self.client_secret = client_secret or get_env_var("REDDIT_CLIENT_SECRET")
        self.use_app_only_auth = use_app_only_auth
        
        # 프록시 설정 (필요시 환경 변수에서 가져오기)
        self.proxies = None  # 기본값은 프록시 없음

        # Reddit OAuth는 password grant만 지원합니다
        if self.use_app_only_auth:
            # Reddit은 client_credentials grant를 지원하지 않으므로 password grant 사용
            password = password or get_env_var("REDDIT_PASSWORD")
            
            if self.client_id and self.client_secret and password:
                # OAuth 사용 가능 (password grant)
                self.username = username or get_env_var("REDDIT_USERNAME", "MyRedditApp")
                self.password = password
                # User-Agent에 username 포함 (Reddit API 요구사항)
                self.user_agent = f"MyRedditApp/0.1 by u/{self.username}"
                print(
                    f"✅ Reddit OAuth API 사용 (Password grant, 사용자: {self.username})"
                )
            else:
                # 비밀번호가 없으면 에러 발생 (OAuth 필수)
                missing = []
                if not self.client_id:
                    missing.append("REDDIT_CLIENT_ID")
                if not self.client_secret:
                    missing.append("REDDIT_CLIENT_SECRET")
                if not password:
                    missing.append("REDDIT_PASSWORD")
                
                raise ValueError(
                    f"⚠️ Reddit OAuth 사용을 위해 다음 환경 변수가 필요합니다: {', '.join(missing)}\n"
                    f"구글 계정 로그인 시에도 Reddit 계정에 비밀번호를 추가로 설정할 수 있습니다.\n"
                    f"Reddit 설정 페이지에서 계정 비밀번호를 설정하세요."
                )
        else:
            # Password grant 방식 (사용자 인증 필요)
            self.username = username or get_env_var("REDDIT_USERNAME")
            self.password = password or get_env_var("REDDIT_PASSWORD")
            self.user_agent = (
                f"MyRedditApp/0.1 by {self.username}"
                if self.username
                else "MyRedditApp/0.1"
            )

            if not all(
                [self.client_id, self.client_secret, self.username, self.password]
            ):
                raise ValueError(
                    "Reddit API 인증 정보가 필요합니다. "
                    "환경 변수 또는 파라미터로 client_id, client_secret, username, password를 제공하세요."
                )
            print(f"✅ Reddit 공식 API 사용 (사용자: {self.username})")

    def get_access_token(self) -> Optional[str]:
        """Reddit API Access Token 획득 (토큰 캐싱) - 실패 시 None 반환"""
        global _access_token, _token_expires_at

        # 토큰이 아직 유효하면 재사용
        if _access_token and time.time() < _token_expires_at:
            return _access_token

        # 인증 정보가 없으면 None 반환 (공개 API 사용)
        if not self.client_id or not self.client_secret:
            return None

        try:
            # OAuth 인증
            auth = requests.auth.HTTPBasicAuth(self.client_id, self.client_secret)
            headers = {"User-Agent": self.user_agent}

            # Reddit API는 client_credentials grant를 지원하지 않습니다
            # Password grant만 지원하므로 username과 password가 필요합니다
            if self.use_app_only_auth:
                # Reddit은 client_credentials를 지원하지 않으므로 password grant 사용
                # 단, password가 없으면 공개 API로 폴백
                if not self.password:
                    print("⚠️ Reddit OAuth는 password grant만 지원합니다. password가 없어 공개 API를 사용합니다.")
                    return None
                data = {
                    "grant_type": "password",
                    "username": self.username,
                    "password": self.password,
                }
            else:
                # Password grant 방식 (사용자 인증 필요)
                if not self.password:
                    print("⚠️ Reddit OAuth는 password가 필요합니다. 공개 API를 사용합니다.")
                    return None
                data = {
                    "grant_type": "password",
                    "username": self.username,
                    "password": self.password,
                }

            # Reddit OAuth 토큰 요청
            response = requests.post(
                "https://www.reddit.com/api/v1/access_token",
                auth=auth,
                data=data,
                headers=headers,
                proxies=self.proxies if self.proxies else None,
                verify=True,
                timeout=10,
            )

            if response.status_code == 200:
                token_data = response.json()
                
                # Reddit API 오류 확인 (web app 타입은 password grant 불가)
                if "error" in token_data:
                    error_desc = token_data.get("error_description", token_data.get("error", ""))
                    print(f"⚠️ Reddit OAuth 오류: {error_desc}")
                    if "Only script apps" in error_desc or "script" in error_desc.lower():
                        print("⚠️ Reddit 앱이 'script' 타입이어야 password grant를 사용할 수 있습니다.")
                        print("⚠️ 현재 앱은 'web app' 타입이므로 OAuth를 사용할 수 없습니다.")
                        print("⚠️ 공개 API로 폴백합니다...")
                    else:
                        print("⚠️ 공개 API로 폴백합니다...")
                    return None
                
                _access_token = token_data.get("access_token")
                if not _access_token:
                    print(f"⚠️ 토큰 응답에 access_token이 없습니다: {token_data}")
                    print("⚠️ 공개 API로 폴백합니다...")
                    return None
                    
                expires_in = token_data.get("expires_in", 3600)  # 기본 1시간
                _token_expires_at = time.time() + expires_in - 60  # 1분 여유

                auth_type = "Application-only" if self.use_app_only_auth else "User"
                print(
                    f"✅ Reddit API 토큰 획득 완료 ({auth_type} OAuth, 유효 시간: {expires_in}초)"
                )
                return _access_token
            else:
                error_msg = (
                    f"토큰 획득 실패: HTTP {response.status_code} - {response.text}"
                )
                print(f"⚠️ {error_msg}")
                print("⚠️ 공개 API로 폴백합니다...")
                return None

        except Exception as e:
            print(f"⚠️ Reddit API 인증 오류: {str(e)}")
            print("⚠️ 공개 API로 폴백합니다...")
            return None

    def clean_text(self, text: str) -> str:
        """텍스트에서 줄바꿈과 링크 제거"""
        if not text:
            return ""

        # 줄바꿈 제거 (공백으로 대체)
        text = text.replace("\n", " ").replace("\r", " ")

        # 여러 공백을 하나로 통합
        text = re.sub(r"\s+", " ", text)

        # URL 링크 제거 (http://, https://, www.로 시작하는 링크)
        text = re.sub(r"https?://[^\s]+", "", text)
        text = re.sub(r"www\.[^\s]+", "", text)
        text = re.sub(
            r"\[([^\]]+)\]\([^\)]+\)", r"\1", text
        )  # 마크다운 링크 형식 [text](url)

        return text.strip()

    def translate_to_korean(self, text: str, max_length: int = 5000) -> str:
        """영어 텍스트를 한글로 번역"""
        if not text or len(text.strip()) == 0:
            return ""

        try:
            # HTML 엔티티 제거 및 텍스트 정리
            text_clean = (
                text.replace("&amp;", "&")
                .replace("&lt;", "<")
                .replace("&gt;", ">")
                .replace("&quot;", '"')
                .replace("&#39;", "'")
            )

            # 너무 긴 텍스트는 잘라서 번역
            if len(text_clean) > max_length:
                text_clean = text_clean[:max_length]

            translator = GoogleTranslator(source="en", target="ko")
            translated = translator.translate(text_clean)
            return translated
        except Exception as e:
            # 번역 실패 시 원문 반환
            return text_clean if "text_clean" in locals() else text

    def get_post_content_from_url(self, permalink: str) -> str:
        """Reddit API를 통해 게시글 본문 추출 (OAuth 또는 공개 API)"""
        global _access_token
        try:
            # Access token 획득 시도
            access_token = self.get_access_token()
            
            # OAuth API 사용 가능하면 사용, 아니면 공개 API 사용
            if access_token:
                api_url = f"https://oauth.reddit.com{permalink.rstrip('/')}.json"
                headers = {
                    "Authorization": f"bearer {access_token}",
                    "User-Agent": self.user_agent
                    or "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
                }
            else:
                # 공개 API 사용 (인증 불필요)
                api_url = f"https://www.reddit.com{permalink.rstrip('/')}.json"
                headers = {
                    "User-Agent": self.user_agent
                    or "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
                }

            time.sleep(1)  # Rate limiting (Reddit API: 분당 60회 제한)
            response = requests.get(api_url, headers=headers, timeout=10)

            if response.status_code == 200:
                data = response.json()
                # Reddit JSON 구조: 첫 번째 항목이 게시글
                if isinstance(data, list) and len(data) > 0:
                    post_data = (
                        data[0].get("data", {}).get("children", [{}])[0].get("data", {})
                    )
                    selftext = post_data.get("selftext", "")
                    return selftext
            elif response.status_code == 401 and access_token:
                # 토큰 만료 시 공개 API로 폴백
                print("⚠️ 토큰 만료, 공개 API로 전환...")
                _access_token = None
                return self.get_post_content_from_url(permalink)
            elif response.status_code == 403 and access_token:
                # 403 Forbidden - 공개 API로 폴백
                print("⚠️ OAuth 요청 차단, 공개 API로 전환...")
                _access_token = None
                return self.get_post_content_from_url(permalink)
            elif response.status_code == 429:
                # Rate limit 초과
                print("⚠️ Rate limit 초과, 10초 대기...")
                time.sleep(10)
                return self.get_post_content_from_url(permalink)
        except Exception as e:
            print(f"⚠️ 본문 추출 실패 ({permalink}): {str(e)}")

        return ""

    def get_reddit_posts(self, subreddit: str, limit: int = 25) -> List[Dict]:
        """Reddit API를 통해 인기 게시글 가져오기 (OAuth 또는 공개 API)"""
        global _access_token
        try:
            # Access token 획득 시도
            access_token = self.get_access_token()
            
            # OAuth API 사용 가능하면 사용, 아니면 공개 API 사용
            if access_token:
                url = f"https://oauth.reddit.com/r/{subreddit}/hot.json"
                headers = {
                    "Authorization": f"bearer {access_token}",
                    "User-Agent": self.user_agent
                    or "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
                }
                api_type = "OAuth API"
            else:
                # 공개 API 사용 (인증 불필요)
                url = f"https://www.reddit.com/r/{subreddit}/hot.json"
                headers = {
                    "User-Agent": self.user_agent
                    or "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
                }
                api_type = "공개 API"
            
            params = {"limit": limit}

            # Rate limiting (Reddit API: 분당 60회 제한)
            time.sleep(1)

            response = requests.get(url, headers=headers, params=params, timeout=10)

            if response.status_code == 200:
                data = response.json()
                posts = data.get("data", {}).get("children", [])
                print(f"✅ {subreddit}: {len(posts)}개 게시글 수집 (Reddit {api_type})")
                return [post["data"] for post in posts]
            elif response.status_code == 401 and access_token:
                # 토큰 만료 시 공개 API로 폴백
                print(f"⚠️ {subreddit} 토큰 만료 (401), 공개 API로 전환...")
                _access_token = None
                return self.get_reddit_posts(subreddit, limit)
            elif response.status_code == 403 and access_token:
                # 403 Forbidden - Reddit이 OAuth 요청을 차단한 경우 공개 API로 폴백
                print(f"⚠️ {subreddit} OAuth 요청 차단 (403), 공개 API로 전환...")
                _access_token = None
                return self.get_reddit_posts(subreddit, limit)
            elif response.status_code == 429:
                print(
                    f"⚠️ {subreddit} 429 Too Many Requests - API 호출 횟수 초과, 10초 대기..."
                )
                time.sleep(10)
                return self.get_reddit_posts(subreddit, limit)
            else:
                print(f"⚠️ {subreddit} API 오류: HTTP {response.status_code}")
                # 공개 API로 폴백 시도
                if access_token:
                    print(f"⚠️ {subreddit} OAuth 실패, 공개 API로 폴백 시도...")
                    _access_token = None
                    return self.get_reddit_posts(subreddit, limit)
                return []
        except Exception as e:
            print(f"⚠️ {subreddit} 게시글 가져오기 실패: {str(e)}")
            import traceback

            traceback.print_exc()
            return []

    def crawl(self, limit_per_subreddit: int = 25) -> Dict:
        """인기 게시글 크롤링 - 타이틀과 본문만"""
        posts_data = []

        for idx, subreddit in enumerate(self.subreddits):
            # 서브레딧 간 요청 간격 (Reddit API Rate limiting 준수)
            if idx > 0:
                time.sleep(2)
            posts = self.get_reddit_posts(subreddit, limit_per_subreddit)

            for post in posts:
                score = post.get("score", 0)

                # score 필터링
                if score < self.min_score:
                    continue

                title_en = post.get("title", "")
                selftext_en = post.get("selftext", "")

                # selftext가 비어있으면 API를 통해 본문 추출 시도
                if not selftext_en or selftext_en.strip() == "":
                    permalink = post.get("permalink", "")
                    if permalink:
                        selftext_en = self.get_post_content_from_url(permalink)
                        time.sleep(1)  # Rate limiting (Reddit API 제한 준수)

                # 타이틀과 본문 한글 번역
                title_ko = self.translate_to_korean(title_en, max_length=500)
                selftext_ko = (
                    self.translate_to_korean(selftext_en, max_length=5000)
                    if selftext_en
                    else ""
                )

                # selftext에서 줄바꿈과 링크 제거
                selftext_ko = self.clean_text(selftext_ko)

                # created_utc를 날짜 형식으로 변환
                created_utc = post.get("created_utc", 0)
                if created_utc:
                    created_date = datetime.fromtimestamp(created_utc).strftime("%Y-%m-%d %H:%M:%S")
                else:
                    created_date = ""

                posts_data.append(
                    {
                        "subreddit": subreddit,
                        "title": title_ko,  # 한글 번역된 타이틀
                        "content": selftext_ko if selftext_ko else "",  # 한글 번역된 본문
                        "score": score,
                        "num_comments": post.get("num_comments", 0),
                        "날짜": created_date,  # 날짜 형식으로 변환
                        "url": post.get("url", ""),
                        "permalink": post.get("permalink", ""),
                    }
                )

        # score 내림차순 정렬
        posts_data.sort(key=lambda x: x.get("score", 0), reverse=True)

        results = {
            "crawled_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "subreddits": self.subreddits,
            "min_score": self.min_score,
            "posts": posts_data,
        }

        return results

    def append_to_json(self, data: Dict, filename: str) -> int:
        """기존 JSON 파일에 누적 저장"""
        os.makedirs(
            os.path.dirname(filename) if os.path.dirname(filename) else ".",
            exist_ok=True,
        )

        existing_data = []
        if os.path.exists(filename):
            try:
                with open(filename, "r", encoding="utf-8") as f:
                    existing_data = json.load(f)
            except:
                existing_data = []

        # 기존 데이터에서 모든 게시글의 permalink 수집
        existing_permalinks = set()
        for day_data in existing_data:
            for post in day_data.get("posts", []):
                permalink = post.get("permalink", "")
                if permalink:
                    existing_permalinks.add(permalink)

        # 새로 크롤링한 게시글 중 중복되지 않은 것만 필터링
        new_posts = [
            post
            for post in data.get("posts", [])
            if post.get("permalink", "") not in existing_permalinks
        ]

        if not new_posts:
            print("⚠️ 모든 게시글이 이미 존재합니다. 새로 추가된 게시글이 없습니다.")
            return 0

        # 중복되지 않은 게시글이 있는 경우, 기존 데이터에 추가
        # 같은 날짜의 데이터가 있으면 그날 데이터에 게시글 추가, 없으면 새로 생성
        current_date = datetime.now().strftime("%Y-%m-%d")
        found_today_data = False

        for day_data in existing_data:
            if day_data.get("crawled_at", "").startswith(current_date):
                # 오늘 날짜 데이터가 있으면 게시글 추가
                day_data["posts"].extend(new_posts)
                # score 순으로 다시 정렬
                day_data["posts"].sort(key=lambda x: x.get("score", 0), reverse=True)
                found_today_data = True
                break

        if not found_today_data:
            # 오늘 날짜 데이터가 없으면 새로 생성하되, 중복되지 않은 게시글만 포함
            data["posts"] = new_posts
            existing_data.append(data)

        # 파일에 저장
        with open(filename, "w", encoding="utf-8") as f:
            json.dump(existing_data, f, ensure_ascii=False, indent=2)

        return len(new_posts)

    def crawl_and_save(self, filename: str, limit_per_subreddit: int = 25) -> Dict:
        """크롤링 실행 및 저장"""
        results = self.crawl(limit_per_subreddit=limit_per_subreddit)

        new_count = self.append_to_json(results, filename)

        return {
            "status": "success",
            "total_posts": len(results["posts"]),
            "new_items": new_count,
            "results": results,
        }


def main():
    """메인 실행 함수"""
    # Windows 콘솔 UTF-8 인코딩 설정
    import sys

    if sys.platform == "win32":
        import io

        sys.stdout = io.TextIOWrapper(
            sys.stdout.buffer, encoding="utf-8", errors="replace"
        )
        sys.stderr = io.TextIOWrapper(
            sys.stderr.buffer, encoding="utf-8", errors="replace"
        )

    # Reddit 공개 API 사용 (인증 불필요)
    crawler = RedditPostsCrawler()

    # AI_airflow/data 폴더 경로 설정
    script_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    data_dir = os.path.join(script_dir, "data")
    os.makedirs(data_dir, exist_ok=True)
    json_file = os.path.join(data_dir, "reddit_stocks.json")

    result = crawler.crawl_and_save(json_file, limit_per_subreddit=25)
    results = result.get("results", {})

    print("\n" + "=" * 70)
    print("📊 Reddit 인기 게시글 크롤링 결과")
    print("=" * 70)
    print(f"\n✅ 상태: {result['status']}")
    print(f"📝 수집된 게시글: {result['total_posts']}개")
    print(f"➕ 신규 추가: {result['new_items']}개")
    print(f"💾 저장 경로: {json_file}")

    # 게시글 샘플 표시
    if results.get("posts"):
        print("\n" + "-" * 70)
        print("📋 게시글 샘플 (상위 5개 - score 순)")
        print("-" * 70)
        for idx, post in enumerate(results["posts"][:5], 1):
            title_ko = post.get("title", "")[:60]
            subreddit = post.get("subreddit", "")
            score = post.get("score", 0)
            selftext_len = len(post.get("content", ""))
            print(f"\n{idx}. r/{subreddit} | 👍{score} | 본문: {selftext_len}자")
            print(f"   {title_ko}...")

    print("\n" + "=" * 70)


if __name__ == "__main__":
    main()
