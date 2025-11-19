"""FastAPI AI Debate Server - AutoGen 토론 시스템"""

import os
import sys
from pathlib import Path

# FastAPI 폴더를 Python 경로에 추가
BASE_DIR = Path(__file__).resolve().parent
FASTAPI_DIR = BASE_DIR / "FastAPI"
if str(FASTAPI_DIR) not in sys.path:
    sys.path.insert(0, str(FASTAPI_DIR))

from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import StreamingResponse, JSONResponse
from pydantic import BaseModel
import asyncio
import time
import json
import threading
import queue
from typing import Dict, Optional, List
from dotenv import load_dotenv
from prometheus_client import make_asgi_app
import openai

# AutoGen 관련 import
from autogen_forum import (
    희열,
    덕수,
    지율,
    테오,
    민지,
    user,
    ACTIVE_AGENTS,
)

# 뉴스 분석용
from news_analyzer import analyze_news

# 기업 분석용
from company_analyzer import analyze_company

# 데이터베이스 설정 import
from database import OPENAI_API_KEY, GMS_BASE_URL

load_dotenv()
app = FastAPI(title="AI Debate SSE Server")

# ===== Prometheus Metrics 엔드포인트 =====
from prometheus_client import generate_latest, CONTENT_TYPE_LATEST
from starlette.responses import Response


@app.get("/metrics")
async def metrics():
    """Prometheus metrics 엔드포인트"""
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)


# ===== 에이전트 이름 매핑 (한글 ↔ 영문) =====
AGENT_NAME_MAPPING = {
    "희열": "heuyeol",
    "덕수": "deoksu",
    "지율": "jiyul",
    "테오": "teo",
    "민지": "minji",
}

AGENT_NAME_REVERSE = {v: k for k, v in AGENT_NAME_MAPPING.items()}

# 백엔드에서 넘어올 수 있는 다양한 형식 매핑 추가
BACKEND_NAME_MAPPING = {
    # 대문자 시작 형식
    "Minji": "minji",
    "Taeo": "teo",
    "Ducksu": "deoksu",  # 백엔드에서 "Ducksu"로 넘어올 수 있음
    "Heuyeol": "heuyeol",
    "Jiyul": "jiyul",
    # 소문자 형식 (이미 REVERSE에 있지만 명시적으로 추가)
    "minji": "minji",
    "teo": "teo",
    "deoksu": "deoksu",
    "heuyeol": "heuyeol",
    "jiyul": "jiyul",
}


def to_english_name(korean_name: str) -> str:
    """한글 에이전트 이름을 영문으로 변환"""
    return AGENT_NAME_MAPPING.get(korean_name, korean_name)


def to_korean_name(english_name: str) -> str:
    """영문 에이전트 이름을 한글로 변환 (백엔드 형식 지원)"""
    # 1. 백엔드 특정 형식 먼저 확인
    normalized = BACKEND_NAME_MAPPING.get(english_name)
    if normalized:
        return AGENT_NAME_REVERSE.get(normalized, english_name)

    # 2. 소문자로 변환 후 매핑 시도
    lower_name = english_name.lower()
    if lower_name in AGENT_NAME_REVERSE:
        return AGENT_NAME_REVERSE[lower_name]

    # 3. 원본 그대로 반환 (매핑 실패)
    return english_name


def convert_personas_to_korean(personas: Optional[List[str]]) -> Optional[List[str]]:
    """personas 리스트의 영문 이름을 한글로 변환"""
    if personas is None:
        return None
    converted = []
    for p in personas:
        korean = to_korean_name(p)
        if korean != p:  # 변환이 성공한 경우
            print(f"✅ 페르소나 이름 변환: '{p}' → '{korean}'")
        else:
            # 변환이 실패한 경우 (이미 한글이거나 매핑되지 않은 경우)
            if p in AGENT_NAME_MAPPING:
                print(f"ℹ️  페르소나 이름 (이미 한글): '{p}'")
            else:
                print(f"⚠️  페르소나 이름 변환 실패: '{p}' (한글로 유지)")
        converted.append(korean)
    return converted


