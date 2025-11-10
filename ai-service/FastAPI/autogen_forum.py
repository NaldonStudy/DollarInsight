"""
AutoGen 다중 에이전트 토론시스템 - 파이프라인
다른 모듈들을 통합하여 전체 토론 시스템을 실행하는 메인 파이프라인
"""

# ===== 사용자 설정 =====
INITIAL_MESSAGE = "삼성전자 주식에 대해 투자 의견을 나눠주세요."
MAX_ROUNDS = 15
AUTO_MAX_ROUNDS = 7  # 사용자 입력 없이 자동 진행 시 최대 라운드 (6~8 사이)
USE_RERANK = False
USE_POSTGRES = False
INPUT_TIMEOUT = 3
PAUSE_MODE = False
# 활성 에이전트 (발언 순서는 랜덤, 직전 발언자는 제외)
ACTIVE_AGENTS = ["민지", "희열", "테오", "지율", "덕수"]
MAX_CONTEXT_MESSAGES = 3

# ===== Import =====
import os
import sys
from pathlib import Path
import logging
import warnings
import random
import queue
import traceback
import signal
import time
import threading

# 현재 파일이 있는 FastAPI 폴더를 Python 경로에 추가
CURRENT_DIR = Path(__file__).resolve().parent
if str(CURRENT_DIR) not in sys.path:
    sys.path.insert(0, str(CURRENT_DIR))

warnings.filterwarnings("ignore", message=".*flaml.automl.*")
warnings.filterwarnings("ignore", message=".*XLMRobertaTokenizerFast.*")
warnings.filterwarnings("ignore", message=".*fast tokenizer.*")
logging.getLogger("transformers").setLevel(logging.ERROR)
logging.getLogger().setLevel(logging.ERROR)

from dotenv import load_dotenv

load_dotenv()

from autogen import ConversableAgent, UserProxyAgent

from database import (
    OPENAI_API_KEY,
    GMS_BASE_URL,
    load_agent_collections,
    search_postgres,
)
from search import keyword_search_bm25, semantic_search_vector
from prompts import create_all_agents

# ===== 유틸리티 함수 =====


def input_with_timeout(prompt, timeout=INPUT_TIMEOUT):
    """타임아웃이 있는 입력 함수 (한글 지원)"""
    print(prompt, end="", flush=True)

    if sys.platform != "win32":

        def timeout_handler(signum, frame):
            raise TimeoutError("입력 타임아웃")

        signal.signal(signal.SIGALRM, timeout_handler)
        signal.alarm(timeout)
        try:
            line = input()
            signal.alarm(0)
            return line
        except TimeoutError:
            signal.alarm(0)
            print(f"\n[타임아웃 {timeout}초] 자동 진행")
            return ""
    else:
        result_queue = queue.Queue()
        done = threading.Event()

        def read_input():
            try:
                line = (
                    input()
                    if sys.stdin.isatty()
                    else sys.stdin.readline().rstrip("\n\r")
                )
                result_queue.put(line)
            except (EOFError, KeyboardInterrupt):
                result_queue.put("")
            finally:
                done.set()

        input_thread = threading.Thread(target=read_input, daemon=True)
        input_thread.start()

        start_time = time.time()
        while time.time() - start_time < timeout:
            if done.is_set():
                try:
                    return result_queue.get_nowait()
                except queue.Empty:
                    return ""
            time.sleep(0.1)

        print(f"\n[타임아웃 {timeout}초] 자동 진행")
        return ""


