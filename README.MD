# Dollar In$ight - 프로젝트 인프라

## 자동 배포 테스트

> 미국 주식 AI 챗봇 서비스

## 📋 프로젝트 개요

**Dollar In$ight**는 6개의 AI 에이전트와 대화하며 미국 주식 투자를 학습하는 서비스입니다.

### 주요 기능
- 🤖 6개 AI 에이전트 턴제 대화 시스템
- 📰 뉴스 자동 크롤링 및 분석
- 📊 시장 데이터 분석
- 💬 실시간 WebSocket 채팅
- 🔍 RAG 기반 AI 응답

---

## 🏗️ 기술 스택

### Backend
- **Spring Boot 3.x** (Java 17)
- **PostgreSQL 15** (메인 DB)
- **MongoDB 7** (뉴스 저장)
- **Redis 7** (캐시 & 메시지 큐)
- **ChromaDB** (벡터 DB for RAG)

### AI Service
- **FastAPI** (Python 3.11)
- **LLM APIs**: OpenAI, Gemini, Claude

### Frontend
- **Flutter** (Web & Mobile)
- **WebSocket** (실시간 통신)

### Infrastructure
- **Docker & Docker Compose**
- **Nginx** (리버스 프록시)
- **Jenkins** (CI/CD)
- **AWS EC2** (Ubuntu 22.04)

---

## 🚀 빠른 시작

### 1. 저장소 클론
```bash
git clone <repository-url>
cd S13P31B205
```

### 2. 환경 변수 설정
```bash
cp env.template .env
vim .env  # 필수 값 입력
```

**필수 환경 변수:**
- `POSTGRES_PASSWORD`
- `MONGO_PASSWORD`
- `REDIS_PASSWORD`
- `JWT_SECRET`
- `OPENAI_API_KEY`
- `DOCKER_HUB_REPO`

### 3. Docker Compose 실행
```bash
docker compose up -d
```

### 4. 서비스 확인
```bash
# 상태 확인
docker compose ps

# 로그 확인
docker compose logs -f

# 헬스 체크
curl http://localhost:8080/actuator/health  # Backend
curl http://localhost:8000/health           # AI Service
```

---

## 📂 프로젝트 구조

```
S13P31B205/
├── backend/              # Spring Boot 애플리케이션
│   ├── src/
│   ├── build.gradle
│   └── Dockerfile
├── ai-service/          # FastAPI AI 서비스
│   ├── app/
│   ├── requirements.txt
│   └── Dockerfile
├── nginx/               # Nginx 설정
│   ├── nginx.conf
│   └── conf.d/
├── docker-compose.yml   # Docker Compose 설정
├── env.template         # 환경 변수 템플릿
└── README.MD           # 이 파일
```

---

## 🌐 서비스 포트

| 서비스 | 포트 | 용도 |
|--------|------|------|
| **Nginx** | 80, 443 | 리버스 프록시 |
| **Backend** | 9090 | REST API |
| **AI Service** | 8000, 50051 | HTTP API, gRPC |
| **PostgreSQL** | 5432 | 메인 DB |
| **MongoDB** | 27017 | 뉴스 DB |
| **Redis** | 6379 | 캐시 & 큐 |
| **ChromaDB** | 9000 | 벡터 DB |

---

## 🗄️ 데이터베이스 역할

| DB | 역할 | 데이터 |
|----|------|--------|
| **PostgreSQL** | 메인 DB | 사용자, 채팅, 포트폴리오 |
| **MongoDB** | 문서 DB | 뉴스, 시장 분석 |
| **Redis** | 캐시 & 큐 | 세션, Celery 큐 |
| **ChromaDB** | 벡터 DB | AI별 RAG 데이터 (6개) |

---

## 🤖 AI 에이전트

1. **가치투자자** - 재무제표 분석
2. **기술분석가** - 차트 패턴 분석
3. **뉴스분석가** - 뉴스 기반 분석
4. **밈주식러** - 커뮤니티 트렌드
5. **리스크관리자** - 위험 평가
6. **산업분석가** - 산업 트렌드

---

## 🛠️ 개발 가이드

### Backend (Spring Boot)

```bash
cd backend

# Gradle 빌드
./gradlew clean build

# Docker 이미지 빌드
docker build -t dollar-insight-backend .

# 로컬 실행
./gradlew bootRun
```

### AI Service (FastAPI)

```bash
cd ai-service

# 가상환경 생성
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 의존성 설치
pip install -r requirements.txt

# 로컬 실행
uvicorn app.main:app --reload --port 8000
```

---

## 🧪 테스트

### Backend 테스트
```bash
cd backend
./gradlew test
```

### AI Service 테스트
```bash
cd ai-service
pytest
```

### 통합 테스트
```bash
# 모든 서비스 시작
docker compose up -d

# API 테스트
curl http://localhost/api/health
curl http://localhost/ai/health

# WebSocket 테스트 (wscat 필요)
wscat -c ws://localhost/ws/chat
```

---

## 🚀 배포



### CI/CD (Jenkins)
1. GitLab에 코드 푸시
2. Webhook이 Jenkins 트리거
3. 자동 빌드 & 배포

---

## 📊 모니터링

### 로그 확인
```bash
# 전체 로그
docker compose logs -f

# 특정 서비스 로그
docker compose logs -f backend
docker compose logs -f ai-service
docker compose logs -f mongodb
```

### 리소스 사용량
```bash
# 실시간 모니터링
docker stats

# 디스크 사용량
df -h

# 메모리 사용량
free -h
```

### MongoDB 모니터링
```bash
# MongoDB 접속
docker compose exec mongodb mongosh -u admin -p changeme --authenticationDatabase admin

# 데이터베이스 통계
use dollar_insight
db.stats()

# 컬렉션 통계
db.news.stats()
```

---

## 🐛 트러블슈팅

### 컨테이너가 시작되지 않을 때
```bash
# 로그 확인
docker compose logs SERVICE_NAME

# 컨테이너 재시작
docker compose restart SERVICE_NAME

# 전체 재시작
docker compose down && docker compose up -d
```

### MongoDB 연결 오류
```bash
# MongoDB 상태 확인
docker compose exec mongodb mongosh --eval "db.adminCommand('ping')"

# 환경 변수 확인
docker compose exec backend env | grep MONGO
docker compose exec ai-service env | grep MONGO
```

### 포트 충돌
```bash
# 포트 사용 확인
netstat -tuln | grep LISTEN

# 특정 포트 프로세스 확인
lsof -i :8080
```

---

## 🔐 보안

### 환경 변수 보안
- `.env` 파일을 Git에 커밋하지 마세요
- 강력한 비밀번호 사용
- JWT Secret은 256비트 이상

### Docker 보안
- 프로덕션에서는 Docker Hub private registry 사용
- 정기적으로 이미지 업데이트

---

## 👥 팀

**B205팀**
- 백엔드 개발
- AI 개발
- 프론트엔드 개발
- 인프라
- DevOps

---

## 📝 라이선스

이 프로젝트는 SSAFY 자율 프로젝트입니다.

---

## 🔗 관련 링크

- [GitLab Repository](<https://lab.ssafy.com/s13-final/S13P31B205.git>)
- [SSAFY](https://www.ssafy.com)

---

**최종 업데이트**: 2025-10-27  
**버전**: 1.0.0