def convert_personas_to_english(personas: Optional[List[str]]) -> Optional[List[str]]:
    """personas 리스트의 한글 이름을 영문으로 변환"""
    if personas is None:
        return None
    return [to_english_name(p) for p in personas]


# ===== Session 관리 =====
class Session:
    def __init__(
        self,
        session_id: str,
        user_input: str,
        pace_ms: int = 3000,
        personas: List[str] = None,
    ):
        self.session_id = session_id
        self.user_input = user_input
        self.pace_ms = max(200, pace_ms)
        self.running = asyncio.Event()
        self.running.set()
        self.idx = 0
        self.speakers = personas if personas else ACTIVE_AGENTS.copy()
        self.closed = False
        self.updated_at = time.time()
        self.messages = [{"content": user_input, "role": "user", "name": "user"}]
        self.current_speaker_idx = 0
        self.pause_mode = False
        self.ai_agents = {
            "희열": 희열,
            "덕수": 덕수,
            "지율": 지율,
            "테오": 테오,
            "민지": 민지,
        }

    def choose_speaker(self):
        """다음 발언자 선택 (라운드 로빈)"""
        speaker = self.speakers[self.current_speaker_idx]
        self.current_speaker_idx = (self.current_speaker_idx + 1) % len(self.speakers)
        return speaker

    def mark_used(self):
        self.updated_at = time.time()


SESSIONS: Dict[str, Session] = {}
SESSIONS_LOCK = asyncio.Lock()


async def get_or_create_session(
    session_id: str,
    user_input: Optional[str] = None,
    pace_ms: Optional[int] = None,
    personas: Optional[List[str]] = None,
) -> Session:
    async with SESSIONS_LOCK:
        s = SESSIONS.get(session_id)
        # personas를 영문에서 한글로 변환
        korean_personas = convert_personas_to_korean(personas)
        if s is None:
            if user_input is None:
                raise HTTPException(
                    status_code=400, detail="Session does not exist. Call /start first."
                )
            s = Session(session_id, user_input, pace_ms or 3000, korean_personas)
            SESSIONS[session_id] = s
        else:
            if user_input is not None:
                s.user_input = user_input
                s.messages = [{"content": user_input, "role": "user", "name": "user"}]
                s.current_speaker_idx = 0
            if pace_ms is not None:
                s.pace_ms = max(200, pace_ms)
            if korean_personas is not None:
                s.speakers = korean_personas
        s.mark_used()
        return s


async def get_session_or_404(session_id: str) -> Session:
    async with SESSIONS_LOCK:
        s = SESSIONS.get(session_id)
        if s is None:
            raise HTTPException(status_code=404, detail="Session not found")
        s.mark_used()
        return s


async def cleanup_sessions():
    """오래된 세션 정리"""
    async with SESSIONS_LOCK:
        now = time.time()
        expired = [sid for sid, s in SESSIONS.items() if now - s.updated_at > 3600]
        for sid in expired:
            del SESSIONS[sid]