def get_llm_config(model_name, temperature):
    """LLM 설정 딕셔너리 생성"""
    # temperature를 지원하지 않는 모델 목록
    # - 추론 모델(o1, o3 시리즈)
    # - nano 모델들(gpt-5-nano 등 경량 모델)
    NO_TEMPERATURE_MODELS = [
        "o1",
        "o1-mini",
        "o1-preview",
        "o3",
        "o3-mini",
        "o3-pro",
        "nano",
    ]

    # 모든 모델을 GPT로 사용 (Gemini 커스텀 클라이언트는 나중에 추가 예정)
    # 형식: POST /v1/chat/completions (Authorization: Bearer {GMS_KEY})
    config_dict = {
        "config_list": [
            {"model": model_name, "api_key": OPENAI_API_KEY, "base_url": GMS_BASE_URL}
        ],
    }

    # temperature를 지원하는 모델만 temperature 추가
    if not any(no_temp_model in model_name for no_temp_model in NO_TEMPERATURE_MODELS):
        config_dict["temperature"] = temperature

    return config_dict


# ===== 페르소나 생성 =====
_all_agents = create_all_agents(
    ConversableAgent_class=ConversableAgent,
    UserProxyAgent_class=UserProxyAgent,
    get_llm_config_func=get_llm_config,
    load_agent_collections_func=load_agent_collections,
    keyword_search_func=keyword_search_bm25,
    semantic_search_func=semantic_search_vector,
    search_postgres_func=search_postgres,
    use_rerank=USE_RERANK,
)

민지 = _all_agents["민지"]
희열 = _all_agents["희열"]
테오 = _all_agents["테오"]
지율 = _all_agents["지율"]
덕수 = _all_agents["덕수"]
user = _all_agents["user"]


# ===== 실행 파이프라인 =====


