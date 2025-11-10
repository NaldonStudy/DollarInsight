# AI Service - Dollar Insight

FastAPI 기반 AI 마이크로서비스

## 기술 스택

- **Framework**: FastAPI 0.104.1
- **Language**: Python 3.10.9
- **Server**: Uvicorn 0.24.0
- **Database**: MongoDB, ChromaDB (Vector DB)
- **Cache**: Redis

## Docker 빌드 및 실행

### 우분투에서 빠른 실행 (권장)

```bash
# 1. 이미지 빌드
docker build -t ai-service:latest .

# 2. 컨테이너 실행 (백그라운드)
docker run -d \
  --name ai-service \
  -p 8000:8000 \
  ai-service:latest

# 3. 실행 확인
curl http://localhost:8000/health

# 4. 로그 확인
docker logs ai-service

# 5. 컨테이너 중지
docker stop ai-service

# 6. 컨테이너 삭제
docker rm ai-service
```

### 기존 컨테이너가 있는 경우

```bash
# 기존 컨테이너 중지 및 삭제
docker stop ai-service 2>/dev/null || true
docker rm ai-service 2>/dev/null || true

# 이미지 재빌드
docker build -t ai-service:latest .

# 새로 실행
docker run -d \
  --name ai-service \
  -p 8000:8000 \
  ai-service:latest
```

### 환경 변수 설정 (필요시)

```bash
# .env 파일이 있다면 (이미 .dockerignore에서 제외 해제되어 이미지에 포함됨)
# 또는 실행 시 직접 전달:
docker run -d \
  --name ai-service \
  --env-file .env \
  -p 8000:8000 \
  ai-service:latest
```

## API 사용 예시

### 1. 헬스 체크
```bash
curl http://localhost:8000/health
# 응답: {"status":"ok","service":"ai-service"}
```

### 2. 루트 엔드포인트
```bash
curl http://localhost:8000/
# 응답: {"message":"AI 투자 토론 시스템 API"}
```

### 3. 세션 시작 (토론 시작)
```bash
curl -X POST http://localhost:8000/start \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "test-session-001",
    "user_input": "테슬라 주식에 대해 토론해주세요",
    "pace_ms": 3000,
    "personas": ["희열", "덕수", "지율"]
  }'

# 응답 예시:
# {
#   "ok": true,
#   "session_id": "test-session-001",
#   "pace_ms": 3000,
#   "active_agents": ["희열", "덕수", "지율"]
# }
```

**파라미터 설명:**
- `session_id`: 세션 고유 ID
- `user_input`: 토론 주제/질문
- `pace_ms`: 메시지 간 간격 (밀리초, 기본값: 3000)
- `personas`: 참여할 AI 에이전트 목록 (선택사항, 기본값: 모든 에이전트)

**사용 가능한 에이전트:**
- `희열`: 🔥 긍정적이고 열정적인 투자자
- `덕수`: 🧘 신중하고 안정적인 투자자
- `지율`: 📊 데이터 중심의 분석가
- `테오`: 🚀 기술 및 혁신 전문가
- `민지`: 📱 트렌드 및 소셜 분석가

### 4. SSE 스트림으로 실시간 토론 수신
```bash
# 별도 터미널에서 실행
curl -N http://localhost:8000/stream?session_id=test-session-001

# 응답 예시 (SSE 형식):
# id: 0
# event: message
# data: {"session_id":"test-session-001","speaker":"희열","text":"테슬라는...","turn":1,"ts_ms":1234567890}
# 
# id: 1
# event: message
# data: {"session_id":"test-session-001","speaker":"덕수","text":"하지만...","turn":2,"ts_ms":1234567891}
```

### 5. 사용자 입력 전송
```bash
curl -X POST http://localhost:8000/input \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "test-session-001",
    "user_input": "그럼 애플은 어떨까요?"
  }'

# 응답: {"ok": true, "message": "User input received"}
```

### 6. 세션 제어 (일시정지/재개/속도 조절)
```bash
# 일시정지
curl -X POST http://localhost:8000/control \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "test-session-001",
    "action": "STOP"
  }'

# 재개
curl -X POST http://localhost:8000/control \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "test-session-001",
    "action": "RESUME"
  }'

# 속도 변경 (1초마다 메시지)
curl -X POST http://localhost:8000/control \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "test-session-001",
    "action": "CHANGE_PACE",
    "pace_ms": 1000
  }'
```

### 7. 활성 세션 목록 조회
```bash
curl http://localhost:8000/sessions

# 응답 예시:
# {
#   "sessions": [
#     {
#       "session_id": "test-session-001",
#       "updated_at": 1234567890.123,
#       "speakers": ["희열", "덕수", "지율"],
#       "pause_mode": false
#     }
#   ]
# }
```

### 전체 워크플로우 예시