# ===== AutoGen 토론 실행 =====
def run_autogen_discussion(
    session: Session, ai_response_queue: queue.Queue, user_input_queue: queue.Queue
):
    """별도 스레드에서 AutoGen 토론 실행"""
    try:
        from autogen_forum import (
            MAX_ROUNDS,
            INPUT_TIMEOUT,
            AUTO_MAX_ROUNDS,
            MAX_CONTEXT_MESSAGES,
        )
        import random

        # 선택된 에이전트들만 사용
        all_agents = session.ai_agents

        # 에이전트 매칭 및 로깅
        matched_agents = []
        unmatched_names = []
        for name in session.speakers:
            if name in all_agents:
                matched_agents.append(all_agents[name])
            else:
                unmatched_names.append(name)

        if unmatched_names:
            print(
                f"⚠️ 에이전트 매칭 실패: {unmatched_names} (사용 가능한 에이전트: {list(all_agents.keys())})"
            )
            print(f"   세션의 speakers: {session.speakers}")

        ai_agents = matched_agents

        if not ai_agents:
            print(f"❌ 매칭된 에이전트가 없습니다. 토론을 시작할 수 없습니다.")
            print(f"   요청된 페르소나: {session.speakers}")
            print(f"   사용 가능한 에이전트: {list(all_agents.keys())}")
            return

        last_speaker = None
        messages = session.messages.copy()
        spoken_agents = set()  # 발언한 에이전트 추적
        auto_turns = 0  # 사용자 입력 없이 진행된 턴 수

        # 에이전트별 이모지
        emojis = {"희열": "🔥", "덕수": "🧘", "지율": "📊", "테오": "🚀", "민지": "📱"}

        for turn in range(MAX_ROUNDS * 5):
            if session.closed or not session.running.is_set():
                break

            print(f"\n{'='*60}")
            print(f"🎯 턴 {turn + 1} 시작")
            print(f"{'='*60}")

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

            print(f"🎲 발언자 선택: {speaker.name}")

            # AI 발언
            try:
                print(f"\n{'─'*60}")
                print(f"🤖 {speaker.name} 발언 중...")
                print(f"{'─'*60}")

                if user not in speaker.chat_messages:
                    speaker.chat_messages[user] = []

                # 컨텍스트 제한
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

                if isinstance(result, tuple):
                    final, reply = result
                else:
                    reply = result

                if reply:
                    ai_response = str(reply)
                    emoji = emojis.get(speaker.name, "💬")
                    print(f"\n{emoji} {speaker.name}:")
                    print(f"{'─'*40}")
                    print(f"{ai_response}")
                    print(f"{'─'*40}\n")

                    # 검색 결과 출력
                    if hasattr(speaker, "_last_search_results"):
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
                                for idx, result in enumerate(
                                    search_data["bm25"][:2], 1
                                ):
                                    preview = (
                                        result[:150] + "..."
                                        if len(result) > 150
                                        else result
                                    )
                                    print(f"    {idx}. {preview}")

                            # Vector 의미 검색 결과
                            if search_data.get("vector"):
                                print("\n  🧠 Vector 의미 검색:")
                                for idx, result in enumerate(
                                    search_data["vector"][:2], 1
                                ):
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
                        {
                            "content": ai_response,
                            "role": "assistant",
                            "name": speaker.name,
                        }
                    )

                    # 세션 메시지 업데이트 (최근 3개만 유지)
                    session.messages = (
                        messages[-MAX_CONTEXT_MESSAGES:]
                        if len(messages) > MAX_CONTEXT_MESSAGES
                        else messages
                    )

                    # AI 응답을 큐에 전송 (speaker 이름을 영문으로 변환)
                    ai_response_queue.put(
                        {
                            "speaker": to_english_name(speaker.name),
                            "content": ai_response,
                            "turn": turn + 1,
                        }
                    )
            except Exception as e:
                print(f"❌ AI 발언 에러: {e}")
                break

            # 사용자 입력 대기
            print(f"\n{'='*60}")
            if session.pause_mode:
                print("⏸️  일시중단 모드 - 사용자 입력 대기 중...")
            else:
                print(f"⌨️  사용자 입력 ({INPUT_TIMEOUT}초 타임아웃)")
            print(f"{'='*60}")

            try:
                if session.pause_mode:
                    user_input = user_input_queue.get(block=True)
                else:
                    user_input = user_input_queue.get(timeout=INPUT_TIMEOUT)

                if user_input and user_input.strip():
                    # 사용자 입력이 있으면 자동 턴 카운터 리셋
                    messages.append(
                        {"content": user_input, "role": "user", "name": "user"}
                    )
                    session.messages = (
                        messages[-MAX_CONTEXT_MESSAGES:]
                        if len(messages) > MAX_CONTEXT_MESSAGES
                        else messages
                    )

                    print(f"\n👤 사용자:")
                    print(f"{'─'*40}")
                    print(f"{user_input}")
                    print(f"{'─'*40}\n")
                    auto_turns = 0  # 카운터 리셋
                    session.pause_mode = False  # 사용자 입력이 있으면 pause 모드 해제
                else:
                    # 사용자 입력이 없으면 자동 턴 증가
                    auto_turns += 1
                    if auto_turns >= AUTO_MAX_ROUNDS:
                        print("\n" + "🏁" * 30)
                        print(
                            f"💥 {AUTO_MAX_ROUNDS}라운드 완료! 사용자 입력 대기 중..."
                        )
                        print("🏁" * 30)
                        # pause 모드로 전환하여 사용자 입력 대기
                        session.pause_mode = True
                        # 사용자 입력을 무한정 대기 (block=True)
                        try:
                            user_input = user_input_queue.get(block=True)
                            if user_input and user_input.strip():
                                # 사용자 입력이 있으면 토론 재개
                                messages.append(
                                    {
                                        "content": user_input,
                                        "role": "user",
                                        "name": "user",
                                    }
                                )
                                session.messages = (
                                    messages[-MAX_CONTEXT_MESSAGES:]
                                    if len(messages) > MAX_CONTEXT_MESSAGES
                                    else messages
                                )
                                print(f"\n👤 사용자:")
                                print(f"{'─'*40}")
                                print(f"{user_input}")
                                print(f"{'─'*40}\n")
                                auto_turns = 0  # 카운터 리셋
                                session.pause_mode = False  # pause 모드 해제
                        except Exception as e:
                            print(f"❌ 사용자 입력 대기 중 에러: {e}")
                            break
            except queue.Empty:
                print(f"\n⏰ {INPUT_TIMEOUT}초 타임아웃 - 자동 진행")
                # 사용자 입력이 없으면 자동 턴 증가
                auto_turns += 1
                if auto_turns >= AUTO_MAX_ROUNDS:
                    print("\n" + "🏁" * 30)
                    print(f"💥 {AUTO_MAX_ROUNDS}라운드 완료! 사용자 입력 대기 중...")
                    print("🏁" * 30)
                    # pause 모드로 전환하여 사용자 입력 대기
                    session.pause_mode = True
                    # 사용자 입력을 무한정 대기 (block=True)
                    try:
                        user_input = user_input_queue.get(block=True)
                        if user_input and user_input.strip():
                            # 사용자 입력이 있으면 토론 재개
                            messages.append(
                                {"content": user_input, "role": "user", "name": "user"}
                            )
                            session.messages = (
                                messages[-MAX_CONTEXT_MESSAGES:]
                                if len(messages) > MAX_CONTEXT_MESSAGES
                                else messages
                            )
                            print(f"\n👤 사용자:")
                            print(f"{'─'*40}")
                            print(f"{user_input}")
                            print(f"{'─'*40}\n")
                            auto_turns = 0  # 카운터 리셋
                            session.pause_mode = False  # pause 모드 해제
                    except Exception as e:
                        print(f"❌ 사용자 입력 대기 중 에러: {e}")
                        break
            except Exception as e:
                print(f"❌ 사용자 입력 대기 에러: {e}")
                break

    except Exception as e:
        print(f"AutoGen 토론 실행 에러: {e}")


