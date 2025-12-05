#!/bin/bash
# FastAPI 재빌드 및 재시작

set -e

echo "=========================================="
echo "🔧 FastAPI 재빌드 및 재시작"
echo "=========================================="

# 1. 기존 컨테이너 정리
echo ""
echo "1️⃣ 기존 컨테이너 정리 중..."
docker stop dollar-insight-ai-service 2>/dev/null || true
docker rm dollar-insight-ai-service 2>/dev/null || true

# 2. 이미지 삭제
echo ""
echo "2️⃣ 기존 이미지 삭제 중..."
docker rmi -f imtaewon/dollar-ai:latest 2>/dev/null || true

# 3. FastAPI 이미지 빌드
echo ""
echo "3️⃣ FastAPI 이미지 빌드 중..."
cd /opt/S13P31B205/ai-service
docker build -t imtaewon/dollar-ai:latest .

# 4. FastAPI 컨테이너 실행
echo ""
echo "4️⃣ FastAPI 컨테이너 실행 중..."
docker run -d \
  --name dollar-insight-ai-service \
  -p 8000:8000 \
  --env-file .env \
  --network s13p31b205_dollar-insight-network \
  imtaewon/dollar-ai:latest

# 5. 헬스체크 대기
echo ""
echo "5️⃣ 헬스체크 대기 중..."
sleep 5
for i in {1..30}; do
  if curl -f http://localhost:8000/health > /dev/null 2>&1; then
    echo "✅ FastAPI 컨테이너 실행 완료 (healthy)"
    break
  fi
  if [ $i -eq 30 ]; then
    echo "⚠️ FastAPI 헬스체크 실패 (로그 확인 필요)"
    docker logs dollar-insight-ai-service --tail 20
    exit 1
  fi
  sleep 2
done

echo ""
echo "=========================================="
echo "✅ FastAPI 재빌드 및 재시작 완료!"
echo "=========================================="
echo ""
echo "📌 접속 정보:"
echo "   - FastAPI: http://localhost:8000"
echo "   - FastAPI Health: http://localhost:8000/health"
echo ""
echo "📌 로그 확인:"
echo "   docker logs -f dollar-insight-ai-service"
echo ""
