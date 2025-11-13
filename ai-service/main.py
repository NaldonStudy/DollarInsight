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


def to_english_name(korean_name: str) -> str:
    """한글 에이전트 이름을 영문으로 변환"""
    return AGENT_NAME_MAPPING.get(korean_name, korean_name)


def to_korean_name(english_name: str) -> str:
    """영문 에이전트 이름을 한글로 변환"""
    return AGENT_NAME_REVERSE.get(english_name, english_name)


def convert_personas_to_korean(personas: Optional[List[str]]) -> Optional[List[str]]:
    """personas 리스트의 영문 이름을 한글로 변환"""
    if personas is None:
        return None
    return [to_korean_name(p) for p in personas]


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
        ai_agents = [
            all_agents[name] for name in session.speakers if name in all_agents
        ]

        if not ai_agents:
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
                            "text": ai_response,
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
                else:
                    # 사용자 입력이 없으면 자동 턴 증가
                    auto_turns += 1
                    if auto_turns >= AUTO_MAX_ROUNDS:
                        print("\n" + "🏁" * 30)
                        print(f"💥 {AUTO_MAX_ROUNDS}라운드 완료! 토론 종료!")
                        print("🏁" * 30)
                        break
            except queue.Empty:
                print(f"\n⏰ {INPUT_TIMEOUT}초 타임아웃 - 자동 진행")
                # 사용자 입력이 없으면 자동 턴 증가
                auto_turns += 1
                if auto_turns >= AUTO_MAX_ROUNDS:
                    print("\n" + "🏁" * 30)
                    print(f"💥 {AUTO_MAX_ROUNDS}라운드 완료! 토론 종료!")
                    print("🏁" * 30)
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

    # AutoGen 토론을 별도 스레드에서 시작
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
    yield "retry: 2000\n\n"

    HEARTBEAT_SECS = 20
    hb_last = time.time()

    s = await get_session_or_404(session_id)

    if not hasattr(s, "ai_response_queue"):
        s.ai_response_queue = queue.Queue()

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
                    "text": result.get("text", ""),
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

        # 페이싱
        await asyncio.sleep(s.pace_ms / 1000.0)

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
            companies=result["companies"]
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
            analyzed_at=result["analyzed_at"]
        )
    except ValueError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"기업 분석 오류: {str(e)}")


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