# ===== API 엔드포인트 =====
class StartReq(BaseModel):
    session_id: str
    user_input: str
    pace_ms: Optional[int] = 3000
    personas: Optional[List[str]] = None


class ControlReq(BaseModel):
    session_id: str
    action: str  # STOP | RESUME | CHANGE_PACE
    pace_ms: Optional[int] = None


@app.post("/start")
async def start(req: StartReq):
    s = await get_or_create_session(
        req.session_id, req.user_input, req.pace_ms, req.personas
    )
    s.running.set()

    ai_response_queue = queue.Queue()
    user_input_queue = queue.Queue()
    thread = threading.Thread(
        target=run_autogen_discussion,
        args=(s, ai_response_queue, user_input_queue),
        daemon=True,
    )
    thread.start()
    s.ai_response_queue = ai_response_queue
    s.user_input_queue = user_input_queue

    return JSONResponse(
        {
            "ok": True,
            "session_id": s.session_id,
            "pace_ms": s.pace_ms,
            "active_agents": convert_personas_to_english(s.speakers),
        }
    )


@app.post("/control")
async def control(req: ControlReq):
    s = await get_session_or_404(req.session_id)
    action = req.action.upper()

    if action == "STOP":
        s.pause_mode = True
    elif action == "RESUME":
        s.pause_mode = False
        if hasattr(s, "user_input_queue"):
            s.user_input_queue.put("")
    elif action == "CHANGE_PACE":
        if req.pace_ms is None:
            raise HTTPException(
                status_code=400, detail="pace_ms required for CHANGE_PACE"
            )
        s.pace_ms = max(200, req.pace_ms)
    else:
        raise HTTPException(
            status_code=400, detail="action must be STOP|RESUME|CHANGE_PACE"
        )

    return {"ok": True, "action": action}


