# Backend Service - Dollar Insight

Spring Boot 기반 백엔드 서비스

## 기술 스택

- **Framework**: Spring Boot 3.5.7
- **Language**: Java 21
- **Build Tool**: Gradle 8.5
- **Database**: PostgreSQL, MongoDB
- **Cache**: Redis
- **Migration**: Flyway

## 프로젝트 구조

```
backend/
├── src/
│   ├── main/
│   │   ├── java/
│   │   └── resources/
│   │       ├── application.yml          # 메인 설정 (환경변수 기반)
│   │       ├── application-local.yml    # 로컬 개발용
│   │       └── application-prod.yml     # 프로덕션용
│   └── test/
├── Dockerfile                            # Docker 이미지 빌드
├── .env.template                         # 환경변수 템플릿
└── build.gradle                          # Gradle 빌드 설정
```

## 로컬 개발 환경 설정

### 1. 필수 요구사항
- Java 21
- Gradle 8.x
- Docker & Docker Compose (선택사항)

### 2. 의존성 서비스 실행

**Docker Compose 사용:**
```bash
docker-compose -f compose.yaml up -d
```

또는 **개별 실행:**
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
# local 프로파일로 실행 (기본값)
./gradlew bootRun

# 또는
./gradlew clean build
java -jar build/libs/*.jar
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
docker build -t dollar-insight-backend:latest .

# 빌드 확인
docker images | grep dollar-insight-backend
```

### 3. 단독 실행

```bash
docker run -d \
  --name backend \
  --env-file .env \
  -p 8080:8080 \
  dollar-insight-backend:latest
```

### 4. Docker Compose로 전체 스택 실행

```bash
# 전체 서비스 시작
docker-compose up -d

# 로그 확인
docker-compose logs -f backend

# 서비스 중지
docker-compose down

# 볼륨까지 삭제
docker-compose down -v
```

## 헬스체크 엔드포인트

애플리케이션이 실행되면 다음 엔드포인트로 상태 확인:

- **전체 헬스체크**: http://localhost:8080/actuator/health
- **Liveness Probe**: http://localhost:8080/actuator/health/liveness
- **Readiness Probe**: http://localhost:8080/actuator/health/readiness
- **메트릭**: http://localhost:8080/actuator/metrics

### 헬스체크 응답 예시

```json
{
  "status": "UP",
  "components": {
    "db": {
      "status": "UP",
      "details": {
        "database": "PostgreSQL",
        "validationQuery": "isValid()"
      }
    },
    "mongo": {
      "status": "UP",
      "details": {
        "version": "7.0.0"
      }
    },
    "redis": {
      "status": "UP",
      "details": {
        "version": "7.0.0"
      }
    }
  }
}
```

## 환경 변수

주요 환경 변수 목록:

| 변수명 | 설명 | 기본값 |
|--------|------|--------|
| SPRING_PROFILES_ACTIVE | 프로파일 (local/prod) | local |
| SERVER_PORT | 서버 포트 | 8080 |
| SPRING_DATASOURCE_URL | PostgreSQL URL | - |
| SPRING_DATASOURCE_USERNAME | DB 사용자명 | - |
| SPRING_DATASOURCE_PASSWORD | DB 비밀번호 | - |
| SPRING_DATA_MONGODB_HOST | MongoDB 호스트 | - |
| SPRING_REDIS_HOST | Redis 호스트 | - |

전체 목록은 `.env.template` 파일 참조

### OAuth 클라이언트

- **Kakao**: `KAKAO_REST_API_KEY`, `KAKAO_CLIENT_SECRET`, `KAKAO_TIMEOUT_SECONDS`, `KAKAO_ALLOW_DEFAULT_REDIRECT`
- **Google**: `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_TIMEOUT_SECONDS`, `GOOGLE_ALLOW_DEFAULT_REDIRECT`
- 두 공급자 모두 모바일 redirect URI를 사용할 경우 클라이언트에서 전달된 값을 `redirectUri`로 넘겨야 하며, 미전달 시 서버 기본값을 허용하려면 각 `ALLOW_DEFAULT_REDIRECT` 값을 `true`로 설정합니다.

## 프로파일별 설정

### local (로컬 개발)
- PostgreSQL, MongoDB, Redis: localhost
- SQL 로깅 활성화
- 상세한 헬스체크 정보 노출

### prod (프로덕션)
- Docker 네트워크 내부 통신
- SQL 로깅 비활성화
- 헬스체크 정보 최소화
- 최적화된 로깅 설정

## 트러블슈팅

### 포트 충돌
```bash
# 8080 포트 사용 중인 프로세스 확인
lsof -i :8080  # macOS/Linux
netstat -ano | findstr :8080  # Windows

# 다른 포트로 실행
SERVER_PORT=8081 ./gradlew bootRun
```

### 데이터베이스 연결 실패
```bash
# 컨테이너 상태 확인
docker-compose ps

# 로그 확인
docker-compose logs postgres
docker-compose logs mongodb
docker-compose logs redis
```

### 빌드 실패
```bash
# Gradle 캐시 삭제
./gradlew clean --refresh-dependencies

# Docker 빌드 캐시 무시
docker build --no-cache -t dollar-insight-backend:latest .
```

## 개발 가이드

### 의존성 추가
`build.gradle` 파일에 의존성 추가 후:
```bash
./gradlew clean build
```

### 데이터베이스 마이그레이션
Flyway 마이그레이션 파일은 `src/main/resources/db/migration` 에 배치
- 파일명 형식: `V{version}__{description}.sql`
- 예: `V1__init_schema.sql`

### 로그 확인
```bash
# 로컬 개발
tail -f logs/spring.log

# Docker
docker-compose logs -f backend
docker exec -it dollar-insight-backend tail -f /app/logs/spring.log
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
docker build -t dollar-insight-backend:1.0.0 .
docker tag dollar-insight-backend:1.0.0 dollar-insight-backend:latest

# 레지스트리 푸시
docker push your-registry/dollar-insight-backend:1.0.0
docker push your-registry/dollar-insight-backend:latest
```

## 라이선스
SSAFY 13기 자율 프로젝트
