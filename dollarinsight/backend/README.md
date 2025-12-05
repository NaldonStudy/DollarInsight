# Backend Service · Dollar Insight

> 미국 주식 AI 챗봇 **Dollar Insight**를 위한 Spring Boot 백엔드 서비스 입니다.

<p align="center">
  <img src="https://img.shields.io/badge/Spring%20Boot-3.5.7-6DB33F?logo=springboot&logoColor=white" alt="Spring Boot">
  <img src="https://img.shields.io/badge/Java-21-007396?logo=openjdk&logoColor=white" alt="Java 21">
  <img src="https://img.shields.io/badge/Gradle-8.5-02303A?logo=gradle" alt="Gradle">
  <img src="https://img.shields.io/badge/PostgreSQL-16-336791?logo=postgresql&logoColor=white" alt="PostgreSQL">
  <img src="https://img.shields.io/badge/Redis-7-DC382D?logo=redis&logoColor=white" alt="Redis">
</p>

---

## 📋 목차
1. [✨ 주요 기능](#-주요-기능)
2. [🧱 기술 스택](#-기술-스택)
3. [🗂️ 프로젝트 구조](#️-프로젝트-구조)
4. [⚙️ 로컬 개발 환경 설정](#️-로컬-개발-환경-설정)
5. [🚀 Docker 빌드 & 실행](#-docker-빌드--실행)
6. [🩺 헬스체크 & 모니터링](#-헬스체크--모니터링)
7. [🔐 환경 변수](#-환경-변수)
8. [🌱 프로파일별 설정](#-프로파일별-설정)
9. [🧰 트러블슈팅](#-트러블슈팅)
10. [🧑‍💻 개발 가이드](#-개발-가이드)
11. [🚢 배포](#-배포)
12. [📜 라이선스](#-라이선스)

---

## ✨ 주요 기능
- 🧠 **AI 에이전트 대화 지원**: 다중 에이전트 챗 시나리오를 위한 REST & WebSocket API.
- 📊 **PostgreSQL + MongoDB**: 정형/비정형 데이터를 분리하여 저장.
- ⚡ **Redis 캐시 & 메시지 브로커**: 세션 캐싱과 비동기 처리.
- 🔐 **OAuth2 로그인**: Kakao / Google 연동.
- 🛡️ **Observability**: Actuator, Prometheus Metrics, 로그 스트리밍 지원.

## 🧱 기술 스택
| 영역 | 사용 기술 |
|------|-----------|
| Framework | Spring Boot 3.5.7, Spring Security, Spring Web/WebFlux |
| Language | Java 21 (JVM Toolchain) |
| Build | Gradle 8.5, Flyway |
| Data | PostgreSQL, MongoDB, Redis, Redisson |
| 기타 | Micrometer, Prometheus, SpringDoc OpenAPI |

## 🗂️ 프로젝트 구조
```
backend/
├── src/
│   ├── main/
│   │   ├── java/
│   │   └── resources/
│   │       ├── application.yml          # 환경변수 기반 기본 설정
│   │       ├── application-local.yml    # 로컬 프로파일
│   │       └── application-prod.yml     # 프로덕션 프로파일
│   └── test/
├── Dockerfile                           # Spring Boot 컨테이너 이미지
├── .env.template                        # 백엔드 환경 변수 템플릿
└── build.gradle                         # Gradle 빌드 스크립트
```

---

## ⚙️ 로컬 개발 환경 설정
### 1. 필수 요구사항
- Java 21
- Gradle 8.x
- Docker & Docker Compose (선택)

### 2. 의존성 서비스 기동
**루트 디렉터리**에서 제공하는 `docker-compose-local.yml`을 활용하면 빠르게 Postgres/Mongo/Redis를 기동할 수 있습니다.
```bash
# 프로젝트 루트(S13P31B205)에서 실행
docker compose -f docker-compose-local.yml up -d
```

직접 컨테이너를 띄우고 싶다면:
```bash
# PostgreSQL
docker run -d -p 5432:5432 \
  -e POSTGRES_DB=dinsight \
  -e POSTGRES_USER=dinsight \
  -e POSTGRES_PASSWORD=secret \
  postgres:16-alpine

# MongoDB
docker run -d -p 27017:27017 \
  -e MONGO_INITDB_ROOT_USERNAME=root \
  -e MONGO_INITDB_ROOT_PASSWORD=secret \
  mongo:7-jammy

# Redis
docker run -d -p 6379:6379 redis:7-alpine
```

### 3. 애플리케이션 실행
```bash
# 기본(local) 프로파일로 실행
./gradlew bootRun

# 혹은 Jar 생성 후 실행
./gradlew clean build
java -jar build/libs/*.jar
```

---

## 🚀 Docker 빌드 & 실행
### 1. .env 준비
```bash
cp .env.template .env
# 필요한 값을 채운 뒤 저장
```

### 2. 이미지 빌드 & 실행
```bash
# 이미지 빌드
docker build -t dollar-insight-backend:latest .

# 단독 실행
docker run -d \
  --name backend \
  --env-file .env \
  -p 9090:9090 \
  dollar-insight-backend:latest
```

### 3. 전체 스택(docker-compose)
```bash
# 프로젝트 루트에서 전체 스택 기동
docker compose up -d

docker compose logs -f backend
```

---

## 🩺 헬스체크 & 모니터링
- 전체 헬스: `http://localhost:9090/actuator/health`
- Liveness: `http://localhost:9090/actuator/health/liveness`
- Readiness: `http://localhost:9090/actuator/health/readiness`
- Metrics: `http://localhost:9090/actuator/metrics`

```json
{
  "status": "UP",
  "components": {
    "db": { "status": "UP", "details": { "database": "PostgreSQL" } },
    "mongo": { "status": "UP", "details": { "version": "7.0.0" } },
    "redis": { "status": "UP", "details": { "version": "7.0.0" } }
  }
}
```

---

## 🔐 환경 변수
| 변수명 | 설명 | 기본값 |
|--------|------|--------|
| `SPRING_PROFILES_ACTIVE` | 활성화할 프로파일(local/prod) | `local` |
| `SERVER_PORT` | 서버 포트 | `9090` |
| `SPRING_DATASOURCE_URL` | PostgreSQL JDBC URL | - |
| `SPRING_DATASOURCE_USERNAME` | DB 계정 | - |
| `SPRING_DATASOURCE_PASSWORD` | DB 비밀번호 | - |
| `SPRING_DATA_MONGODB_HOST` | MongoDB 호스트 | - |
| `SPRING_REDIS_HOST` | Redis 호스트 | - |

> 전체 목록은 `.env.template` 파일을 참고하세요.

### OAuth 클라이언트
- **Kakao**: `KAKAO_REST_API_KEY`, `KAKAO_CLIENT_SECRET`, `KAKAO_TIMEOUT_SECONDS`, `KAKAO_ALLOW_DEFAULT_REDIRECT`
- **Google**: `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_TIMEOUT_SECONDS`, `GOOGLE_ALLOW_DEFAULT_REDIRECT`
- 모바일 redirect URI를 클라이언트에서 전달하지 않을 경우 각 `ALLOW_DEFAULT_REDIRECT` 값을 `true`로 설정합니다.

---

## 🌱 프로파일별 설정
| 프로파일 | 특징 |
|----------|------|
| `local` | localhost 기반 DB, SQL 로그 출력, 상세 헬스체크 |
| `prod`  | Docker 네트워크 호스트명 사용, SQL 로그 off, 최소 헬스 정보, 최적화된 로깅 |

---

## 🧰 트러블슈팅
### 포트 충돌
```bash
# 9090 포트 점유 확인
lsof -i :9090        # macOS/Linux
netstat -ano | findstr :9090  # Windows

# 다른 포트로 실행
SERVER_PORT=9091 ./gradlew bootRun
```

### 데이터베이스 연결 실패
```bash
docker compose ps
docker compose logs postgres
docker compose logs mongodb
docker compose logs redis
```

### 빌드 실패
```bash
./gradlew clean --refresh-dependencies

docker build --no-cache -t dollar-insight-backend:latest .
```

---

## 🧑‍💻 개발 가이드
### 의존성 추가
```bash
./gradlew clean build
```

### Flyway 마이그레이션
- 경로: `src/main/resources/db/migration`
- 네이밍: `V{version}__{description}.sql` (예: `V1__init_schema.sql`)

### 로그 확인
```bash
# 로컬
tail -f logs/spring.log

# Docker 환경
docker compose logs -f backend
docker exec -it dollar-insight-backend tail -f /app/logs/spring.log
```

---

## 🚢 배포
1. Git push → CI/CD 트리거
2. Gradle 빌드 & Docker 이미지 생성
3. 컨테이너 레지스트리에 push
4. 서버에서 pull 후 재기동

```bash
# 이미지 태깅 및 배포 예시
docker build -t dollar-insight-backend:1.0.0 .
docker tag dollar-insight-backend:1.0.0 dollar-insight-backend:latest

docker push <registry>/dollar-insight-backend:1.0.0
docker push <registry>/dollar-insight-backend:latest
```

---

## 📜 라이선스
SSAFY 13기 자율 프로젝트