@app.post("/input")
async def input_message(request: Request):
    req = await request.json()
    session_id = req.get("session_id")
    user_input = req.get("user_input")

    if not session_id or not user_input:
        raise HTTPException(
            status_code=400, detail="session_id and user_input required"
        )

    s = await get_session_or_404(session_id)

    if hasattr(s, "user_input_queue"):
        s.user_input_queue.put(user_input)
        s.messages.append({"content": user_input, "role": "user", "name": "user"})
        s.current_speaker_idx = 0

    return {"ok": True, "message": "User input received"}


# ===== SSE 스트림 =====
async def sse_generator(request: Request, session_id: str):
    """SSE 스트림 생성기"""
    # 응답 시작 전에 세션 확인 (재시도 포함)
    # 백엔드가 /start를 호출하기 전에 /stream이 올 수 있으므로 재시도 필요
    # 백엔드에서 /start 요청이 느리게 올 수 있으므로 대기 시간을 늘림 (약 15초)
    max_retries = 75
    retry_delay = 0.2  # 200ms
    s = None

    for i in range(max_retries):
        async with SESSIONS_LOCK:
            s = SESSIONS.get(session_id)
            if s is not None:
                s.mark_used()
                break

        # 세션을 찾지 못했고 아직 재시도 가능하면 대기
        if s is None and i < max_retries - 1:
            await asyncio.sleep(retry_delay)

    # 세션을 찾지 못한 경우 하트비트를 보내며 계속 대기
    # 백엔드가 /start를 호출하기 전에 /stream이 올 수 있으므로 무한 대기
    yield "retry: 2000\n\n"

    HEARTBEAT_SECS = 20
    hb_last = time.time()
    session_wait_heartbeat_secs = 2
    session_wait_last = time.time()
    ready_sent = False

    # 세션을 찾을 때까지 하트비트를 보내며 대기
    while s is None:
        if await request.is_disconnected():
            return

        # 세션 재확인
        async with SESSIONS_LOCK:
            s = SESSIONS.get(session_id)
            if s is not None:
                s.mark_used()
                print(f"[SSE] 세션 발견: {session_id}")
                break

        # 세션 대기 중 하트비트 전송
        now = time.time()
        if now - session_wait_last >= session_wait_heartbeat_secs:
            yield ":\n\n"
            session_wait_last = now

        await asyncio.sleep(0.5)

    # 세션을 찾았으므로 ready 이벤트 전송
    if not hasattr(s, "ai_response_queue"):
        s.ai_response_queue = queue.Queue()

    if not ready_sent:
        yield f'id: 0\nevent: ready\ndata: {{"session_id": "{session_id}", "status": "ready"}}\n\n'
        ready_sent = True
        print(f"[SSE] Ready 이벤트 전송: {session_id}")

    while True:
        if await request.is_disconnected():
            break
        if s.closed:
            break

        # 하트비트
        now = time.time()
        if now - hb_last >= HEARTBEAT_SECS:
            yield ":\n\n"
            hb_last = now

        # 실행 상태 대기
        await s.running.wait()

        # AI 응답 확인
        try:
            result = s.ai_response_queue.get(timeout=1.0)

            if result and isinstance(result, dict):
                payload = {
                    "session_id": s.session_id,
                    "speaker": result.get("speaker", "unknown"),
                    "content": result.get("content", ""),
                    "turn": result.get("turn", 0),
                    "ts_ms": int(time.time() * 1000),
                }

                frame = (
                    f"id: {s.idx}\n"
                    f"event: message\n"
                    f"data: {json.dumps(payload, ensure_ascii=False)}\n\n"
                )
                yield frame
                s.idx += 1
                s.mark_used()

        except queue.Empty:
            await asyncio.sleep(0.1)
            continue
        except Exception as e:
            print(f"SSE 생성기 에러: {e}")
            break

        # 페이싱 제거 (딜레이 없음)

    # 종료 신호
    yield f"id: {s.idx}\nevent: close\ndata: {{}}\n\n"


