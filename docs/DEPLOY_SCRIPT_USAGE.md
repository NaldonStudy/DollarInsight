# Deploy Script 사용 가이드 (Docker Hub 방식)

## 📋 개요

`deploy.sh`는 이제 **Docker Hub에서 이미지를 받아서 배포**하는 방식으로 작동합니다.
- ✅ 로컬 빌드 불필요
- ✅ sudo 권한 불필요 (docker 그룹만 있으면 됨)
- ✅ Jenkins와 동일한 배포 방식
- ✅ 수동 배포 시에도 안정적

---

## 🎯 주요 변경사항

### Before (로컬 빌드 방식)
```bash
sudo ./deploy.sh deploy
# → 로컬에서 Docker 이미지 빌드
# → sudo 권한 필요
# → 빌드 시간 소요
```

### After (Docker Hub 방식)
```bash
./deploy.sh deploy
# → Docker Hub에서 이미지 다운로드
# → sudo 불필요 (docker 그룹만)
# → 빠른 배포
# → Jenkins와 동일한 이미지 사용
```

---

## ⚙️ 사전 설정

### 1. Docker 그룹 권한 설정 (한 번만)

```bash
# 현재 사용자를 docker 그룹에 추가
sudo usermod -aG docker $USER

# 그룹 변경 적용 (재로그인 대신)
newgrp docker

# 확인
docker ps
# 에러 없이 실행되면 성공
```

### 2. 디렉토리 구조 생성

```bash
sudo mkdir -p /opt/S13P31B205/{backend,ai-service}
sudo chown -R $USER:$USER /opt/S13P31B205
```

### 3. 환경 변수 파일 생성

```bash
# Backend 환경 변수
nano /opt/S13P31B205/backend/.env
```


```bash
# AI Service 환경 변수
nano /opt/S13P31B205/ai-service/.env
```


### 4. docker-compose.yml 배치

```bash
# Jenkins가 자동으로 전송하거나, 수동으로 복사
cp docker-compose.yml /opt/S13P31B205/
```

---

## 🚀 사용 방법

### 기본 배포

```bash
cd /opt/S13P31B205
./deploy.sh deploy
```

**실행 과정:**
1. ✅ Docker 권한 확인
2. ✅ 디렉토리 생성
3. ✅ 현재 배포 백업
4. ✅ Docker Hub에서 최신 이미지 Pull
5. ✅ 기존 컨테이너 중지
6. ✅ 새 컨테이너 시작
7. ✅ Health Check (최대 5분)
8. ✅ 상태 확인

### 서비스 상태 확인

```bash
./deploy.sh status
```


### 로그 확인

```bash
# 모든 서비스 로그
./deploy.sh logs

# 특정 서비스 로그
./deploy.sh logs backend
./deploy.sh logs ai-service
./deploy.sh logs nginx
```

### Health Check

```bash
./deploy.sh health
```

**출력 예시:**
```
[2025-01-05 14:25:10] Performing health checks...
[2025-01-05 14:25:15] Backend is healthy ✓
[2025-01-05 14:25:18] AI service is healthy ✓
[2025-01-05 14:25:20] Nginx is healthy ✓
[2025-01-05 14:25:20] All critical services are healthy ✓
```

### 서비스 재시작

```bash
# 모든 서비스 재시작
./deploy.sh restart

# 특정 서비스만 재시작
./deploy.sh restart-service backend
./deploy.sh restart-service ai-service
```

### 서비스 중지/시작

```bash
# 모든 서비스 중지
./deploy.sh stop

# 모든 서비스 시작
./deploy.sh start
```

### 롤백

```bash
./deploy.sh rollback
```

**동작:**
- 최근 백업(docker-compose.yml, .env)으로 복원
- 컨테이너 재시작
- Health Check 수행

### 정리 (Cleanup)

```bash
./deploy.sh cleanup
```

**정리 대상:**
- Dangling 이미지 (태그 없는 이미지)
- 사용하지 않는 네트워크
- (Volume은 안전을 위해 제외)

---

## 📊 명령어 비교표

| 명령어 | 설명 | sudo 필요 | 사용 예시 |
|--------|------|-----------|-----------|
| `deploy` | 전체 배포 | ❌ | `./deploy.sh deploy` |
| `status` | 상태 확인 | ❌ | `./deploy.sh status` |
| `logs` | 로그 확인 | ❌ | `./deploy.sh logs backend` |
| `health` | Health Check | ❌ | `./deploy.sh health` |
| `restart` | 전체 재시작 | ❌ | `./deploy.sh restart` |
| `restart-service` | 특정 재시작 | ❌ | `./deploy.sh restart-service ai-service` |
| `stop` | 전체 중지 | ❌ | `./deploy.sh stop` |
| `start` | 전체 시작 | ❌ | `./deploy.sh start` |
| `rollback` | 롤백 | ❌ | `./deploy.sh rollback` |
| `cleanup` | 정리 | ❌ | `./deploy.sh cleanup` |

---