```bash
# 1. 세션 시작
SESSION_ID="demo-$(date +%s)"
curl -X POST http://localhost:8000/start \
  -H "Content-Type: application/json" \
  -d "{
    \"session_id\": \"$SESSION_ID\",
    \"user_input\": \"비트코인 투자에 대해 토론해주세요\",
    \"pace_ms\": 2000,
    \"personas\": [\"희열\", \"덕수\", \"지율\", \"테오\", \"민지\"]
  }"

# 2. SSE 스트림으로 실시간 메시지 수신 (별도 터미널)
curl -N "http://localhost:8000/stream?session_id=$SESSION_ID"

# 3. 사용자 입력 추가 (원하는 시점에)
curl -X POST http://localhost:8000/input \
  -H "Content-Type: application/json" \
  -d "{
    \"session_id\": \"$SESSION_ID\",
    \"user_input\": \"이더리움은 어떨까요?\"
  }"

# 4. 세션 상태 확인
curl "http://localhost:8000/sessions"
```

### 스크립트를 사용하는 경우

```bash
# 이미지 빌드
./scripts/build.sh

# 또는 특정 버전으로
./scripts/build.sh v1.0.0

# Windows
scripts\build.bat
```

### Docker Compose로 전체 스택 실행

```bash
# 루트 디렉토리에서
cd ..
docker-compose up -d ai-service

# 또는 전체 스택
docker-compose up -d
```

## 프로젝트 구조

```
ai-service/
├── main.py                      # FastAPI 애플리케이션
├── requirements.txt             # Python 의존성
├── Dockerfile                   # Docker 이미지 빌드
├── .dockerignore               # Docker 빌드 제외 파일
├── .env.template               # 환경 변수 템플릿
├── scripts/
│   ├── build.sh                # 이미지 빌드 스크립트
│   ├── build.bat               # 이미지 빌드 (Windows)
│   └── health-check.sh         # 헬스체크 테스트
└── README.md
```

## 로컬 개발 환경 설정

### 1. 필수 요구사항
- Python 3.10+
- pip
- virtualenv (권장)
- Docker & Docker Compose (선택사항)

### 2. 가상환경 생성 및 활성화

**Linux/Mac:**
```bash
python -m venv venv
source venv/bin/activate
```

**Windows:**
```bash
python -m venv venv
venv\Scripts\activate
```

### 3. 의존성 설치

```bash
pip install -r requirements.txt
```

### 4. 환경 변수 설정

```bash
# .env 파일 생성
cp .env.template .env

# 필요에 따라 .env 파일 수정
vim .env
```

### 5. 애플리케이션 실행

```bash
# 개발 모드 (핫 리로드)
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# 프로덕션 모드
uvicorn main:app --host 0.0.0.0 --port 8000
```

## API 엔드포인트

### 기본 엔드포인트

- **Root**: http://localhost:8000/
  ```json
  {
    "message": "Hello World"
  }
  ```

- **Health Check**: http://localhost:8000/health
  ```json
  {
    "status": "ok",
    "service": "ai-service"
  }
  ```

- **API 문서** (Swagger UI): http://localhost:8000/docs
- **Alternative 문서** (ReDoc): http://localhost:8000/redoc

## 헬스체크

```bash
# 스크립트로 테스트
./scripts/health-check.sh

# 또는 curl로 직접
curl http://localhost:8000/health
```

## 환경 변수

주요 환경 변수 목록:

| 변수명 | 설명 | 기본값 |
|--------|------|--------|
| SERVICE_ENV | 환경 (development/production) | development |
| LOG_LEVEL | 로그 레벨 | INFO |
| REDIS_HOST | Redis 호스트 | redis |
| REDIS_PORT | Redis 포트 | 6379 |
| MONGODB_HOST | MongoDB 호스트 | mongodb |
| MONGODB_PORT | MongoDB 포트 | 27017 |
| CHROMADB_HOST | ChromaDB 호스트 | chromadb |
| CHROMADB_PORT | ChromaDB 포트 | 8001 |

전체 목록은 `.env.template` 파일 참조

## 개발 가이드

### 의존성 추가

```bash
# 의존성 설치
pip install <package-name>

# requirements.txt 업데이트
pip freeze > requirements.txt
```

### 코드 스타일

```bash
# Black (코드 포매터)
pip install black
black .

# Flake8 (린터)
pip install flake8
flake8 .
```

### 테스트

```bash
# pytest 설치
pip install pytest pytest-asyncio

# 테스트 실행
pytest
```

## 트러블슈팅

### 포트 충돌
```bash
# 8000 포트 사용 중인 프로세스 확인
lsof -i :8000  # macOS/Linux
netstat -ano | findstr :8000  # Windows

# 다른 포트로 실행
uvicorn main:app --port 8001
```

### 의존성 설치 실패
```bash
# pip 업그레이드
pip install --upgrade pip

# 캐시 삭제 후 재설치
pip install --no-cache-dir -r requirements.txt
```

### Docker 빌드 실패
```bash
# 캐시 무시하고 빌드
docker build --no-cache -t dollar-insight-ai-service:latest .

# 이전 이미지 정리
docker system prune -a
```

## 배포

### CI/CD 파이프라인
1. 코드 푸시
2. Docker 이미지 빌드
3. 이미지 레지스트리에 푸시
4. 서버에서 이미지 pull 및 실행

### 이미지 태깅
```bash
# 버전 태그
docker build -t dollar-insight-ai-service:1.0.0 .
docker tag dollar-insight-ai-service:1.0.0 dollar-insight-ai-service:latest

# 레지스트리 푸시
docker push your-registry/dollar-insight-ai-service:1.0.0
docker push your-registry/dollar-insight-ai-service:latest
```

## 라이선스
SSAFY 13기 자율 프로젝트