def run():
    """메인 실행 함수"""
    print("💥 AI 투자 토론 배틀 시작 💥")
    print("=" * 50)
    print("🎲 5명의 에이전트가 격렬하게 토론합니다!")
    print("🔥 희열(공격적) vs 덕수(보수적) vs 지율(냉철)")
    print("🚀 테오(미래파) vs 민지(트렌드파)")
    print(f"⏱️  자동 진행 {AUTO_MAX_ROUNDS}라운드 (Enter로 계속)")
    print("=" * 50)

    messages = [{"content": INITIAL_MESSAGE, "role": "user", "name": "user"}]

    all_agents = {
        "민지": 민지,
        "희열": 희열,
        "테오": 테오,
        "지율": 지율,
        "덕수": 덕수,
    }
    ai_agents = [all_agents[name] for name in ACTIVE_AGENTS if name in all_agents]

    print(
        f"활성 에이전트: {', '.join([a.name for a in ai_agents])} / 총 {len(ai_agents)}명"
    )

    last_speaker = None
    turns = 0
    auto_turns = 0  # 사용자 입력 없이 진행된 턴 수
    limit_msgs = MAX_ROUNDS * 10
    spoken_agents = set()  # 발언한 에이전트 추적

    while turns < MAX_ROUNDS * 5:
        print("\n" + "=" * 60)
        print(f"턴 {turns + 1} 시작")
        print("=" * 60)

        # 모든 에이전트에게 최소 1번 발언권 보장
        if len(spoken_agents) < len(ai_agents):
            # 아직 발언 안 한 에이전트 중에서 선택
            not_spoken = [a for a in ai_agents if a not in spoken_agents]
            speaker = random.choice(not_spoken)
        else:
            # 모두 발언했으면 랜덤 선택 (직전 발언자 제외)
            available = [a for a in ai_agents if a != last_speaker]
            speaker = (
                random.choice(available) if available else random.choice(ai_agents)
            )

        spoken_agents.add(speaker)
        last_speaker = speaker

        # 에이전트별 이모지
        emojis = {"희열": "🔥", "덕수": "🧘", "지율": "📊", "테오": "🚀", "민지": "📱"}
        emoji = emojis.get(speaker.name, "💬")

        print(f"\n{emoji} [{speaker.name}] 발언 차례")

        try:
            print("-" * 60)

            if user not in speaker.chat_messages:
                speaker.chat_messages[user] = []

            limited_messages = (
                messages[-MAX_CONTEXT_MESSAGES:]
                if len(messages) > MAX_CONTEXT_MESSAGES
                else messages
            )
            if len(messages) > MAX_CONTEXT_MESSAGES:
                print(
                    f"[컨텍스트 제한] {len(messages)}개 메시지 → {len(limited_messages)}개로 제한 (최근 {MAX_CONTEXT_MESSAGES}개)"
                )

            speaker.chat_messages[user] = limited_messages
            result = speaker.generate_reply(messages=limited_messages, sender=user)
            reply = result[1] if isinstance(result, tuple) else result

            if reply:
                ai_resp = str(reply)
                emoji = emojis.get(speaker.name, "💬")
                print("\n" + "▶" * 30)
                print(f"{emoji} {speaker.name}의 의견:")
                print("▶" * 30)
                print(ai_resp)
                print("▶" * 30)

                # 검색 결과 출력 (PG, BM25, Vector 구분)
                if hasattr(speaker, "_last_search_results"):
                    # 가장 최근 검색 결과 가져오기
                    if speaker._last_search_results:
                        latest_key = list(speaker._last_search_results.keys())[-1]
                        search_data = speaker._last_search_results[latest_key]

                        print("\n[검색 근거]")

                        # PostgreSQL 결과
                        if search_data.get("postgres"):
                            print("\n  📊 PostgreSQL (재무 데이터):")
                            for idx, result in enumerate(
                                search_data["postgres"][:2], 1
                            ):
                                preview = (
                                    result[:150] + "..."
                                    if len(result) > 150
                                    else result
                                )
                                print(f"    {idx}. {preview}")

                        # BM25 키워드 검색 결과
                        if search_data.get("bm25"):
                            print("\n  🔍 BM25 키워드 검색:")
                            for idx, result in enumerate(search_data["bm25"][:2], 1):
                                preview = (
                                    result[:150] + "..."
                                    if len(result) > 150
                                    else result
                                )
                                print(f"    {idx}. {preview}")

                        # Vector 의미 검색 결과
                        if search_data.get("vector"):
                            print("\n  🧠 Vector 의미 검색:")
                            for idx, result in enumerate(search_data["vector"][:2], 1):
                                preview = (
                                    result[:150] + "..."
                                    if len(result) > 150
                                    else result
                                )
                                print(f"    {idx}. {preview}")

                        if not any(
                            [
                                search_data.get("postgres"),
                                search_data.get("bm25"),
                                search_data.get("vector"),
                            ]
                        ):
                            print("  (검색 결과 없음)")

                messages.append(
                    {"content": ai_resp, "role": "assistant", "name": speaker.name}
                )
        except Exception as e:
            print(f"AI 발언 에러: {type(e).__name__}: {e}")
            traceback.print_exc()
            break

        print("\n" + "=" * 60)
        if PAUSE_MODE:
            print("일시중단 모드 - 사용자 입력 대기")
        else:
            print("사용자 입력 (Enter: 계속, 메시지: 토론 참여)")
        print("=" * 60)

        user_input = (
            input("> ") if PAUSE_MODE else input_with_timeout("> ", INPUT_TIMEOUT)
        )

        if user_input.strip():
            # 사용자 입력이 있으면 자동 턴 카운터 리셋
            messages.append({"content": user_input, "role": "user", "name": "user"})
            print("\n사용자:")
            print("-" * 40)
            print(user_input)
            print("-" * 40)
            auto_turns = 0  # 카운터 리셋
        else:
            # 사용자 입력이 없으면 자동 턴 증가
            auto_turns += 1
            if auto_turns >= AUTO_MAX_ROUNDS:
                print("\n" + "🏁" * 30)
                print(f"💥 {AUTO_MAX_ROUNDS}라운드 완료! 토론 종료!")
                print("🏁" * 30)
                break

        turns += 1
        if len(messages) >= limit_msgs:
            print("\n" + "=" * 60)
            print("최대 턴 도달 - 토론 종료")
            print("=" * 60)
            break


if __name__ == "__main__":
    run()