## 🔧 트러블슈팅

### 1. "Cannot connect to Docker daemon" 에러

**원인:** Docker가 실행 중이지 않거나 권한 문제

**해결:**
```bash
# Docker 실행 확인
sudo systemctl status docker

# Docker 시작
sudo systemctl start docker

# docker 그룹 권한 확인
groups
# docker가 있어야 함

# docker 그룹에 추가 (없다면)
sudo usermod -aG docker $USER
newgrp docker
```

### 2. "Environment files not found" 에러

**원인:** .env 파일이 없음

**해결:**
```bash
# .env 파일 존재 확인
ls -la /opt/S13P31B205/backend/.env
ls -la /opt/S13P31B205/ai-service/.env

# 없다면 생성
nano /opt/S13P31B205/backend/.env
nano /opt/S13P31B205/ai-service/.env
```

### 3. "Failed to pull Docker images" 에러

**원인:** Docker Hub 접속 문제 또는 이미지 없음

**해결:**
```bash
# 인터넷 연결 확인
ping -c 3 hub.docker.com

# 이미지 수동으로 pull 시도
docker pull imtaewon/dollar-backend:latest
docker pull imtaewon/dollar-ai:latest
docker pull imtaewon/dollar-nginx:latest

# Docker Hub 로그인 (private 이미지인 경우)
docker login
```

### 4. Health Check 실패

**원인:** 컨테이너가 정상적으로 시작되지 않음

**해결:**
```bash
# 컨테이너 상태 확인
docker compose ps

# 로그 확인
docker compose logs backend
docker compose logs ai-service

# 특정 컨테이너 재시작
./deploy.sh restart-service backend
```

### 5. 포트 충돌

**원인:** 다른 프로세스가 포트 사용 중

**해결:**
```bash
# 포트 사용 확인
sudo netstat -tlnp | grep -E '(9090|8000|80)'

# 충돌하는 프로세스 종료
sudo kill <PID>

# 또는 docker-compose.yml에서 포트 변경
```

---

## 🎯 Jenkins vs 수동 배포

### Jenkins 자동 배포
```
Git Push → Jenkins Build → Docker Hub Push → EC2 배포
```
- ✅ 자동화
- ✅ 테스트 포함
- ✅ 이미지 태그 관리

### 수동 배포 (deploy.sh)
```
./deploy.sh deploy → Docker Hub Pull → 배포
```
- ✅ 빠른 긴급 배포
- ✅ 특정 서비스만 재시작
- ✅ 로컬 테스트/디버깅

**공통점:**
- 🎯 동일한 Docker Hub 이미지 사용
- 🎯 동일한 배포 프로세스
- 🎯 동일한 Health Check

---

## 📝 백업 및 롤백

### 자동 백업
배포 시 자동으로 백업 생성:
```
/opt/dollar-insight-backups/
  └── backup_20250105_142330/
      ├── docker-compose.yml
      ├── backend.env
      └── ai-service.env
```

### 백업 보관 정책
- 최근 5개 백업 유지
- 오래된 백업 자동 삭제

### 수동 롤백
```bash
# 최근 백업으로 롤백
./deploy.sh rollback

# 특정 백업으로 롤백 (수동)
cd /opt/dollar-insight-backups/backup_20250105_140000
cp docker-compose.yml /opt/S13P31B205/
cp backend.env /opt/S13P31B205/backend/.env
cp ai-service.env /opt/S13P31B205/ai-service/.env
cd /opt/S13P31B205
./deploy.sh deploy
```

---

## 🔍 로그 위치

### Deploy Script 로그
```
/var/log/dollar-insight-deploy.log
```

### Container 로그
```bash
# 실시간 로그
docker compose logs -f

# 최근 100줄
docker compose logs --tail=100

# 특정 서비스
docker compose logs -f backend
```

---

## 📊 모니터링

### 리소스 사용량 확인
```bash
# 실시간 모니터링
docker stats

# 한 번만 조회
./deploy.sh status
```

### 디스크 사용량
```bash
# Docker 디스크 사용량
docker system df

# 상세 정보
docker system df -v
```

---

## 🚀 성능 최적화 팁

### 1. 이미지 캐싱
Docker Hub에서 받은 이미지는 로컬에 캐싱되므로, 재배포 시 빠름

### 2. 정기적인 Cleanup
```bash
# 주 1회 실행 권장
./deploy.sh cleanup
```

### 3. 리소스 모니터링
```bash
# 매일 확인
./deploy.sh status
```

---

## 📞 지원

### 문제 발생 시
1. 로그 확인: `./deploy.sh logs`
2. 상태 확인: `./deploy.sh status`
3. Health Check: `./deploy.sh health`
4. 로그 파일: `/var/log/dollar-insight-deploy.log`

### 긴급 복구
```bash
# 1. 모든 서비스 중지
./deploy.sh stop

# 2. 로그 확인
docker compose logs --tail=200

# 3. 강제 재시작
docker compose down -v
./deploy.sh deploy
```