@app.get("/stream")
async def stream(request: Request, session_id: str):
    """SSE 스트림 엔드포인트"""
    return StreamingResponse(
        sse_generator(request, session_id),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",  # nginx 버퍼링 방지
        },
    )


@app.get("/")
def read_root():
    """루트 엔드포인트"""
    return {"message": "AI 투자 토론 시스템 API"}


@app.get("/health")
def health_check():
    """헬스 체크"""
    return {"status": "ok", "service": "ai-service"}


@app.get("/sessions")
async def list_sessions():
    """활성 세션 목록"""
    await cleanup_sessions()
    return {
        "sessions": [
            {
                "session_id": s.session_id,
                "updated_at": s.updated_at,
                "speakers": convert_personas_to_english(s.speakers),
                "pause_mode": s.pause_mode,
            }
            for s in SESSIONS.values()
        ]
    }


# ===== 뉴스 분석 엔드포인트 =====


class NewsAnalysisRequest(BaseModel):
    """뉴스 분석 요청 모델"""

    title: str
    content: str


class NewsAnalysisResponse(BaseModel):
    """뉴스 분석 응답 모델"""

    summary: str
    persona_analyses: Dict[str, str]
    companies: List[str]


class CompanyAnalysisRequest(BaseModel):
    """기업 분석 요청 모델"""

    company_name: str
    company_info: Optional[str] = ""


class CompanyAnalysisResponse(BaseModel):
    """기업 분석 응답 모델"""

    company_name: str
    heuyeol: str
    deoksu: str
    jiyul: str
    teo: str
    minji: str
    analyzed_at: str


@app.post("/analyze-news", response_model=NewsAnalysisResponse)
async def analyze_news_endpoint(request: NewsAnalysisRequest):
    """
    뉴스 기사를 5명의 페르소나 관점에서 분석
    - 뉴스 요약
    - 페르소나 5명 분석 (heuyeol, deoksu, jiyul, teo, minji)
    - 영향 미칠 기업 목록
    """
    try:
        result = analyze_news(request.title, request.content)
        # persona_analyses의 키를 한글에서 영문으로 변환
        english_persona_analyses = {
            to_english_name(k): v for k, v in result["persona_analyses"].items()
        }
        return NewsAnalysisResponse(
            summary=result["summary"],
            persona_analyses=english_persona_analyses,
            companies=result["companies"],
        )
    except ValueError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"분석 오류: {str(e)}")


@app.post("/analyze-company", response_model=CompanyAnalysisResponse)
async def analyze_company_endpoint(request: CompanyAnalysisRequest):
    """
    기업을 5명의 페르소나 관점에서 분석
    - 페르소나별로 한마디씩 투자 의견 생성 (heuyeol, deoksu, jiyul, teo, minji)
    """
    try:
        result = analyze_company(request.company_name, request.company_info or "")
        return CompanyAnalysisResponse(
            company_name=result["company_name"],
            heuyeol=result.get("heuyeol", "heuyeol 분석 생성 실패"),
            deoksu=result.get("deoksu", "deoksu 분석 생성 실패"),
            jiyul=result.get("jiyul", "jiyul 분석 생성 실패"),
            teo=result.get("teo", "teo 분석 생성 실패"),
            minji=result.get("minji", "minji 분석 생성 실패"),
            analyzed_at=result["analyzed_at"],
        )
    except ValueError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"기업 분석 오류: {str(e)}")


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
