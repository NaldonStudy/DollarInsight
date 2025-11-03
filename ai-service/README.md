# AI Service - Dollar Insight

FastAPI 기반 AI 마이크로서비스

## 기술 스택

- **Framework**: FastAPI 0.104.1
- **Language**: Python 3.10.9
- **Server**: Uvicorn 0.24.0
- **Database**: MongoDB, ChromaDB (Vector DB)
- **Cache**: Redis

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

## Docker 빌드 및 실행

### 1. 환경 변수 설정

```bash
# .env 파일 생성
cp .env.template .env

# 필요에 따라 .env 파일 수정
vim .env
```

### 2. Docker 이미지 빌드

```bash
# 이미지 빌드
./scripts/build.sh

# 또는 특정 버전으로
./scripts/build.sh v1.0.0

# Windows
scripts\build.bat
```

### 3. 단독 실행

```bash
docker run -d \
  --name ai-service \
  --env-file .env \
  -p 8000:8000 \
  dollar-insight-ai-service:latest
```

### 4. Docker Compose로 전체 스택 실행

```bash
# 루트 디렉토리에서
cd ..
docker-compose up -d ai-service

# 또는 전체 스택
docker-compose up -d
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
