#!/bin/bash

# 보안 설정 검증 스크립트
# 사용법: ./test-security.sh https://k13b205.p.ssafy.io

DOMAIN="${1:-https://k13b205.p.ssafy.io}"

echo "🔐 보안 설정 검증 시작: $DOMAIN"
echo "=================================================="

# 색상 코드
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 테스트 함수
test_endpoint() {
    local url=$1
    local expected=$2  # "blocked" or "allowed"
    local description=$3

    echo -n "테스트: $description ... "

    status_code=$(curl -s -o /dev/null -w "%{http_code}" "$url")

    if [ "$expected" = "blocked" ]; then
        if [ "$status_code" = "403" ] || [ "$status_code" = "401" ] || [ "$status_code" = "404" ]; then
            echo -e "${GREEN}✅ 차단됨 ($status_code)${NC}"
            return 0
        else
            echo -e "${RED}❌ 노출됨! ($status_code)${NC}"
            return 1
        fi
    else
        if [ "$status_code" = "200" ] || [ "$status_code" = "301" ] || [ "$status_code" = "302" ]; then
            echo -e "${GREEN}✅ 접근 가능 ($status_code)${NC}"
            return 0
        else
            echo -e "${RED}❌ 접근 불가 ($status_code)${NC}"
            return 1
        fi
    fi
}

echo ""
echo "🚫 차단되어야 하는 엔드포인트 (보안 취약점)"
echo "=================================================="
test_endpoint "$DOMAIN/swagger-ui/" "blocked" "Swagger UI"
test_endpoint "$DOMAIN/swagger-ui/index.html" "blocked" "Swagger UI 메인"
test_endpoint "$DOMAIN/v3/api-docs" "blocked" "API Docs"
test_endpoint "$DOMAIN/actuator/health" "blocked" "Actuator Health"
test_endpoint "$DOMAIN/actuator/env" "blocked" "Actuator Env"
test_endpoint "$DOMAIN/pgadmin/" "blocked" "pgAdmin"
test_endpoint "$DOMAIN/mongo-express/" "blocked" "Mongo Express"
test_endpoint "$DOMAIN/redis-commander/" "blocked" "Redis Commander"

echo ""
echo "✅ 공개되어야 하는 엔드포인트"
echo "=================================================="
test_endpoint "$DOMAIN/download" "allowed" "APK 다운로드 페이지"
test_endpoint "$DOMAIN/apk/app-release.apk" "allowed" "APK 파일"
test_endpoint "$DOMAIN/health" "allowed" "Nginx Health"

echo ""
echo "🔒 인증이 필요한 엔드포인트 (401/403 정상)"
echo "=================================================="
test_endpoint "$DOMAIN/api/user/profile" "blocked" "사용자 프로필 API"
test_endpoint "$DOMAIN/api/portfolio" "blocked" "포트폴리오 API"

echo ""
echo "=================================================="
echo "🎉 검증 완료!"
echo "=================================================="
