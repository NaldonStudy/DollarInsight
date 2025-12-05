@echo off
REM Backend Docker Build Script for Windows
REM 사용법: scripts\build.bat [version]

SET VERSION=%1
IF "%VERSION%"=="" SET VERSION=latest
SET IMAGE_NAME=dollar-insight-backend

echo ================================================
echo Building Docker Image: %IMAGE_NAME%:%VERSION%
echo ================================================

REM .env 파일 존재 확인
IF NOT EXIST .env (
    echo WARNING: .env 파일이 없습니다. .env.template을 복사합니다.
    copy .env.template .env
    echo SUCCESS: .env 파일이 생성되었습니다. 필요시 수정해주세요.
)

echo.
echo Building Docker image...
docker build -t %IMAGE_NAME%:%VERSION% .

IF %ERRORLEVEL% NEQ 0 (
    echo ERROR: Docker 빌드 실패
    exit /b 1
)

REM latest 태그도 함께 생성
IF NOT "%VERSION%"=="latest" (
    docker tag %IMAGE_NAME%:%VERSION% %IMAGE_NAME%:latest
)

echo.
echo SUCCESS: 빌드 완료!
echo.
echo 생성된 이미지:
docker images | findstr %IMAGE_NAME%

echo.
echo ================================================
echo 실행 방법:
echo   단독 실행: docker run -d --env-file .env -p 8080:8080 %IMAGE_NAME%:%VERSION%
echo   전체 스택: docker-compose up -d
echo ================================================

pause
