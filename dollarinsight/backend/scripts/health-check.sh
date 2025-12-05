#!/bin/bash

# 헬스체크 테스트 스크립트

HOST=${1:-localhost}
PORT=${2:-8080}
BASE_URL="http://${HOST}:${PORT}"

echo "================================================"
echo "Backend Health Check Test"
echo "Target: ${BASE_URL}"
echo "================================================"
echo ""

# 전체 헬스체크
echo "1️⃣  전체 헬스체크:"
echo "   GET ${BASE_URL}/actuator/health"
curl -s "${BASE_URL}/actuator/health" | jq '.' || echo "❌ 실패"
echo ""

# Liveness probe
echo "2️⃣  Liveness Probe:"
echo "   GET ${BASE_URL}/actuator/health/liveness"
curl -s "${BASE_URL}/actuator/health/liveness" | jq '.' || echo "❌ 실패"
echo ""

# Readiness probe
echo "3️⃣  Readiness Probe:"
echo "   GET ${BASE_URL}/actuator/health/readiness"
curl -s "${BASE_URL}/actuator/health/readiness" | jq '.' || echo "❌ 실패"
echo ""

# 개별 컴포넌트 헬스체크
echo "4️⃣  PostgreSQL 헬스:"
echo "   GET ${BASE_URL}/actuator/health/db"
curl -s "${BASE_URL}/actuator/health/db" | jq '.' || echo "❌ 실패"
echo ""

echo "5️⃣  MongoDB 헬스:"
echo "   GET ${BASE_URL}/actuator/health/mongo"
curl -s "${BASE_URL}/actuator/health/mongo" | jq '.' || echo "❌ 실패"
echo ""

echo "6️⃣  Redis 헬스:"
echo "   GET ${BASE_URL}/actuator/health/redis"
curl -s "${BASE_URL}/actuator/health/redis" | jq '.' || echo "❌ 실패"
echo ""

echo "================================================"
echo "✅ 헬스체크 테스트 완료"
echo "================================================"
echo ""
echo "사용법:"
echo "  ./scripts/health-check.sh [host] [port]"
echo "  예: ./scripts/health-check.sh localhost 8080"
