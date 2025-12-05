# Airflow Docker 실행 가이드

## 🚀 빠른 시작

### 로컬 실행 (Windows)
```bash
# AI_airflow 디렉토리로 이동
cd AI_airflow

# 시작 (Docker Compose v2)
docker compose -f docker-compose-airflow.yml up -d

# 중지
docker compose -f docker-compose-airflow.yml down
```

### 로컬 실행 (Linux/Mac)
```bash
# AI_airflow 디렉토리로 이동
cd AI_airflow

# 시작 (Docker Compose v2)
docker compose -f docker-compose-airflow.yml up -d

# 중지
docker compose -f docker-compose-airflow.yml down
```

### AWS EC2 배포
```bash
# AI_airflow 디렉토리로 이동
cd AI_airflow

# 1. 초기 설정 (파일 권한, 디렉토리 생성)
chmod +x setup_ec2.sh
./setup_ec2.sh

# 2. 배포 스크립트 실행
chmod +x deploy_aws.sh
./deploy_aws.sh

# 또는 수동 실행
# 기존 컨테이너 정리
docker compose -f docker-compose-airflow.yml down -v --remove-orphans

# 빌드 및 실행
docker compose -f docker-compose-airflow.yml build --no-cache
docker compose -f docker-compose-airflow.yml up -d
```

**⚠️ EC2 보안 그룹 설정 필수:**
- 인바운드 규칙에 포트 **8090** 추가 (TCP)
- 소스: 특정 IP 또는 0.0.0.0/0 (테스트용, 운영 시 특정 IP만 허용 권장)

## 📁 파일 구조

```
AI_airflow/
├── dags/                             # ✅ DAG 파일들
│   ├── investing_news_crawler_dag.py # Investing.com 뉴스 크롤링 DAG
│   └── reddit_stocks_crawler_dag.py  # Reddit 주식 게시글 크롤링 DAG
├── utils/                             # ✅ Airflow 전용 유틸리티
│   ├── crawl_investing_news.py       # Investing.com 크롤러 클래스
│   └── crawl_reddit_stocks.py        # Reddit 크롤러 클래스
├── docker-compose-airflow.yml        # ✅ 필수: Docker Compose 설정
├── Dockerfile.airflow                 # ✅ 필수: Docker 이미지 빌드
├── deploy_aws.sh                     # 편의: AWS 배포 스크립트
├── setup_ec2.sh                      # 편의: EC2 초기 설정 스크립트
├── reset_airflow.sh                  # 편의: Airflow 완전 초기화 스크립트
└── README.md                         # 이 파일
```

## 🌐 웹 UI 접속

- URL: http://localhost:8090 (로컬) 또는 http://<EC2-IP>:8090 (AWS)
- 사용자명: `airflow`
- 비밀번호: `.env` 파일의 `AIRFLOW_DB_PASSWORD` 또는 기본값 (개발 환경용)

## 📊 상태 확인

```bash
# AI_airflow 디렉토리에서 실행
cd AI_airflow

# Docker Compose v2 사용 (v1인 경우 docker-compose로 변경)
# 실행 중인 컨테이너 확인
docker compose -f docker-compose-airflow.yml ps

# 로그 확인
docker compose -f docker-compose-airflow.yml logs -f

# 특정 서비스 로그만
docker compose -f docker-compose-airflow.yml logs -f airflow-scheduler
```

## 🔧 환경 변수 설정 (선택사항)

`.env` 파일 생성 (프로젝트 루트):
```bash
AIRFLOW_UID=50000
_AIRFLOW_WWW_USER_USERNAME=airflow
_AIRFLOW_WWW_USER_PASSWORD=your_secure_password
```

## 📊 데이터 저장

- 크롤링 데이터:
  - `data/investing_news.json` - Investing.com 뉴스 데이터
  - `data/reddit_stocks.json` - Reddit 주식 게시글 데이터
- Airflow 로그: `logs/` (프로젝트 루트)
- Airflow DB: Docker Volume (`postgres-db-volume`)

## 📋 DAG 스케줄

- **investing_news_crawler**: 10분마다 실행 (`*/10 * * * *`)
- **reddit_stocks_crawler**: 2시간마다 실행 (`0 */2 * * *`)

## 🌐 AWS EC2 배포 주의사항

### 1. **EC2 보안 그룹 설정 (필수)**
   - AWS 콘솔 → EC2 → 보안 그룹
   - 인바운드 규칙 추가:
     - 타입: Custom TCP
     - 포트: 8090
     - 소스: 특정 IP 또는 0.0.0.0/0 (운영 시 특정 IP만 허용 권장)
   - 또는 SSH로 터널링: `ssh -L 8090:localhost:8090 ubuntu@<EC2-IP>`

### 2. **파일 권한 설정**
   - EC2에서 처음 실행 시 `setup_ec2.sh` 실행 권장
   - 현재 사용자 UID를 `AIRFLOW_UID` 환경 변수로 설정

### 3. **자동 재시작**
   - Docker Compose는 `restart: always`로 설정되어 자동 재시작됩니다
   - EC2 재부팅 시 자동 시작하려면 systemd 서비스로 등록 가능

### 4. **데이터 영속성**
   - `data/` 폴더는 볼륨 마운트로 유지됩니다
   - PostgreSQL 데이터는 Docker Volume에 저장됩니다
   - EC2 인스턴스 삭제 시 데이터 손실 주의 (EBS 볼륨 백업 권장)

### 5. **리소스 확인**
   - EC2 인스턴스 타입: 최소 t3.medium 권장 (2 vCPU, 4GB RAM)
   - 디스크 공간: 최소 20GB 여유 공간 권장

## 💡 유용한 명령어

```bash
# AI_airflow 디렉토리에서 실행
cd AI_airflow

# Docker Compose v2 사용 (v1인 경우 docker-compose로 변경)
# 전체 재시작
docker compose -f docker-compose-airflow.yml restart

# 특정 서비스만 재시작
docker compose -f docker-compose-airflow.yml restart airflow-scheduler

# 볼륨 삭제 (주의: 데이터 삭제됨)
docker compose -f docker-compose-airflow.yml down -v

# 완전히 초기화 (컨테이너, 볼륨, 네트워크 모두 삭제)
docker compose -f docker-compose-airflow.yml down -v --remove-orphans
```

## ⚠️ 주요 변경 사항

✅ Docker Compose 파일 완전 재작성
✅ 네트워크를 내부 네트워크로 변경 (external 네트워크 의존성 제거)
✅ Reddit 크롤러의 proxies 변수 오류 수정
✅ 실행 스크립트 경로 수정
✅ 환경 변수 지원 추가 (REDDIT_CLIENT_ID, REDDIT_CLIENT_SECRET 등)

## 🚨 초기 실행 시 주의사항

처음 실행할 때는 기존 컨테이너와 볼륨을 정리하는 것이 좋습니다:

```bash
cd AI_airflow
docker compose -f docker-compose-airflow.yml down -v --remove-orphans
docker compose -f docker-compose-airflow.yml build --no-cache
docker compose -f docker-compose-airflow.yml up -d
```

**참고:** Docker Compose v1을 사용하는 경우 `docker compose` 대신 `docker-compose`를 사용하세요.
