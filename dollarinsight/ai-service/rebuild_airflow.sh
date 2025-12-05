#!/bin/bash
# Airflow 재빌드 및 재시작

set -e

echo "=========================================="
echo "🔧 Airflow 재빌드 및 재시작"
echo "=========================================="

# 1. 기존 컨테이너 정리
echo ""
echo "1️⃣ 기존 Airflow 컨테이너 정리 중..."
cd /opt/S13P31B205/ai-service/AI_airflow
docker compose -f docker-compose-airflow.yml down 2>/dev/null || true

# 2. 이미지 삭제
echo ""
echo "2️⃣ 기존 Airflow 이미지 삭제 중..."
docker rmi -f ai_airflow-airflow-webserver:latest 2>/dev/null || true
docker rmi -f ai_airflow-airflow-scheduler:latest 2>/dev/null || true
docker rmi -f ai_airflow-airflow-init:latest 2>/dev/null || true

# 3. Airflow 이미지 빌드
echo ""
echo "3️⃣ Airflow 이미지 빌드 중..."
docker compose -f docker-compose-airflow.yml build --no-cache

# 4. Airflow 컨테이너 실행
echo ""
echo "4️⃣ Airflow 컨테이너 실행 중..."
docker compose -f docker-compose-airflow.yml up -d

# 5. 초기화 대기
echo ""
echo "5️⃣ Airflow 초기화 대기 중..."
sleep 10

# 6. 상태 확인
echo ""
echo "=========================================="
echo "📊 Airflow 실행 상태 확인"
echo "=========================================="
docker compose -f docker-compose-airflow.yml ps

echo ""
echo "=========================================="
echo "✅ Airflow 재빌드 및 재시작 완료!"
echo "=========================================="
echo ""
echo "📌 접속 정보:"
echo "   - Airflow: http://localhost:8090"
echo "   - 사용자명: airflow"
echo "   - 비밀번호: airflow"
echo ""
echo "📌 로그 확인:"
echo "   docker compose -f docker-compose-airflow.yml logs -f"
echo ""
