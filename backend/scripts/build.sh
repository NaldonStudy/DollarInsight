#!/bin/bash

# Backend Docker Build Script
# 사용법: ./scripts/build.sh [version]

set -e

VERSION=${1:-latest}
IMAGE_NAME="dollar-insight-backend"

echo "================================================"
echo "Building Docker Image: ${IMAGE_NAME}:${VERSION}"
echo "================================================"

# .env 파일 존재 확인
if [ ! -f .env ]; then
    echo "⚠️  .env 파일이 없습니다. .env.template을 복사합니다."
    cp .env.template .env
    echo "✅ .env 파일이 생성되었습니다. 필요시 수정해주세요."
fi

# Docker 이미지 빌드
echo ""
echo "🔨 Docker 이미지 빌드 중..."
docker build -t ${IMAGE_NAME}:${VERSION} .

# latest 태그도 함께 생성
if [ "$VERSION" != "latest" ]; then
    docker tag ${IMAGE_NAME}:${VERSION} ${IMAGE_NAME}:latest
fi

echo ""
echo "✅ 빌드 완료!"
echo ""
echo "생성된 이미지:"
docker images | grep ${IMAGE_NAME}

echo ""
echo "================================================"
echo "실행 방법:"
echo "  단독 실행: docker run -d --env-file .env -p 8080:8080 ${IMAGE_NAME}:${VERSION}"
echo "  전체 스택: docker-compose up -d"
echo "================================================"
